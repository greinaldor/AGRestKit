//
//  AGRestEventuallyQueue.m
//  AGRestStack
//
//  Created by Adrien Greiner on 27/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestEventuallyQueue.h"

#import <Bolts/BFTask.h>
#import <Bolts/BFTaskCompletionSource.h>

#import "AGRestReachabilityManager.h"
#import "BFTask+Private.h"
#import "AGRestRequest.h"
#import "AGRestRequest_Private.h"
#import "AGRestResponse.h"
#import "AGRestRequestRunner.h"
#import "AGRestErrorUtilities.h"
#import "AGRestTaskQueue.h"
#import "AGRestEventuallyQueue_Private.h"

NSUInteger       const AGRestEventuallyQueueDefaultMaxAttemps = 5;
NSTimeInterval   const AGRestEventuallyQueueDefaultRetryTimeInterval = 600.0f;

@interface AGRestEventuallyQueue() <AGRestReachabilityListener>

@property (atomic, assign, getter=isRunning) BOOL running;
@property (nonatomic, assign, readwrite, getter=isConnected) BOOL connected;

@end

@implementation AGRestEventuallyQueue

#pragma mark - Init
#pragma mark -

- (instancetype)initWithRequestRunner:(id<AGRestRequestRunning>)runner
                          maxAttempts:(NSUInteger)maxAttemps
                        retryInterval:(NSTimeInterval)retryInterval
{
    self = [super init];
    if (!self) return nil;
    
    _requestRunner = runner;
    _maxAttempsCount = maxAttemps;
    _retryInterval = retryInterval;
    
    _synchronizationQueue = dispatch_queue_create("com.AGRest.eventuallyQueuSynchronizeQueue", DISPATCH_QUEUE_SERIAL);
    _synchronizationExecutor = [BFExecutor executorWithDispatchQueue:_synchronizationQueue];
    
    _processingQueue = dispatch_queue_create("com.AGRest.eventuallyQueueProcessingQueue", DISPATCH_QUEUE_SERIAL);
    _processingQueueSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, _processingQueue);
    
    _requestIdentifiers = [[NSMutableDictionary alloc] init];
    _taskCompletionSources = [[NSMutableDictionary alloc] init];
    
    _requestEnqueueTaskQueue = [[AGRestTaskQueue alloc] init];
    
    [[AGRestReachabilityManager sharedManager] addListener:self];

    //self.connected = ([AGRestReachabilityManager sharedManager].currentState != AGRestReachabilityStatusNotReachable);
    
    return self;
}

- (void)dealloc {
    [[AGRestReachabilityManager sharedManager] removeListener:self];
}

#pragma mark - Feeding Queue
#pragma mark -

- (BFTask *)enqueueRequestInBackground:(id<AGRestCachable>)request {
    if (!request) return [BFTask taskWithException:[NSException exceptionWithName:NSInternalInconsistencyException
                                                                           reason:@" Can't enqueue a nil `request`."
                                                                         userInfo:nil]];
    
    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    
    weakify(self);
    [_requestEnqueueTaskQueue enqueueTask:^BFTask *(BFTask *toAwait) {
        return [toAwait continueAsyncWithBlock:^id(BFTask *task) {
            strongify(weakSelf);
            
            NSString *identifier = [strongSelf _newIdentifierForRequest:request];
            return [[[strongSelf _enqueueRequestInBackground:request
                                                  identifier:identifier] continueWithBlock:^id(BFTask *task) {
                if (task.error || task.exception || task.cancelled) {
                    if (task.error) {
                        taskCompletionSource.error = task.error;
                    } else if (task.exception) {
                        taskCompletionSource.exception = task.exception;
                    } else if (task.cancelled) {
                        [taskCompletionSource cancel];
                    }
                }
                
                return task;
            }] continueWithExecutor:_synchronizationExecutor withSuccessBlock:^id(BFTask *task) {
                [self _didEnqueueRequest:request withIdentifier:identifier taskCompletionSource:taskCompletionSource];
                return nil;
            }];
        }];
    }];
    
    return taskCompletionSource.task;
}

- (BFTask *)_enqueueRequestInBackground:(id<AGRestCachable>)request
                             identifier:(NSString *)identifier {
    // This enforces implementing this method in subclasses
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)_didEnqueueRequest:(id<AGRestCachable>)request
            withIdentifier:(NSString *)identifier
      taskCompletionSource:(BFTaskCompletionSource *)taskCompletionSource
{
    _taskCompletionSources[identifier] = taskCompletionSource;
    dispatch_source_merge_data(_processingQueueSource, 1);
    
    if (_retryingSemaphore) {
        dispatch_semaphore_signal(_retryingSemaphore);
    }
}

#pragma mark - Controlling Queue
#pragma mark -

- (void)start {
    dispatch_source_set_event_handler(_processingQueueSource, ^{
        [self _runRequests];
    });
    [self resume];
}

- (void)resume {
    if (self.running) {
        return;
    }
    self.running = YES;
    dispatch_resume(_processingQueueSource);
    dispatch_source_merge_data(_processingQueueSource, 1);
}

- (void)pause {
    if (!self.running) {
        return;
    }
    self.running = NO;
    dispatch_suspend(_processingQueueSource);
}

- (void)removeAllRequests {
    dispatch_sync(_synchronizationQueue, ^{
        [_taskCompletionSources removeAllObjects];
    });
}


#pragma mark - Pending Requests
#pragma mark -

- (NSArray *)_pendingRequestIdentifiers {
    return nil;
}

- (id<AGRestCachable>)_requestWithIdentifier:(NSString *)identifier error:(NSError **)error {
    return nil;
}

- (NSString *)_newIdentifierForRequest:(id<AGRestCachable>)request {
    return nil;
}

