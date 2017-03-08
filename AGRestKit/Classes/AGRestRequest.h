//
//  AGRestRequest.h
//  AGRestKit
//
//  Created by Adrien Greiner on 18/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AGRestConstants.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  @typedef AGRestRequestCachePolicy
 *  `AGRestRequestCachePolicy` enums contains all possible cache policy for `AGRestRequest`
 */
typedef NS_ENUM(NSInteger, AGRestRequestCachePolicy) {
    /*!
     The request does not load from the cache or save results to the cache
     */
    kAGRestRequestIgnoreCache = 1,
    /*!
     The request loads from the cache only.
     */
    kAGRestRequestCacheOnly,
    /*!
     The request first loads from the cache, then loads from network
     */
    kAGRestRequestCacheThenNetwork,
    /*!
     The request first loads from the cache, if that fails, it loads results from network
     */
    kAGRestRequestCacheElseNetwork,
    /*!
     The request first loads from network, if that fails, it loads results from cache
     */
    kAGRestRequestNetworkElseCache,
    /*!
     The request does not load from the cache, but it will save results in the cache
     */
    kAGRestRequestNetworkOnly
};

/**
 *  @typedef AGRestRequestTimeoutPolicy
 *  `AGRestRequestTimeoutPolicy` enums contains all possible timeout policy for `AGRestRequest`
 */
typedef NS_ENUM(NSInteger, AGRestRequestTimeoutPolicy) {
    /*!
     The request won't fire any response block if request timed out. Usually a bad idea.
     */
    kAGRestRequestTimeoutStopExecution,
    /*!
     The request will retry once if timed out. You can set the number of retry by setting
     \b requestTimeoutRetryCount:
     */
    kAGRestRequestTimeoutRetry,
    /*!
     The request will return fire a response block with timeout error set.
     @note Default implemetation.
     */
    kAGRestRequestTimeoutNone,
};

@class BFTask;

/*!
 @class AGRestRequest
 @discussion The AGRestRequest class represents a REST API Request and provide all informations for executing complex HTTP request on the server.
 You should use AGRestRequest to send any requests to the API and receive response accordingly. 
 
 You can send requests in many ways, asynchronously or synchronously, single request or batched requests, or eventual requests as well. Once the request is executed,
 you can receive the response using BFTask, blocks or target/selector. 
 
 You also can control the request behaviour when timed out error occurs by setting a custom block that
 will be executed or a timed out policy indicating if the request should retry and how many times before returning.
 
 ## Request Life Cycle
 
 The diagram below shows the basics of the request life cycle.
 
 <div style="display:block; vertical-align:middle; margin: 0 auto;">
    <img style="display: block; margin: 0 auto;" src="../docs/documentation/AGRestKit_Request_Life_Cycle.jpg">
 </div>
 */
@interface AGRestRequest : NSObject <NSCopying, NSCoding>

///-----------------------
#pragma mark Properties
/// @name Properties
///-----------------------
/*!
 @abstract The base url for the request.
 */
@property (nonatomic, strong, nullable) NSString                *baseUrl;
/*!
 @abstract The web service endpoint that the request aim to call.
 */
@property (nonatomic, strong, nullable) NSString                *endPoint;
/*!
 @abstract The cache policy that the request should adopt.
 @discussion By default, the request has kAGRestRequestNetworkOnly policy set.
 */
@property (nonatomic, assign) AGRestRequestCachePolicy          cachePolicy;
/*!
 @abstract The AGRestRequestTimeoutPolicy timeout policy fot the request.
 @discussion By default, the request has no timed out policy.
 @warning If you specify your own timeoutBlock then the timeout policy won't apply for the request.
 */
@property (nonatomic, assign) AGRestRequestTimeoutPolicy        timeoutPolicy;
/*!
 @abstract The number of times the request should retry if fails with _timed out_ error.
 */
@property (nonatomic, assign) NSUInteger                        retryCount;
/*!
 @abstract The HTTP method used to send the request.
 */
@property (nonatomic, assign) AGRestRequestHTTPMethod           httpMethod;
/*!
 @abstract A block to execute if the request failed with _timed out_ error.
 If block return YES then the server will call the response block with the timeout error set.
 If block return NO then the server won't call the response block, this is discouraged.
 @warning If you specify your own timeoutBlock then the timeout policy won't apply for the request.
 */
