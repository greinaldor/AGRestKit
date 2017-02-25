//
//  AGRestServer.m
//  AGRestStack
//
//  Created by Adrien Greiner on 18/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestServer.h"

#import <Foundation/Foundation.h>

#import "Bolts.h"
#import "BFTask+Private.h"

#import "AFHTTPSessionOperation.h"

#import "AGRestRequest.h"
#import "AGRestRequest+Format.h"
#import "AGRestResponse.h"
#import "AGRestErrorUtilities.h"
#import "AGRestLogger.h"

#define kRestServerMaxConcurrentOperationsWAN   2
#define kRestServerMaxConcurrentOperationsWIFI  4

static NSString * const kAlamoSerializationReponseErrorData = @"com.alamofire.serialization.response.error.data";

@interface AGRestServer () {
    dispatch_queue_t _executionAccessQueue;
    dispatch_queue_t _operationQueueAccessQueue;
}

@property (nonatomic, strong, readonly) NSOperationQueue     *operationsQueue;

- (BFTask *)_performRequestWithIdentifier:(nonnull NSString *)requestIdentifier
                                   method:(nonnull NSString *)method
                                URLString:(nonnull NSString *)url
                               parameters:(nullable id)parameters
                                  headers:(nullable NSDictionary *)headers
                                  options:(AGRestRequestRunningOptions)options
                        cancellationToken:(nullable BFCancellationToken *)cancellationToken;

- (void)didReachabilityChanged:(NSNotification *)aNotification;

@end

static NSString * kRestServerOperationsQueueName         = @"com.restserver.operations";

static NSString * kRestServerHTTPHeaderAuthorizationKey  = @"Authorization";
static NSString * kRestServerHTTPHeaderContentTypeKey    = @"Content-Type";
static NSString * kRestServerHTTPHeaderAcceptKey         = @"Accept";
static NSString * kRestServerHTTPContentTypeJson         = @"application/json";

@interface AGRestServer()

- (void)configureServer;

@end

static AGRestServer *_sharedServer = nil; // shared instance

@implementation AGRestServer

@synthesize operationsQueue = _operationsQueue;

#pragma mark - Init methods
#pragma mark -

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (BOOL)initializeWithBaseUrl:(nonnull NSString *)url
{
    __block BOOL ret = NO;
    
    if (!url || !url.length)
        return ret;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedServer = [[AGRestServer alloc] initWithBaseURL:[NSURL URLWithString:url]];
        if (_sharedServer) {
            [_sharedServer configureServer];
            ret = YES;
        }
    });
    return ret;
}

- (void)reset {
    @synchronized(_sharedServer) {
        _sharedServer = nil;
    }
}

- (void)configureServer
{
    _executionAccessQueue = dispatch_queue_create("com.AGRest.server.executionAccessQueue", DISPATCH_QUEUE_SERIAL);
    _operationQueueAccessQueue = dispatch_queue_create("com.AGRest.server.operationQueueAccessQueue", DISPATCH_QUEUE_SERIAL);
    
    // Set the server security policy
    [self setSecurityPolicy:[AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone]];
    
    // Set the completion Queue to default priority background queue
    [self setCompletionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    // Configure the session
    [self.session.configuration setTimeoutIntervalForRequest:AGRestRequestSessionTimeoutInterval];
    [self.session.configuration setTimeoutIntervalForResource:AGRestRessourceSessionTimeoutInterval];
    [self.session.configuration setRequestCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    // Set the Response Serializer
    AFCompoundResponseSerializer *responseSerializer = [AFCompoundResponseSerializer serializer];
    [self.responseSerializer setAcceptableContentTypes:[NSSet setWithObject:kRestServerHTTPContentTypeJson]];
    [self setResponseSerializer:responseSerializer];
    
    // Set the Request Serializer
    [self setRequestSerializer:[AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted]];
    [self.requestSerializer setValue:kRestServerHTTPContentTypeJson forHTTPHeaderField:kRestServerHTTPHeaderAcceptKey];
    [self.requestSerializer setValue:kRestServerHTTPContentTypeJson forHTTPHeaderField:kRestServerHTTPHeaderContentTypeKey];
    [self.requestSerializer setHTTPShouldHandleCookies:NO];
    [self.requestSerializer setTimeoutInterval:AGRestRequestSessionTimeoutInterval];
        
    // Start monitoring reachability
    [self.reachabilityManager startMonitoring];
    
    // Register for reachability update
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReachabilityChanged:)
                                                 name:AFNetworkingReachabilityDidChangeNotification
                                               object:nil];
}

+ (nullable instancetype)sharedServer
{
    return _sharedServer;
}

- (NSOperationQueue *)operationsQueue {
    __block NSOperationQueue * operationQueue = nil;
    dispatch_sync(_operationQueueAccessQueue, ^{
        if (!_operationsQueue) {
            // Configure operations queue
            _operationsQueue = [[NSOperationQueue alloc] init];
            _operationsQueue.maxConcurrentOperationCount = kRestServerMaxConcurrentOperationsWAN;
            _operationsQueue.name = kRestServerOperationsQueueName;
            _operationsQueue.qualityOfService = NSQualityOfServiceUserInitiated;
        }
        operationQueue = _operationsQueue;
    });
    return operationQueue;
}

#pragma mark - AGRestRequestRunning
#pragma mark -

- (BFTask *)runRequestAsync:(AGRestRequest *)request withOptions:(AGRestRequestRunningOptions)options {
    return [self runRequestAsync:request withOptions:options cancellationToken:nil];
}

