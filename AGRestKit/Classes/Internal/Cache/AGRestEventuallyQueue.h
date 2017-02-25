//
//  AGRestEventuallyQueue.h
//  AGRestStack
//
//  Created by Adrien Greiner on 27/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AGRestRequestRunning;

@class BFTask;
@class AGRestRequest;

extern NSUInteger       const AGRestEventuallyQueueDefaultMaxAttemps;
extern NSTimeInterval   const AGRestEventuallyQueueDefaultRetryTimeInterval;

/*!
    @class AGRestEventuallyQueue
 */
@interface AGRestEventuallyQueue : NSObject

@property (nonatomic, strong, readonly) id<AGRestRequestRunning>    requestRunner;
@property (nonatomic, assign, readonly) NSUInteger                  requestsCount;
@property (nonatomic, assign, readonly) NSUInteger                  maxAttempsCount;
@property (nonatomic, assign, readonly) NSTimeInterval              retryInterval;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithRequestRunner:(id<AGRestRequestRunning>)runner
                          maxAttempts:(NSUInteger)maxAttemps
                        retryInterval:(NSTimeInterval)retryInterval NS_DESIGNATED_INITIALIZER;

///-----------------------
#pragma mark - Queueing
/// @name Queueing
///-----------------------

- (BFTask *)enqueueRequestInBackground:(AGRestRequest *)request;

///-----------------------
#pragma mark - Controlling Queue
/// @name Controlling queue
///-----------------------

- (void)start NS_REQUIRES_SUPER;
- (void)resume NS_REQUIRES_SUPER;
- (void)pause NS_REQUIRES_SUPER;

- (void)removeAllRequests;

@end
