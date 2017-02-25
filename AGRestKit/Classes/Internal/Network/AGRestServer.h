//
//  AGRestServer.h
//  AGRestStack
//
//  Created by Adrien Greiner on 18/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "AGRestConstants.h"
#import "AGRestServerProtocol.h"

#define AGRestRequestSessionTimeoutInterval     60
#define AGRestRessourceSessionTimeoutInterval   120

NS_ASSUME_NONNULL_BEGIN

/*!
 @class AGRestServer
 
 @discussion The default server implementation used in the AGRestSDK. AGRestServer inherit from AFHTTPSessionManager and then is depedent of AFNetworking 2.0.
 The AGRestServer can execute # count of AGRestRequest operations concurrently and asynchronously in a dedicated thread using
 its own concurrent NSOperationQueue. By default the AGRestServer is configured with JSON request and response serializers.
 
 @note The maximum concurrent operations count is dynamically defined by the current reachability status.
 When reachability status changes the maximum operations count is updated accordingly.
 By default, when reachability status is :
 
 - AGRestReachabilityStatusReachableViaWan = 2 concurrent operations maximum.
 - AGRestReachabilityStatusReachableViaWifi = 4 concurrent operations maximum.
 
 ___Important:___ AGRestServer is not intended to be use for fetching requests, do not use it directly but instead prefer higher AGRestRequest interface
 for server operations.
 AGRestServer is used internally and the returned BFTask from runRequestAsync:withOptions: is processed and may change before returning to AGRestRequest.
 
 __Subclassing Note:__
 You are encouraged to subclass AGRestServer only if you aim to extend running operations with additionnal features or fine-tune server
 configurations. If you need a server instance that can manage its own queues, threads and running operations behaviours or if you don't want to use
 AFNetworking as the underlying server client then prefer creating a new class that conforms to AGRestServerProtocol.
 In any case, change the default AGRestServer instance with your own by calling AGRest method `[AGRest setServerInstance:]` .
 
 */
@interface AGRestServer : AFHTTPSessionManager <AGRestServerProtocol>

- (instancetype)init NS_UNAVAILABLE;

///------------------
/// @name Initialize
///------------------
/*!
 @abstract Initialized the shared instance with given base server url.
 @param url The base server url.
 @return YES if server successfully initialized. NO otherwise.
 */
+ (BOOL)initializeWithBaseUrl:(nonnull NSString *)url;

/*!
 @abstract Return shared instance of AGRestServer
 */
+ (nullable instancetype)sharedServer;

- (void)reset;

///------------------
/// @name Run Request
///------------------
/*!
 @abstract Run a request asynchronously.
 @param request AGRestRequest to execute.
 @param options AGRestRequestRunningOptions for running the request.
 @return Returns a BFTask as result.
 */
- (BFTask *)runRequestAsync:(nonnull AGRestRequest *)request
                withOptions:(AGRestRequestRunningOptions)options;
/*!
 @abstract Run a request asynchronously.
 @param request AGRestRequest to execute.
 @param options AGRestRequestRunningOptions for running the request.
 @param cancellationToken The BFCancellationToken for cancelling the request.
 @return Returns a BFTask as result.
 */
- (BFTask *)runRequestAsync:(nonnull AGRestRequest *)request
                withOptions:(AGRestRequestRunningOptions)options
          cancellationToken:(nullable BFCancellationToken *)cancellationToken;

///------------------
/// @name Configure
///------------------
- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(nonnull NSString *)key;

- (void)setAcceptableContentTypes:(nonnull NSSet *)contentTypes;

- (void)setAcceptableStatusCodes:(nonnull NSIndexSet *)httpStatusCodes;

@end

NS_ASSUME_NONNULL_END