@property (nonatomic, copy, nullable) AGRestRequestTimeoutCompletionBlock timeoutBlock;
/*!
 @abstract A randomly generated UUID for identifying the request.
 */
@property (nonatomic, strong, nonnull, readonly) NSString       *requestIdentifier;
/*!
 @abstract Wether the request should try to execute later if eventually failed with connection lost error.
 */
@property (nonatomic, assign, readonly) BOOL                    shouldRunEventually;
/*!
 @abstract Target class to map from the response.
 */
@property (nonatomic, copy) Class                               targetClass;
/*!
 @abstract Enable or disable object mapping for request's response.
 If enable, will try to map the response into an instance of `targetClass`.
 */
@property (nonatomic, assign, getter=isObjectMappingEnabled) BOOL objectMappingEnabled;

///-----------------------
#pragma mark - Init
/// @name Init
///-----------------------
/*!
 @abstract Returns a new AGRestRequest instance initialized based on the given dictionary representation.
 @param dictionary The dictionary representing the request.
 @return A new AGRestRequest instance.
 */
+ (instancetype)requestWithDictionary:(NSDictionary *)dictionary;

/*!
 @abstract Returns a new instance initialized with given parameters.
 @param method      The HTTP method.
 @param baseUrl     The base url (optional).
 @param endPoint    The endpoint.
 @param headers     The headers dictionary specific to the request.
 @param body        The body as dictionary to attached with the request.
 @param arrayData   The data to send with the request.
 @return An initialized instance of AGRestRequest.
 */
+ (instancetype)requestWithMethod:(AGRestRequestHTTPMethod)method
                              url:(nonnull NSString *)baseUrl
                         endPoint:(nonnull NSString *)endPoint
                          headers:(nullable NSDictionary *)headers
                             body:(nullable NSDictionary *)body
                             data:(nullable NSArray *)arrayData;
/*!
 @abstract Returns a new instance initialized with given parameters.
 @param method      The HTTP method.
 @param baseUrl     The base url (optional).
 @param endPoint    The endpoint.
 @param headers     The headers dictionary specific to the request.
 @param body        The body as dictionary to attached with the request.
 @return An initialized instance of AGRestRequest.
 */
+ (instancetype)requestWithMethod:(AGRestRequestHTTPMethod)method
                              url:(nonnull NSString *)baseUrl
                         endPoint:(nonnull NSString *)endPoint
                          headers:(nullable NSDictionary *)headers
                             body:(nullable NSDictionary *)body;

/*!
 @abstract Returns a new HTTP POST request instance initialized with given parameters.
 @param url         The base url (optional).
 @param endPoint    The endpoint.
 @param body        The body as dictionary to attached with the request.
 @return An initialized instance of AGRestRequest.
 */
+ (instancetype)POSTRequestWithUrl:(nonnull NSString *)url
                          endPoint:(nonnull NSString *)endPoint
                              body:(nullable NSDictionary *)body;

/*!
 @abstract Returns a new HTTP GET request instance initialized with given parameters.
 @param url         The base url (optional).
 @param endPoint    The endpoint.
 @param body        The body as dictionary to attached with the request.
 @return An initialized instance of AGRestRequest.
 */
+ (instancetype)GETRequestWithUrl:(nonnull NSString *)url
                         endPoint:(nonnull NSString *)endPoint
                             body:(nullable NSDictionary *)body;
/*!
 @abstract Returns a new HTTP HEAD request instance initialized with given parameters.
 @param url         The base url (optional).
 @param endPoint    The endpoint.
 @param headers     The headers dictionary specific to the request.
 @param body        The body as dictionary to attached with the request.
 @return An initialized instance of AGRestRequest.
 */
+ (instancetype)HEADRequestWithUrl:(nonnull NSString *)url
                          endPoint:(nonnull NSString *)endPoint
                           headers:(nonnull NSDictionary *)headers
                              body:(nullable NSDictionary *)body;

/*!
 @abstract Returns a new HTTP PUT request instance initialized with given parameters.
 @param url         The base url (optional).
 @param endPoint    The endpoint.
 @param body        The body as dictionary to attached with the request.
 @return An initialized instance of AGRestRequest.
 */
