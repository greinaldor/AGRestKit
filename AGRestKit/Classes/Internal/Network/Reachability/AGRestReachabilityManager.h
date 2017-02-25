//
//  AGRestReachabilityManager.h
//  AGRestStack
//
//  Created by Adrien Greiner on 27/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AGRestConstants.h"

@protocol AGRestReachabilityListener;

/*!
 @class AGRestReachabilityManager
 */
@interface AGRestReachabilityManager : NSObject

@property (nonatomic, assign, readonly) AGRestReachabilityStatus    currentState;

- (instancetype)init NS_UNAVAILABLE;

///-----------------------
#pragma mark - Init
/// @name Init
///-----------------------
/*!
 @abstract Returns an initialized instance configured to monitoring with the given url.
 @param url The url to monitor.
 @return New AGRestReachabilityManager instance.
 */
- (instancetype)initWithUrl:(NSURL *)url NS_DESIGNATED_INITIALIZER;

///-----------------------
#pragma mark - Getter
/// @name Getter
///-----------------------
/*!
 @abstract Return a shared instance of AGRestReachabilityManager.
 */
+ (instancetype)sharedManager;

///-----------------------
#pragma mark - Listening
/// @name Listening
///-----------------------
/*!
 @abstract Add a listener for reachability updates.
 @param listener A listener implementing `AGRestReachabilityListener` protocol.
 */
- (void)addListener:(id<AGRestReachabilityListener>)listener;

/*!
 @abstract Remove a registered listener.
 @param listener A listener implementing `AGRestReachabilityListener` protocol.
 */
- (void)removeListener:(id<AGRestReachabilityListener>)listener;

/*!
 @abstract Remove all registered listeners.
 */
- (void)removeAllListeners;

@end

/*!
 @protocol AGRestReachabilityListener
 @discussion AGRestReachabilityListener defines the methods called when reachibilty status changed.
 @note Class who aims to be updated for reachibility status should implement this protocol.
 */
@protocol AGRestReachabilityListener <NSObject>

@required

/*!
 @abstract Called by a AGRestReachabilityManager when reachability status changed.
 @param manager The calling manager.
 @param status  The new AGRestReachabilityStatus reachability status.
 */
- (void)reachability:(AGRestReachabilityManager *)manager didReachabilityChanged:(AGRestReachabilityStatus)status;

@end
