//
//  AGRestDataProvider.h
//  AGRestStack
//
//  Created by Adrien Greiner on 20/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#ifndef AG_REST_DATA_PROVIDER
#define AG_REST_DATA_PROVIDER

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Protocol RequestRunnerProvider
#pragma mark -

@protocol AGRestRequestRunning;

@protocol AGRestRequestRunnerProvider <NSObject>

@property (nonatomic, strong, readonly) id<AGRestRequestRunning> requestRunner;

@end

#pragma mark - Protocol SessionControllerProvider
#pragma mark -

@protocol AGRestSessionProtocol;

@protocol AGRestSessionControllerProvider <NSObject>

@property (nonatomic, strong, readonly) id<AGRestSessionProtocol> sessionController;

@end

#pragma mark - Protocol ObjectMapperProvider
#pragma mark -

@protocol AGRestObjectMapperProtocol;

@protocol AGRestObjectMapperProvider <NSObject>

@property (nonatomic, strong, readonly) id<AGRestObjectMapperProtocol> objectMapper;

@end

#pragma mark - Protocol KeychainStoreProvider
#pragma mark -

@protocol AGRestSessionStoreProtocol;

@protocol AGRestSessionStoreProvider <NSObject>

@property (nonatomic, strong, readonly) id<AGRestSessionStoreProtocol> sessionStore;

@end

#pragma mark - Protocol ServerProvider
#pragma mark -

@protocol AGRestServerProtocol;

@protocol AGRestServerProvider <NSObject>

@property (nonatomic, weak, readonly) id<AGRestServerProtocol> requestServer;

@end

#pragma mark - Protocol ResponseProvider

@protocol AGRestResponseSerializerProtocol;

@protocol AGRestResponseSerializerProvider <NSObject>

@property (nonatomic, strong, readonly) id<AGRestResponseSerializerProtocol> responseSerializer;

@end

#pragma mark - Protocol KeyValueCache

@protocol AGRestKeyValueCaching;

@protocol AGRestKeyValueCacheProvider <NSObject>

@property (nonatomic, strong, readonly) id<AGRestKeyValueCaching> keyValueCache;

@end

#pragma mark - Protocol EventuallyQueueProvider

@class AGRestEventuallyQueue;

@protocol AGRestEventuallyQueueProvider <NSObject>

@property (nonatomic, strong, readonly) AGRestEventuallyQueue * eventuallyQueue;

@end

#pragma mark - File Manager Provider

@class AGRestFileManager;

@protocol AGRestFileManagerProvider <NSObject>

@property (nonatomic, strong, readonly) AGRestFileManager * fileManager;

@end

#pragma mark - Logger

@protocol AGRestLogging;

@protocol  AGRestLoggerProvider <NSObject>

@property (nonatomic, weak, readonly) id<AGRestLogging> logger;

@end

#endif

NS_ASSUME_NONNULL_END
