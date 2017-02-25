//
//  AGRest.h
//  AGRestStack
//
//  Created by Adrien Greiner on 21/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestConstants.h"

// Imports Public Modules
#import "AGRestRequest.h"
#import "AGRestResponse.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AGRestSessionProtocol;
@protocol AGRestObjectMapperProtocol;
@protocol AGRestServerProtocol;
@protocol AGRestResponseSerializerProtocol;
@protocol AGRestLogging;

/*!
 @class AGRestManager
 
 @abstract The primary interface for integrating AGRestKit.
 
 @discussion Use the AGRestManager class to setup and configure AGRestKit in your project.
 You must initialize the AGRestKit before using any classes or provided features.

    [AGRest initializeRestWithBaseUrl:<<API URL>>];
 
 */
@interface AGRestManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

///-----------------------
#pragma mark - Initialize
/// @name Initialize
///-----------------------
/*!
    @abstract Initialize AGRest with a base url.
    @warning This method should be called prior using AGRest.
    @param baseUrl The base url used to fetch request and monitor reachability.
 */
+ (void)initializeRestWithBaseUrl:(nonnull NSString *)baseUrl;

///-----------------------
#pragma mark - Setter
/// @name Setter
///-----------------------
/*!
    @abstract Set a custom session controller which conforns to `AGRestSessionProtocol` protocol.
    @param sessionController    The new session controller.
 */
+ (void)setSessionController:(nonnull id<AGRestSessionProtocol>)sessionController;

/*!
    @abstract Set a custom object mapper which conforms to `AGRestObjectMapperProtocol` protocol;
    @param objectMapper The new objectMapper.
 */
+ (void)setObjectMapper:(nonnull id<AGRestObjectMapperProtocol>)objectMapper;

/*!
    @abstract Set a custom server instance which conforms to `AGRestServerProtocol` protocol.
    @param server   The new server instance.
 */
+ (void)setServerInstance:(nonnull id<AGRestServerProtocol>)server;

/*!
    @abstract Set a custom response serializer which conforms to `AGRestResponseSerializerProtocol` protocol.
    @param responseSerializer   The new response serializer.
 */
+ (void)setResponseSerializer:(nonnull id<AGRestResponseSerializerProtocol>)responseSerializer;

/*!
 @abstract Set a custom logger which conforms to `AGRestLogging` protocol.
 @param logger   The new logger instance.
 */
+ (void)setLogger:(id<AGRestLogging>)logger;

/*!
 @abstract Enable caching let AGRest's controllers cache requests, responses, files locally.
 Caching is enabled by default.
 @param enabled Bool flag.
 */
+ (void)setCachingEnabled:(BOOL)enabled;

/*!
 @abstract Enable logging will let AGRest's controllers log events, error, crash in the debugger.
 Logging is enabled by default.
 @note Logging is \b disabled in \b production environement.
 @param enabled Bool flag.
 @param level Restrict logging to fixed levels.
 */
+ (void)setLoggingEnable:(BOOL)enabled
                   level:(AGRestLoggingLevel)level;

/*!
 @abstract Enable mapping of response into registered classes using the object mapper.
 @param enabled  Bool flag.
 */
+ (void)setObjectMappingEnabled:(BOOL)enabled;

///-----------------------
#pragma mark - Getter
/// @name Getter
///-----------------------
/*!
 @return The base url.
 */
+ (NSString *)getRestBaseUrl;

/*!
    @return The session controller in use.
 */
+ (id<AGRestSessionProtocol>)sessionController;

/*!
    @return The serverInstance in user.
 */
+ (id<AGRestServerProtocol>)serverInstance;

/*!
    @return The response serializer in use.
 */
+ (id<AGRestResponseSerializerProtocol>)responseSerializer;

/*!
    @return The logger in use.
 */
+ (id<AGRestLogging>)logger;

/*!
    @return Whether caching is enabled.
 */
+ (BOOL)isCachingEnabled;

/*!
    @return Whether logging is enabled.
 */
+ (BOOL)isLoggingEnabled;

/*!
    @return Whether object mapping is enabled.
 */
+ (BOOL)isObjectMappingEnabled;

///-----------------------
#pragma mark - Register Subclass
/// @name Register Subclass
///-----------------------
/*!
    @abstract Register subclass for mapping using the current objectMapper instance.
    @discussion The registered class should conforms to AGRestObjectMapping protocol.
    @param newModelClass Class to register.
 */
+ (BOOL)registerSubclass:(nonnull Class)newModelClass;

@end

NS_ASSUME_NONNULL_END
