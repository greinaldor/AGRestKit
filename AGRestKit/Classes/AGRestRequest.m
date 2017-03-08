//
//  AGRestRequest.m
//  AGRestKit
//
//  Created by Adrien Greiner on 18/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestRequest.h"

#import <Bolts/BFTask.h>
#import "BFTask+Private.h"

#import "AGRest_Private.h"
#import "AGRestRequest_Private.h"
#import "AGRestManager.h"
#import "AGRestCore.h"
#import "AGRestRequestController.h"
#import "AGRestLogger.h"

static NSString * const kAGRequestBaseUrlKey        = @"baseu-rl";
static NSString * const kAGRequestEndpointKey       = @"endpoint";
static NSString * const kAGRequestHTTPMethodKey     = @"http";
static NSString * const kAGRequestCachePolicyKey    = @"cache-policy";
static NSString * const kAGRequestRetryCountKey     = @"retry-count";
static NSString * const kAGRequestIdentifierKey     = @"identifier";
static NSString * const kAGRequestTimeoutPolicyKey  = @"timeout-policy";
static NSString * const kAGRequestShouldRunEventually = @"should-run-eventually";
static NSString * const kAGRequestHeadersKey        = @"headers";
static NSString * const kAGRequestBodyKey           = @"body";
static NSString * const kAGRequestDataKey           = @"data";
static NSString * const kAGRequestTargetClass       = @"targetClass";

@interface AGRestRequest()

@property (strong) NSMutableDictionary          *headers_;
@property (strong) NSMutableDictionary          *body_;
@property (strong) NSMutableArray               *data_;

@property (strong) __block BFCancellationTokenSource  *cancellationSource;

@end

@implementation AGRestRequest

@synthesize requestIdentifier = _requestIdentifier;
@synthesize shouldRunEventually = _shouldRunEventually;

- (instancetype)init
{
    if ((self = [super init])) {
        self.cachePolicy = kAGRestRequestNetworkOnly;
        self.timeoutPolicy = kAGRestRequestTimeoutNone;
        self.retryCount = 1;
        self.httpMethod = 0;
        self.requestIdentifier = [[NSUUID UUID] UUIDString];
        self.objectMappingEnabled = YES;
    }
    return self;
}

+ (instancetype)requestWithDictionary:(nonnull NSDictionary *)dictionary {
    return [[AGRestRequest alloc] initWithDictionary:dictionary];
}

#pragma mark - AGRestCachable
#pragma mark -

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if ((self = [super init])) {
        self.baseUrl            = [dictionary objectForKey:kAGRequestBaseUrlKey];
        self.endPoint           = [dictionary objectForKey:kAGRequestEndpointKey];
        self.headers_           = [dictionary objectForKey:kAGRequestHeadersKey];
        self.body_              = [dictionary objectForKey:kAGRequestBodyKey];
        self.data_              = [dictionary objectForKey:kAGRequestDataKey];
        self.requestIdentifier  = [dictionary objectForKey:kAGRequestIdentifierKey];
        self.cachePolicy        = [[dictionary objectForKey:kAGRequestIdentifierKey] integerValue];
        self.timeoutPolicy      = [[dictionary objectForKey:kAGRequestTimeoutPolicyKey] integerValue];
        self.httpMethod         = [[dictionary objectForKey:kAGRequestHTTPMethodKey] integerValue];
        self.retryCount         = [[dictionary objectForKey:kAGRequestRetryCountKey] integerValue];
        self.shouldRunEventually= [[dictionary objectForKey:kAGRequestShouldRunEventually] boolValue];
        self.targetClass        = NSClassFromString([dictionary objectForKey:kAGRequestTargetClass]);
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary * selfRepresentation = [NSMutableDictionary dictionary];
    
    selfRepresentation[kAGRequestBaseUrlKey]       = self.baseUrl;
    selfRepresentation[kAGRequestEndpointKey]      = self.endPoint;
    selfRepresentation[kAGRequestHeadersKey]       = self.headers_;
    selfRepresentation[kAGRequestBodyKey]          = self.body_;
    selfRepresentation[kAGRequestDataKey]          = self.data_;
    selfRepresentation[kAGRequestIdentifierKey]    = self.requestIdentifier;
    selfRepresentation[kAGRequestIdentifierKey]    = @(self.cachePolicy);
    selfRepresentation[kAGRequestTimeoutPolicyKey] = @(self.timeoutPolicy);
    selfRepresentation[kAGRequestHTTPMethodKey]    = @(self.httpMethod);
    selfRepresentation[kAGRequestRetryCountKey]    = @(self.retryCount);
    selfRepresentation[kAGRequestShouldRunEventually] = @(self.shouldRunEventually);
    selfRepresentation[kAGRequestTargetClass]      = NSStringFromClass(self.targetClass);
    
    return [NSDictionary dictionaryWithDictionary:selfRepresentation];
}

