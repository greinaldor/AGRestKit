//
//  AGRestRequestRunner.m
//  AGRestStack
//
//  Created by Adrien Greiner on 25/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestRequestRunner.h"

#import <Bolts/BFTask.h>
#import "BFTask+Private.h"

#import "AGRestConstants.h"
#import "AGRestResponse.h"
#import "AGRestRequest.h"
#import "AGRestServer.h"
#import "AGRestCore.h"
#import "AGRestLogger.h"

#define kDefaultInitialRetryDelay   2.f

@interface AGRestRequestRunner()

@property (nonatomic, assign) NSInteger     initialRetryDelay;
@property (strong) NSMutableDictionary      *runningRequests;

@end

@implementation AGRestRequestRunner

@synthesize dataSource = _dataSource;

- (instancetype)initWithDataSource:(id<AGRestCoreManagerDataSource>)dataSource {
    self = [super init];
    if (!self) return nil;
    
    self.dataSource = dataSource;
    self.initialRetryDelay = kDefaultInitialRetryDelay;
    self.runningRequests = [NSMutableDictionary dictionaryWithCapacity:16];
    
    return self;
}

#pragma mark - Request Running

- (BFTask *)runRequestAsync:(AGRestRequest *)request
                withOptions:(AGRestRequestRunningOptions)options
{
    return [self runRequestAsync:request withOptions:options cancellationToken:nil];
}

- (BFTask *)runRequestAsync:(AGRestRequest *)request
                withOptions:(AGRestRequestRunningOptions)options
          cancellationToken:(BFCancellationToken *)token
{
    // If same request already executing then return cancelled task
    if ([[self.runningRequests allKeys] containsObject:request.requestIdentifier])
        return [BFTask cancelledTask];
    
    // Return a task that will executes on background
    weakify(self)
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        strongify(weakSelf)
        // Declare the server execution block
        id (^serverRequestBlock)() = ^{
            return [strongSelf.dataSource.requestServer runRequestAsync:request withOptions:options cancellationToken:token];
        };
        
        // Register request as running request
        [strongSelf.runningRequests setObject:request forKey:request.requestIdentifier];
        
        // Perform the request
        return [[strongSelf _performRequestWithBlock:serverRequestBlock
                                         withOptions:(request.timeoutPolicy == kAGRestRequestTimeoutRetry)?AGRestRequestRunningOptionRetryIfFailed:-1
                                        withAttempts:request.retryCount
                                   cancellationToken:token] continueWithBlock:^id(BFTask *task) {
            strongify(weakSelf)
            // Remove request from running requests
            [strongSelf.runningRequests removeObjectForKey:request.requestIdentifier];
            return task;
        }];
    }];
}

#pragma mark - Private

- (BFTask *)_performRequestWithBlock:(nonnull id (^)())block
                         withOptions:(AGRestRequestRunningOptions)options
                        withAttempts:(NSUInteger)attemps
                   cancellationToken:(BFCancellationToken *)cancellationToken {
    
    if (cancellationToken.cancellationRequested) {
        return [BFTask cancelledTask];
    }
    
    // If shouldn't retry return block execution
    if (!(options & AGRestRequestRunningOptionRetryIfFailed)) {
        return block();
    }
    
    NSTimeInterval delay = self.initialRetryDelay; // Delay (secs) of next retry attempt
    
    // Set the initial delay to something between 1 and 2 seconds. We want it to be
    // random so that clients that fail simultaneously don't retry on simultaneous
    // intervals.
    delay += self.initialRetryDelay * ((double)(arc4random() & 0x0FFFF) / (double)0x0FFFF);
    return [self _performRequestRunningBlock:block
                       withCancellationToken:cancellationToken
                                       delay:delay
                                 forAttempts:attemps];
}

- (BFTask *)_performRequestRunningBlock:(nonnull id (^)())block
                  withCancellationToken:(BFCancellationToken *)cancellationToken
                                  delay:(NSTimeInterval)delay
                            forAttempts:(NSUInteger)attempts {
    weakify(self);
    return [block() continueWithBlock:^id(BFTask *task) {
        strongify(weakSelf);
        if (task.cancelled) {
            return task;
        }
        
        AGRestLogInfo(@"Attemps %ld", (unsigned long)attempts);
        
        AGRestResponse * response = task.result;
        if (response.responseError && response.responseError.code == NSURLErrorTimedOut && attempts > 1) {
            return [[BFTask taskWithDelay:(int)(delay * 1000)] continueWithBlock:^id(BFTask *task) {
                return [strongSelf _performRequestRunningBlock:block
                                         withCancellationToken:cancellationToken
                                                         delay:delay * 2.0
                                                   forAttempts:attempts - 1];
            } cancellationToken:cancellationToken];
        }
        return task;
    } cancellationToken:cancellationToken];
}

@end
