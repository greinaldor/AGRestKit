//
//  AGRestManager.h
//  AGRestStack
//
//  Created by Adrien Greiner on 20/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AGRestDataProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class AGRestRequestController;
@class AGRestRequestRunner;
@class AGRestKeyValueCache;

@protocol AGRestCoreManagerDataSource <
AGRestRequestRunnerProvider,
AGRestSessionControllerProvider,
AGRestObjectMapperProvider,
AGRestSessionStoreProvider,
AGRestServerProvider,
AGRestResponseSerializerProvider,
AGRestKeyValueCacheProvider,
AGRestEventuallyQueueProvider,
AGRestFileManagerProvider,
AGRestLoggerProvider>
@end

/*!
 @class AGRestCore
 
 @discussion AGRestCore class manages internal controllers.
 */
@interface AGRestCore : NSObject

@property (nonatomic, weak, readonly) id<AGRestCoreManagerDataSource> dataSource;

@property (nonatomic, strong, readonly) AGRestRequestController       *requestController;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(id<AGRestCoreManagerDataSource>)dataSource baseUrl:(NSString *)baseUrl;
+ (instancetype)coreWithDataSource:(id<AGRestCoreManagerDataSource>)dataSource baseUrl:(NSString *)baseUrl;

- (void)setCachingEnabled:(BOOL)caching;

@end

NS_ASSUME_NONNULL_END