+ (BOOL)isValidDictionaryRepresentation:(NSDictionary *)dictionary {
    return YES;
}

#pragma mark - NSCopying
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [self.class requestWithMethod:self.httpMethod
                                        url:[NSString stringWithString:self.baseUrl]
                                   endPoint:[NSString stringWithString:self.endPoint]
                                    headers:[NSDictionary dictionaryWithDictionary:self.headers]
                                       body:[NSDictionary dictionaryWithDictionary:self.body]
                                       data:[NSArray arrayWithArray:self.data]];
    if (copy) {
        [copy setRetryCount:self.retryCount];
        [copy setTimeoutPolicy:self.timeoutPolicy];
        [copy setTimeoutBlock:self.timeoutBlock];
        [copy setRequestIdentifier:self.requestIdentifier];
    }
    return copy;
}

#pragma mark - NSCoding
#pragma mark -

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.baseUrl           forKey:kAGRequestBaseUrlKey];
    [aCoder encodeObject:self.endPoint          forKey:kAGRequestEndpointKey];
    [aCoder encodeObject:self.headers_          forKey:kAGRequestHeadersKey];
    [aCoder encodeObject:self.body_             forKey:kAGRequestBodyKey];
    [aCoder encodeObject:self.data_             forKey:kAGRequestDataKey];
    [aCoder encodeObject:self.requestIdentifier forKey:kAGRequestIdentifierKey];
    [aCoder encodeInteger:self.httpMethod       forKey:kAGRequestHTTPMethodKey];
    [aCoder encodeInteger:self.cachePolicy      forKey:kAGRequestCachePolicyKey];
    [aCoder encodeInteger:self.timeoutPolicy    forKey:kAGRequestTimeoutPolicyKey];
    [aCoder encodeInteger:self.retryCount       forKey:kAGRequestRetryCountKey];
    [aCoder encodeBool:self.shouldRunEventually forKey:kAGRequestShouldRunEventually];
    [aCoder encodeObject:NSStringFromClass(self.targetClass) forKey:kAGRequestTargetClass];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (!(self = [super init])) {
        return nil;
    }
    
    self.baseUrl            = [aDecoder decodeObjectForKey:kAGRequestBaseUrlKey];
    self.endPoint           = [aDecoder decodeObjectForKey:kAGRequestEndpointKey];
    self.headers_           = [aDecoder decodeObjectForKey:kAGRequestHeadersKey];
    self.body_              = [aDecoder decodeObjectForKey:kAGRequestBodyKey];
    self.data_              = [aDecoder decodeObjectForKey:kAGRequestDataKey];
    self.requestIdentifier  = [aDecoder decodeObjectForKey:kAGRequestIdentifierKey];
    self.cachePolicy        = [aDecoder decodeIntegerForKey:kAGRequestIdentifierKey];
    self.timeoutPolicy      = [aDecoder decodeIntegerForKey:kAGRequestTimeoutPolicyKey];
    self.httpMethod         = [aDecoder decodeIntegerForKey:kAGRequestHTTPMethodKey];
    self.retryCount         = [aDecoder decodeIntegerForKey:kAGRequestRetryCountKey];
    self.shouldRunEventually= [aDecoder decodeBoolForKey:kAGRequestShouldRunEventually];
    self.targetClass        = [aDecoder decodeObjectForKey:kAGRequestTargetClass];
    
    return self;
}

#pragma mark - Setter
#pragma mark -

- (void)setRequestIdentifier:(NSString * _Nonnull)requestIdentifier {
    @synchronized(self) {
        _requestIdentifier = requestIdentifier;
    }
}