- (BFTask *)runRequestAsync:(AGRestRequest *)request
                withOptions:(AGRestRequestRunningOptions)options
          cancellationToken:(BFCancellationToken *)token
{
    if (token.cancellationRequested) {
        return [BFTask cancelledTask];
    }
    
    return [BFTask taskFromExecutor:[BFExecutor executorWithDispatchQueue:_executionAccessQueue] withBlock:^id{
        @autoreleasepool {
            switch (request.httpMethod)
            {
                case AGRestRequestMethodHttpPOST:
                case AGRestRequestMethodHttpPUT:
                case AGRestRequestMethodHttpHEAD:
                case AGRestREquestMethodHttpPATCH:
                case AGRestRequestMethodHttpGET:
                case AGRestRequestMethodHttpDELETE:
                {
                    return [self _performRequestWithIdentifier:request.requestIdentifier
                                                        method:request.httpMethodString
                                                     URLString:request.endPoint
                                                    parameters:request.body
                                                       headers:request.headers
                                                       options:options
                                             cancellationToken:token];
                } break;
                    
                default: {
                    NSString *errorMsg = [NSString stringWithFormat:@"<AGRestServer> HTTP method not supported : %@", request.httpMethodString];
                    NSError *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal
                                                                    message:errorMsg
                                                                  shouldLog:NO];
                    return [BFTask taskWithError:error];
                }  break;
            }
        }
    }];
}

#pragma mark - AGRestServerProtocol
#pragma mark -

- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(nonnull NSString *)key {
    [self.requestSerializer setValue:value forHTTPHeaderField:key];
}

- (void)setAcceptableContentTypes:(nonnull NSSet *)contentTypes {
    [self.responseSerializer setAcceptableContentTypes:contentTypes];
}

- (void)setAcceptableStatusCodes:(nonnull NSIndexSet *)httpStatusCodes {
    [self.responseSerializer setAcceptableStatusCodes:httpStatusCodes];
}

#pragma mark - Private()
#pragma mark -

- (BFTask *)_performRequestWithIdentifier:(nonnull NSString *)requestIdentifier
                                   method:(nonnull NSString *)method
                                URLString:(nonnull NSString *)url
                               parameters:(nullable id)parameters
                                  headers:(nullable NSDictionary *)headers
                                  options:(AGRestRequestRunningOptions)options
                        cancellationToken:(nullable BFCancellationToken *)cancellationToken
{
    if (cancellationToken.cancellationRequested) {
        return [BFTask cancelledTask];
    }
    
    weakify(self)
    BFTask *task = [BFTask taskFromExecutor:[BFExecutor executorWithDispatchQueue:_executionAccessQueue] withBlock:^id{
        strongify(weakSelf)
        if (strongSelf)
        {
            AGRestLogInfo(@"<AGRestServer> Fetch request <%@> in background :\nmethod: %@\nurl: %@\nparams: %@\nheaders: %@\n",
                          requestIdentifier, method, url, (parameters)?:@"nil", (headers)?:@"nil");
            
            BFTaskCompletionSource *completionSource = [BFTaskCompletionSource taskCompletionSource];
            
            void (^success)(NSURLSessionDataTask *, id) = ^(NSURLSessionDataTask *task, id result)
            {
                // Map with AGRestResponse
                NSDictionary    *header = [(NSHTTPURLResponse *)task.response allHeaderFields];
            
                NSInteger       statusCode = [(NSHTTPURLResponse *)task.response statusCode];
                AGRestResponse  *response = [AGRestResponse responseWithData:result
                                                                      header:header
                                                                  statusCode:statusCode];
                [completionSource setResult:response];
            };
            void (^failure)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError *error)
            {
                // Map with AGRestResponse
                NSInteger       statusCode = [(NSHTTPURLResponse *)task.response statusCode];
                
                NSData          *errorData = error.userInfo[kAlamoSerializationReponseErrorData];
                NSDictionary    *errorDict = nil;
                if (errorData) {
                    errorDict = [NSJSONSerialization JSONObjectWithData:errorData options:NSJSONReadingAllowFragments error:nil];
                }
                
                AGRestResponse  *response = [AGRestResponse responseWithError:error statusCode:statusCode];
                response.responseData = errorDict;
                [completionSource setResult:response];
            };
            
            // Create the request operation
            AFHTTPSessionOperation *operation = [AFHTTPSessionOperation operationWithManager:strongSelf
                                                                                      method:method
                                                                                   urlString:url
                                                                                  parameters:parameters
                                                                                     headers:headers
                                                                                     success:success
                                                                                     failure:failure];
            // Set Operation name
            operation.name = [NSString stringWithFormat:@"Request<%@> %@", requestIdentifier, url];
            
            // Add cancellation token block
            [cancellationToken registerCancellationObserverWithBlock:^{
                [operation cancel];
            }];
            
            // Add Operation to the queue
            [strongSelf.operationsQueue addOperation:operation];
            return completionSource.task;
        }
        return [BFTask taskWithResult:nil];
    }];
    return task;
}

- (void)didReachabilityChanged:(NSNotification *)aNotification {
    
    // Update max concurrent operations depending of the connectivity
    NSInteger reachabilityStatus = [aNotification.object integerValue];
    switch (reachabilityStatus) {
        case AFNetworkReachabilityStatusNotReachable: break;
        case AFNetworkReachabilityStatusReachableViaWWAN: {
            self.operationsQueue.maxConcurrentOperationCount = kRestServerMaxConcurrentOperationsWAN;
        } break;
        case AFNetworkReachabilityStatusReachableViaWiFi: {
            self.operationsQueue.maxConcurrentOperationCount = kRestServerMaxConcurrentOperationsWIFI;
        } break;
        case AFNetworkReachabilityStatusUnknown: break;
        default: break;
    }
}

@end