+ (instancetype)PUTRequestWithUrl:(nonnull NSString *)url
                         endPoint:(nonnull NSString *)endPoint
                             body:(nullable NSDictionary *)body;

/*!
 @abstract Returns a new HTTP DELETE request instance initialized with given parameters.
 @param url         The base url (optional).
 @param endPoint    The endpoint.
 @param body        The body as dictionary to attached with the request.
 @return An initialized instance of AGRestRequest.
 */
+ (instancetype)DELETERequestWithUrl:(nonnull NSString *)url
                            endPoint:(nonnull NSString *)endPoint
                                body:(nullable NSDictionary *)body;

///-----------------------
#pragma mark - Getter
/// @name Getter
///-----------------------
/*!
 @return The body of the request
 */
- (nullable NSDictionary *)body;
/*!
 @return HTTP header fields attached to the request.
 */
- (nullable NSDictionary *)headers;
/*!
 @return The array of data to send with the request.
 */
- (nullable NSArray *)data;
/*!
 @return The full request url, formed with \b baseUrl + \b endPoint.
 */
- (nullable NSString *)requestURL;

///-----------------------
#pragma mark - Setter
/// @name Setters
///-----------------------
/*!
 @abstract Set header value for http header key.
 @param value The string value for key.
 @param key The string http key.
 */
- (void)setValue:(nonnull NSString *)value forHTTPHeaderField:(nonnull NSString *)key;

///-----------------------
#pragma mark - Send Request
/// @name Send Request
///-----------------------

// Sync

/*!
 @abstract Send the request synchronously.
 @return On-going BFTask. BFTask _result_ is set with AGRestResponse instance.
 */
- (nullable BFTask *)sendRequest;

/*!
 @abstract Send the request synchronously.
 @param completionBlock     The block to execute when the synchronous request is complete.
                            It should have this signature : ^(AGRestResponse * _Nonnull response).
 */
- (void)sendRequestWithBlock:(nullable AGRestRequestResultBlock)completionBlock;

/*!
 @abstract Send the request synchronously.
 @param target      The target object for the selector.
 @param aSelector   The selector to call on the target when the synchronous request is complete.
 @return
 */
- (void)sendRequestWithTarget:(nonnull id)target selector:(nonnull SEL)aSelector;

// Async

/*!
 @abstract Send the request asynchronously.
 @return On-going BFTask. BFTask _result_ is set with AGRestResponse instance.
 */
- (nullable BFTask *)sendRequestInBackground;

/*!
 @abstract Send the request asynchronously.
 @param completionBlock The block to execute when the synchronous request is complete.
                            It should have this signature : ^(AGRestResponse * _Nonnull response).
 */
- (void)sendRequestInBackgroundWithBlock:(nullable AGRestRequestResultBlock)completionBlock;

/*!
 @abstract Send the request asynchronously.
 @param target      The target object for the selector.
 @param aSelector   The selector to call on the target when the synchronous request is complete.
 */
- (void)sendRequestInBackrgoundWithTarget:(nonnull id)target selector:(nonnull SEL)aSelector;

///-----------------------
#pragma mark - Send Batched Requests
/// @name Send Batched Requests
///-----------------------

/*!
 @abstract Send a batch of AGRestRequest synchronously.
 @param requests    NSArray of AGRestRequest.
 @return On-going BFTask. BFTask _result_ is set with NSArray of AGRestResponse instances.
 */
+ (nullable BFTask *)sendBatchedRequests:(nonnull NSArray *)requests;

/*!
 @abstract Send a batch of AGRestRequest synchronously.
 @param requests        NSArray of AGRestRequest.
 @param completionBlock The block to execute when all the synchronous requests are complete.
                        It should have this signature : ^(AGRestResponse * _Nonnull response).
 */
+ (void)sendBatchedRequests:(nonnull NSArray *)requests withCompletionBlock:(nullable AGRestBatchResponseCompletionBlock)completionBlock;

/*!
 @abstract Send a batch of AGRestRequest synchronously.
 @param requests    NSArray of AGRestRequest.
 @param target      The target object for the selector.
 @param aSelector   The selector to call on the target when the all the synchronous requests are complete.
 */