- (NSUInteger)requestsCount {
    return [[self _pendingRequestIdentifiers] count];
}

#pragma mark - Running Requests
#pragma mark -

- (void)_runRequests {
    [self _runRequestsWithRetriesCount:self.maxAttempsCount];
}

- (void)_runRequestsWithRetriesCount:(NSUInteger)retriesCount {
    if (!self.running || !self.connected) {
        return;
    }
    
    // Expect sorted result from _pendingRequestIdentifiers
    NSArray *requestIdentifiers = [self _pendingRequestIdentifiers];
    BOOL shouldRetry = NO;
    for (NSString *identifier in requestIdentifiers) {
        NSError *error = nil;
        id<AGRestCachable> request = [self _requestWithIdentifier:identifier error:&error];
        if (!request || error) {
            if (!error) {
                error = [AGRestErrorUtilities errorWithCode:kSSErrorInternalServer
                                                    message:@"Failed to dequeue an eventually request."
                                                  shouldLog:NO];
            }
            BFTask *task = [BFTask taskWithError:error];
            [self _didFinishRunningRequest:request withIdentifier:identifier resultTask:task];
            continue;
        }
        
        __block BFTaskCompletionSource *taskCompletionSource = nil;
        dispatch_sync(_synchronizationQueue, ^{
            taskCompletionSource = _taskCompletionSources[identifier];
        });
        
        BFTask *resultTask = nil;
        AGRestResponse *result = nil;
        @try {
            resultTask = [self _runRequest:request withIdentifier:identifier];
            result = [resultTask waitForResult:&error];
        }
        @catch (NSException *exception) {
            error = [NSError errorWithDomain:AGRestErrorDomain
                                        code:-1
                                    userInfo:@{ @"message" : @"Failed to run an eventually request.",
                                                @"exception" : exception }];
            resultTask = [BFTask taskWithError:error];
        }
        
        if (error) {
            BOOL permanent = (![error.userInfo[@"temporary"] boolValue] &&
                              ([[error domain] isEqualToString:AGRestErrorDomain] ||
                               [error code] != kSSErrorConnectionFailed));
            
            if (!permanent) {
                NSLog(@"Attempt at runEventually request timed out. Waiting %f seconds. %d retries remaining.",
                      self.retryInterval,
                      (int)retriesCount);
                
                __block dispatch_semaphore_t semaphore = NULL;
                dispatch_sync(_synchronizationQueue, ^{
                    _retryingSemaphore = dispatch_semaphore_create(0);
                    semaphore = _retryingSemaphore;
                });
                
                dispatch_time_t timeoutTime = dispatch_time(DISPATCH_TIME_NOW,
                                                            (int64_t)(self.retryInterval * NSEC_PER_SEC));
                
                long waitResult = dispatch_semaphore_wait(semaphore, timeoutTime);
                dispatch_sync(_synchronizationQueue, ^{
                    _retryingSemaphore = NULL;
                });
                
                if (waitResult == 0) {
                    // We haven't waited long enough, but if we lost the connection, or should stop, just quit.
                    return;
                }
                
                // We need to go out of the loop.
                if (retriesCount > 0) {
                    shouldRetry = YES;
                    break;
                }
            }
        }
        
        // Post processing shouldn't make the queue retry the request.
        resultTask = [self _didFinishRunningRequest:request withIdentifier:identifier resultTask:resultTask];
        [resultTask waitForResult:nil];
        
        // Notify anyone waiting that the operation is completed.
        if (resultTask.error) {
            taskCompletionSource.error = resultTask.error;
        } else if (resultTask.exception) {
            taskCompletionSource.exception = resultTask.exception;
        } else if (resultTask.cancelled) {
            [taskCompletionSource cancel];
        } else {
            taskCompletionSource.result = resultTask.result;
        }
    }
    
    // Retry here so that we're in cleaner state.
    if (shouldRetry) {
        return [self _runRequestsWithRetriesCount:(retriesCount - 1)];
    }
}

- (BFTask *)_runRequest:(id<AGRestCachable>)request withIdentifier:(NSString *)identifier {
    if ([request isKindOfClass:[AGRestRequest class]]) {
        return [self.requestRunner runRequestAsync:(AGRestRequest *)request withOptions:0];
    }
    
    NSString *reason = [NSString stringWithFormat:@"Can't find a compatible runner for request %@.", request];
    NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:reason
                                                   userInfo:nil];
    return [BFTask taskWithException:exception];
}

- (BFTask *)_didFinishRunningRequest:(id<AGRestCachable>)request
                      withIdentifier:(NSString *)identifier
                          resultTask:(BFTask *)resultTask {
    dispatch_sync(_synchronizationQueue, ^{
        [_taskCompletionSources removeObjectForKey:identifier];
    });
    
    return resultTask;
}

#pragma mark - Accessors
#pragma mark -

- (void)setConnected:(BOOL)connected {
    BFTaskCompletionSource *barrier = [BFTaskCompletionSource taskCompletionSource];
    dispatch_async(_processingQueue, ^{
        dispatch_sync(_synchronizationQueue, ^{
            if (self.connected != connected) {
                _connected = connected;
                if (connected) {
                    dispatch_source_merge_data(_processingQueueSource, 1);
                }
            }
        });
        barrier.result = nil;
    });
    if (connected) {
        dispatch_async(_synchronizationQueue, ^{
            if (_retryingSemaphore) {
                dispatch_semaphore_signal(_retryingSemaphore);
            }
        });
    }
    [barrier.task waitForResult:nil];
}

#pragma mark - AGRestReachabilityQueue
#pragma mark -

- (void)reachability:(AGRestReachabilityManager *)manager didReachabilityChanged:(AGRestReachabilityStatus)status {
    self.connected = (status != AGRestReachabilityStatusNotReachable);
}

@end
