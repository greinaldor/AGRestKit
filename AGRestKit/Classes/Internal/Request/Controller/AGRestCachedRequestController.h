//
//  AGRestCachedRequestController.h
//  AGRestStack
//
//  Created by Adrien Greiner on 24/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AGRestRequestController.h"

@protocol AGRestKeyValueCacheProvider;

typedef id<AGRestRequestRunnerProvider,AGRestResponseSerializerProvider,AGRestKeyValueCacheProvider> AGRestCachedRequestControllerDataSource;

NS_ASSUME_NONNULL_BEGIN

/*!
 @class AGRestCachedRequestController
 
 
 */
@interface AGRestCachedRequestController : AGRestRequestController

- (instancetype)initWithDataSource:(nonnull AGRestCachedRequestControllerDataSource)dataSource;

+ (instancetype)controllerWithDataSource:(nonnull AGRestCachedRequestControllerDataSource)dataSource;

- (nonnull BFTask *)runRequestAsync:(nonnull AGRestRequest *)request withCancellationToken:(nullable BFCancellationToken *)cancellationToken;

@end

NS_ASSUME_NONNULL_END