- (NSString *)requestIdentifier {
    @synchronized(self) {
        return _requestIdentifier;
    }
}

- (void)setShouldRunEventually:(BOOL)shouldExecuteEventually {
    @synchronized(self) {
        _shouldRunEventually = shouldExecuteEventually;
    }
}

- (BOOL)shouldRunEventually {
    @synchronized(self) {
        return _shouldRunEventually;
    }
}

#pragma mark - Getter
#pragma mark -

- (nullable NSDictionary *)body {
    return [NSDictionary dictionaryWithDictionary:self.body_];
}

- (nullable NSDictionary *)headers {
    return [NSDictionary dictionaryWithDictionary:self.headers_];
}

- (nullable NSArray *)data {
    return [NSArray arrayWithArray:self.data_];
}

- (nullable NSString *)requestURL
{
    NSMutableString *urlString = [NSMutableString string];
    if (self.baseUrl) {
        [urlString appendFormat:@"%@/", self.baseUrl];
    }
    if (self.endPoint) {
        [urlString appendFormat:@"%@", self.endPoint];
    }
    return (urlString.length)?urlString:nil;
}

#pragma mark - Constructors
#pragma mark -

+ (instancetype)requestWithMethod:(AGRestRequestHTTPMethod)method
                              url:(nonnull NSString *)baseUrl
                         endPoint:(nonnull NSString *)endPoint
                          headers:(nullable NSDictionary *)headers
                             body:(nullable NSDictionary *)body
                             data:(nullable NSArray *)arrayData
{
    AGRestRequest *request = [[AGRestRequest alloc] init];
    request.baseUrl = baseUrl;
    request.endPoint = endPoint;
    request.httpMethod = method;
    if (headers) {
        request.headers_ = [NSMutableDictionary dictionaryWithDictionary:headers];
    }
    if (body) {
        request.body_ = [NSMutableDictionary dictionaryWithDictionary:body];
    }
    if (arrayData) {
        request.data_ = [NSMutableArray arrayWithArray:arrayData];
    }
    return request;
}

+ (instancetype)requestWithMethod:(AGRestRequestHTTPMethod)method
                              url:(nonnull NSString *)baseUrl
                         endPoint:(nonnull NSString *)endPoint
                          headers:(nullable NSDictionary *)headers
                             body:(nullable NSDictionary *)body
{
    return [AGRestRequest requestWithMethod:method
                                        url:baseUrl
                                   endPoint:endPoint
                                    headers:headers
                                       body:body
                                       data:nil];
}

+ (instancetype)POSTRequestWithUrl:(nonnull NSString *)url
                          endPoint:(nonnull NSString *)endPoint
                              body:(nullable NSDictionary *)body
{
    return [AGRestRequest requestWithMethod:AGRestRequestMethodHttpPOST
                                        url:url
                                   endPoint:endPoint
                                    headers:nil
                                       body:body
                                       data:nil];
}

+ (instancetype)GETRequestWithUrl:(nonnull NSString *)url
                         endPoint:(nonnull NSString *)endPoint
                             body:(nullable NSDictionary *)body
{
    return [AGRestRequest requestWithMethod:AGRestRequestMethodHttpGET
                                        url:url
                                   endPoint:endPoint
                                    headers:nil
                                       body:body
                                       data:nil];
}

+ (instancetype)HEADRequestWithUrl:(nonnull NSString *)url
                          endPoint:(nonnull NSString *)endPoint
                           headers:(nonnull NSDictionary *)headers
                              body:(nullable NSDictionary *)body
{
    return [AGRestRequest requestWithMethod:AGRestRequestMethodHttpHEAD
                                        url:url
                                   endPoint:endPoint
                                    headers:headers
                                       body:body
                                       data:nil];
}

+ (instancetype)PUTRequestWithUrl:(nonnull NSString *)url
                         endPoint:(nonnull NSString *)endPoint
                             body:(nullable NSDictionary *)body
{
    return [AGRestRequest requestWithMethod:AGRestRequestMethodHttpPUT
                                        url:url
                                   endPoint:endPoint
                                    headers:nil
                                       body:body
                                       data:nil];
}