+ (void)sendBatchedRequests:(nonnull NSArray *)requests withTarget:(nonnull id)target selector:(nonnull SEL)aSelector;

/*!
 @abstract Send a batch of AGRestRequest asynchronously.
 @param requests    NSArray of AGRestRequest.
 @return On-going BFTask. BFTask _result_ is set with NSArray of AGRestResponse instances.
 */
+ (nullable BFTask *)sendBatchedRequestsInBackground:(nonnull NSArray *)requests;

/*!
 @abstract Send a batch of AGRestRequest asynchronously.
 @param requests        NSArray of AGRestRequest.
 @param completionBlock The block to execute when all the synchronous requests are complete.
                        It should have this signature : ^(AGRestResponse * _Nonnull response).
 */
+ (void)sendBatchedRequestsInBackground:(nonnull NSArray *)requests withCompletionBlock:(nullable AGRestBatchResponseCompletionBlock)completionBlock;

/*!
 @abstract Send a batch of AGRestRequest asynchronously.
 @param requests    NSArray of AGRestRequest.
 @param target      The target object for the selector.
 @param aSelector   The selector to call on the target when the all the synchronous requests are complete.
 */
+ (void)sendBatchedRequestsInBackground:(NSArray *)requests withTarget:(nonnull id)target selector:(nonnull SEL)aSelector;

///-----------------------
#pragma mark - Send Request Eventually
/// @name Send Request Eventually
///-----------------------

/*!
 @abstract Send request synchronously.
 @param completionBlock     The block to execute when the request finish execution.<br/>
                            It should have this signature : ^(AGRestResponse * _Nonnull response).
 @discussion    Use this method to send a request even if connectivity is lost.
                In the case where the device's connectivy might be lost then the request is cache locally and will be
                send once the connectivity is back. The request can persist accross multiple app sessions.
                If device is connected then the request is sent immediatly. 
                A typical scenario where you may want to send _eventually_ request is for saving / deleting operations.
 */
- (void)sendRequestEventuallyWithBlock:(nullable AGRestRequestResultBlock)completionBlock;

/*!
 @abstract Send request synchronously.
 @param target      The target object for the selector.
 @param aSelector   The selector to call on the target when the synchronous request is complete.
 @discussion    Use this method to send a request even if connectivity is lost.
                In the case where the device's connectivy might be lost then the request is cache locally and will be
                send once the connectivity is back. The request can persist accross multiple app sessions.
                If device is connected then the request is sent immediatly.
                A typical scenario where you may want to send _eventually_ request is for saving / deleting operations.
 */

- (void)sendRequestEventuallyWithTarget:(nonnull id)target selector:(nonnull SEL)aSelector;

/*!
 @abstract Send request asynchronously.
 @param completionBlock     The block to execute when the request finish execution.<br/>
 It should have this signature : ^(AGRestResponse * _Nonnull response).
 @discussion    Use this method to send a request even if connectivity is lost.
                In the case where the device's connectivy might be lost then the request is cache locally and will be
                send once the connectivity is back. The request can persist accross multiple app sessions.
                If device is connected then the request is sent immediatly.
                A typical scenario where you may want to send _eventually_ request is for saving / deleting operations.
 */

- (void)sendRequestEventuallyInBackgroundWithBlock:(nullable AGRestRequestResultBlock)completionBlock;

/*!
 @abstract Send request asynchronously.
 @param target      The target object for the selector.
 @param aSelector   The selector to call on the target when the synchronous request is complete. 
 @discussion    Use this method to send a request even if connectivity is lost.
                In the case where the device's connectivy might be lost then the request is cache locally and will be
                send once the connectivity is back. The request can persist accross multiple app sessions.
                If device is connected then the request is sent immediatly.
                A typical scenario where you may want to send _eventually_ request is for saving / deleting operations.
 */

- (void)sendRequestEventuallyInBackgroundWithTarget:(nonnull id)target selector:(nonnull SEL)aSelector;

///-----------------------
#pragma mark - Cancellation
/// @name Cancellation
///-----------------------

/*!
 @abstract Cancel the request.
 @return YES if the request has been cancelled successfuly. No otherwise.
 */
- (BOOL)cancel;

@end

NS_ASSUME_NONNULL_END
