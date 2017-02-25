//
//  AGRestManager.h
//  AGRestStack
//
//  Created by Adrien Greiner on 20/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AGRestDataProvider.h"

@class AGRestCore;

@protocol AGRestResponseSerializerProtocol;
@protocol AGRestSessionProtocol;
@protocol AGRestServerProtocol;
@protocol AGRestObjectMapperProtocol;
@protocol AGRestSessionStoreProtocol;
@protocol AGRestResponseSerializerProtocol;
@protocol AGRestLogging;

/*!
 @class AGRestManager
 
 @discussion AGRestManager class owns the core modules and manages their access to the rest of the framework. 
 */
@interface AGRestManager : NSObject <
AGRestRequestRunnerProvider,
AGRestSessionControllerProvider,
AGRestObjectMapperProvider,
AGRestSessionStoreProvider,
AGRestServerProvider,
AGRestResponseSerializerProvider,
AGRestKeyValueCacheProvider,
AGRestLoggerProvider>

@property (nonatomic, copy, readonly) NSString                      *baseUrl;

@property (nonatomic, strong, readonly) AGRestCore                  *core;
@property (nonatomic, strong, readonly) AGRestFileManager           *fileManager;

@property (nonatomic, strong) id<AGRestRestSessionProtocol>             sessionController;
@property (nonatomic, strong) id<AGRestRestSessionStoreProtocol>        sessionStore;
@property (nonatomic, strong) id<AGRestRestObjectMapperProtocol>        objectMapper;
@property (nonatomic, strong) id<AGRestRestServerProtocol>              requestServer;
@property (nonatomic, strong) id<AGRestRestRequestRunning>              requestRunner;
@property (nonatomic, strong) id<AGRestRestResponseSerializerProtocol>  responseSerializer;
@property (nonatomic, strong) id<AGRestRestKeyValueCaching>             keyValueCache;
@property (nonatomic, strong) id<AGRestRestLogging>                     logger;

///-----------------------
/// @name Init
///-----------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithBaseUrl:(NSString *)baseUrl;

- (void)preload;
- (void)reset;

@end