+ (instancetype)DELETERequestWithUrl:(nonnull NSString *)url
                            endPoint:(nonnull NSString *)endPoint
                                body:(nullable NSDictionary *)body
{
    return [AGRestRequest requestWithMethod:AGRestRequestMethodHttpDELETE
                                        url:url
                                   endPoint:endPoint
                                    headers:nil
                                       body:body
                                       data:nil];
}

#pragma mark - Configure
#pragma mark -

- (void)setValue:(nonnull NSString *)value forHTTPHeaderField:(nonnull NSString *)key {
    [self.headers_ setObject:value forKey:key];
}

#pragma mark - send Data
#pragma mark -

#pragma mark Single Request

- (nullable BFTask *)sendRequest {
    if (!_cancellationSource) {
        BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];
        [[self sendRequestInBackground] continueWithBlock:^id(BFTask *task) {
            if (!task.result) {
                [taskCompletion setError:task.error];
            } else {
                [taskCompletion setResult:task.result];
            }
            return nil;
        } cancellationToken:_cancellationSource.token];
        [taskCompletion.task waitUntilFinished];
        return taskCompletion.task;
    }
    return nil;
}

- (void)sendRequestWithBlock:(nullable AGRestRequestResultBlock)completionBlock {
    [[self sendRequest] continueWithBlock:^id(BFTask *task)
     {
         if (!task.isCancelled) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 completionBlock(task.result);
             });
         }
         return nil;
     }];
}

- (void)sendRequestWithTarget:(nonnull id)target selector:(nonnull SEL)aSelector {
    if (target && [target respondsToSelector:aSelector]) {
        weakify(target);
        [[self sendRequest] continueWithBlock:^id(BFTask *task) {
            strongify(target);
            if (strongSelf && !task.isCancelled && target) {
                [strongSelf performSelectorOnMainThread:aSelector withObject:task.result waitUntilDone:YES];
            }
            return nil;
        }];
    }
}

- (BFTask *)sendRequestInBackground {
    if (!_cancellationSource)
    {
        _cancellationSource = [BFCancellationTokenSource cancellationTokenSource];
        return [[[AGRestRequest _requestController] runRequestAsync:self withCancellationToken:_cancellationSource.token]
                continueWithBlock:^id(BFTask *task) {
            _cancellationSource = nil;
            return task;
        }];
    }
    return nil;
}

- (void)sendRequestInBackgroundWithBlock:(nullable AGRestRequestResultBlock)completionBlock {
    [[self sendRequestInBackground] continueWithBlock:^id(BFTask *task)
     {
         if (!task.isCancelled) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 completionBlock(task.result);
             });
         }
         return nil;
     }];
}

- (void)sendRequestInBackrgoundWithTarget:(nonnull id)target selector:(nonnull SEL)aSelector {
    if (target && [target respondsToSelector:aSelector]) {
        weakify(target);
        [[self sendRequestInBackground] continueWithBlock:^id(BFTask *task) {
            strongify(weakSelf);
            if (strongSelf && !task.isCancelled) {
                [strongSelf performSelectorOnMainThread:aSelector withObject:task.result waitUntilDone:NO];
            }
            return nil;
        }];
    }
}

- (void)sendRequestEventuallyWithBlock:(nullable AGRestRequestResultBlock)completionBlock {
    [self setShouldRunEventually:YES];
    [self sendRequestWithBlock:completionBlock];
}

- (void)sendRequestEventuallyWithTarget:(nonnull id)target selector:(nonnull SEL)aSelector {
    if (target && [target respondsToSelector:aSelector]) {
        weakify(target);
        [self sendRequestEventuallyWithBlock:^(AGRestResponse * _Nonnull response) {
            strongify(target);
            if (strongSelf && !response.cancelled) {
                [strongSelf performSelectorOnMainThread:aSelector withObject:response waitUntilDone:YES];
            }
        }];
    }
}

- (void)sendRequestEventuallyInBackgroundWithBlock:(AGRestRequestResultBlock)completionBlock {
    [self setShouldRunEventually:YES];
    [self sendRequestInBackgroundWithBlock:completionBlock];
}

