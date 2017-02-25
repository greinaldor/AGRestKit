//
//  AGRestRequestController.h
//  AGRestStack
//
//  Created by Adrien Greiner on 20/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AGRestRequest;
@class BFTask;
@class BFCancellationToken;

@protocol AGRestRequestRunnerProvider;
@protocol AGRestResponseSerializerProvider;
@protocol AGRestEventuallyQueueProvider;

typedef id<AGRestRequestRunnerProvider,AGRestResponseSerializerProvider,AGRestEventuallyQueueProvider> AGRestRequestControllerDataSource;

NS_ASSUME_NONNULL_BEGIN

/*!
 @class AGRestRequestController
 
 @discussion 
 */
@interface AGRestRequestController : NSObject

///-----------------------
/// @name Init
///-----------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(nonnull AGRestRequestControllerDataSource)dataSource NS_DESIGNATED_INITIALIZER;

+ (instancetype)controllerWithDataSource:(nonnull AGRestRequestControllerDataSource)dataSource;

///-----------------------
/// @name Fetch
///-----------------------

- (nonnull BFTask *)runRequestAsync:(nonnull AGRestRequest *)request
              withCancellationToken:(nullable BFCancellationToken *)cancellationToken;


@end

NS_ASSUME_NONNULL_END