- (void)sendRequestEventuallyInBackgroundWithTarget:(nonnull id)target selector:(nonnull SEL)aSelector {
    if (target && [target respondsToSelector:aSelector]) {
        weakify(target);
        [self sendRequestEventuallyInBackgroundWithBlock:^(AGRestResponse * _Nonnull response) {
            strongify(weakSelf);
            if (weakSelf && !response.cancelled) {
                [strongSelf performSelectorOnMainThread:aSelector withObject:response waitUntilDone:NO];
            }
        }];
    }
}

#pragma mark - Batched Requests

+ (nullable BFTask *)sendBatchedRequests:(nonnull NSArray *)requests {
    if (requests && requests.count) {
        BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];
        [[AGRestRequest sendBatchedRequestsInBackground:requests] continueWithBlock:^id(BFTask *task) {
            [taskCompletion setResult:task.result];
            return nil;
        }];
        [taskCompletion.task waitUntilFinished];
        return taskCompletion.task;
    }
    return nil;
}

+ (void)sendBatchedRequests:(nonnull NSArray *)requests withCompletionBlock:(nullable AGRestBatchResponseCompletionBlock)completionBlock {
    [[[self class] sendBatchedRequests:requests] continueWithBlock:^id(BFTask *task)
     {
         if (!task.isCancelled && completionBlock) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 completionBlock(task.result);
             });
         }
         return nil;
     }];
}

+ (void)sendBatchedRequests:(nonnull NSArray *)requests withTarget:(nonnull id)target selector:(nonnull SEL)aSelector {
    if (target && [target respondsToSelector:aSelector]) {
        weakify(target);
        [[[self class] sendBatchedRequests:requests] continueWithBlock:^id(BFTask *task) {
            strongify(weakSelf);
            if (strongSelf && !task.cancelled) {
                [strongSelf performSelectorOnMainThread:aSelector withObject:task.result waitUntilDone:YES];
            }
            return nil;
        }];
    }
}

+ (nullable BFTask *)sendBatchedRequestsInBackground:(nonnull NSArray *)requests {
    if (requests && requests.count) {
        // Create an array of BFTask
        NSMutableArray *requestTasks = [NSMutableArray arrayWithCapacity:requests.count];
        for (id request in requests) {
            if ([request isKindOfClass:[AGRestRequest class]]) {
                // Check that request can't stop execution
                if (((AGRestRequest *)request).timeoutPolicy == kAGRestRequestTimeoutStopExecution ||
                    ((AGRestRequest *)request).timeoutBlock) {
                    AGRestLogWarn(@"Request is ignored. A batched request cannot have a timeout policy that stops the execution or a custom timeout block.");
                } else {
                    [requestTasks addObject:[(AGRestRequest *)request sendRequestInBackground]];
                }
            }
        }
        // Wait for all tasks to execute and return the running batch request task
        return [BFTask taskForCompletionOfAllTasksWithResults:requestTasks];
    }
    return nil;
}

+ (void)sendBatchedRequestsInBackground:(nonnull NSArray *)requests withCompletionBlock:(nullable AGRestBatchResponseCompletionBlock)completionBlock {
    [[[self class] sendBatchedRequestsInBackground:requests] continueWithBlock:^id(BFTask *task)
     {
         if (!task.isCancelled && completionBlock) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 completionBlock(task.result);
             });
         }
         return nil;
     }];
}

+ (void)sendBatchedRequestsInBackground:(NSArray *)requests withTarget:(nonnull id)target selector:(nonnull SEL)aSelector {
    if (target && [target respondsToSelector:aSelector]) {
        weakify(target);
        [[[self class] sendBatchedRequestsInBackground:requests] continueWithBlock:^id(BFTask *task) {
            strongify(weakSelf);
            if (strongSelf && !task.isCancelled) {
                [strongSelf performSelectorOnMainThread:aSelector withObject:task.result waitUntilDone:NO];
            }
            return nil;
        }];
    }
}

#pragma mark - Request Lifecycle

- (BOOL)cancel {
    if (_cancellationSource) {
        [_cancellationSource cancel];
        return YES;
    }
    return NO;
}

#pragma mark - Private
#pragma mark -

- (void)_validateRequestState {
    
}

- (void)_markAsRunning:(BFCancellationTokenSource *)source {
    @synchronized(self) {
        _cancellationSource = source;
    }
}

+ (AGRestRequestController *)_requestController {
    return [AGRest _currentManager].core.requestController;
}

@end
