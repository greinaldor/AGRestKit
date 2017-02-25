//
//  AGRest.m
//  AGRestStack
//
//  Created by Adrien Greiner on 23/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AGRest.h"
#import "AGRestManager.h"
#import "AGRestCore.h"
#import "AGRestObjectMapperProtocol.h"
#import "AGRestSessionProtocol.h"
#import "AGRestLogging.h"
#import "AGRestLogger.h"

@interface AGRest()

+ (BOOL)didAGRestInitialized;

+ (id)performInternalSelector:(SEL)selector withObject:(id)object;

@end

@implementation AGRest

static AGRestManager * _restManager = nil;
static BOOL            _cachingEnabled;
static BOOL            _loggingEnabled;
static BOOL            _objectMappingEnabled;

+ (void)initialize {
    if (self == [AGRest class]) {
        // Global iniatialization here
        
        // Caching enabled by default.
        _cachingEnabled = YES;
        // Logging enabled by default.
        _loggingEnabled = YES;
        // Object mapping enabled by default
        _objectMappingEnabled = YES;
    }
}

+ (void)initializeRestWithBaseUrl:(nonnull NSString *)baseUrl {
    
    if (!baseUrl || ![baseUrl isKindOfClass:[NSString class]] || !baseUrl.length) {
        [NSException raise:NSInternalInconsistencyException format:@"`baseUrl` should not be nil"];
    }
    
    if (![self didAGRestInitialized])
    {        
        //-----------------------
        // Instantiate the current shared RestManager
        //-----------------------
        _restManager = [[AGRestManager alloc] initWithBaseUrl:baseUrl];
        
        //-----------------------
        // Configure global settings for AGRest here
        //-----------------------
        [_restManager.core setCachingEnabled:_cachingEnabled];
        
        //-----------------------
        // Load primary controllers
        //-----------------------
        [_restManager preload];
    } else {
        AGRestLogWarn(@"<AGRest> Already initialized with baseUrl : %@", _restManager.baseUrl);
    }
}

+ (nonnull NSString *)getRestBaseUrl {
    return [AGRest performInternalSelector:@selector(_getRestBaseUrl) withObject:nil];
}

#pragma mark - Customize
#pragma mark -

+ (void)setSessionController:(nonnull id<AGRestSessionProtocol>)sessionController {
    [AGRest performInternalSelector:@selector(_setSessionController:) withObject:sessionController];
}

+ (void)setObjectMapper:(nonnull id<AGRestObjectMapperProtocol>)objectMapper {
    [AGRest performInternalSelector:@selector(_setObjectMapper:) withObject:objectMapper];
}

+ (void)setServerInstance:(nonnull id<AGRestServerProtocol>)server {
    [AGRest performInternalSelector:@selector(_setServerInstance:) withObject:server];
}

+ (void)setResponseSerializer:(nonnull id<AGRestResponseSerializerProtocol>)responseSerializer {
    [AGRest performInternalSelector:@selector(_setResponseSerializer:) withObject:responseSerializer];
}

+ (void)setLogger:(nonnull id<AGRestLogging>)logger {
    [AGRest performInternalSelector:@selector(_setLogger:) withObject:logger];
}

+ (id<AGRestSessionProtocol>)sessionController {
    return [AGRest performInternalSelector:@selector(_sessionController) withObject:nil];
}

+ (id<AGRestServerProtocol>)serverInstance {
    return [AGRest performInternalSelector:@selector(_serverInstance) withObject:nil];
}

+ (id<AGRestResponseSerializerProtocol>)responseSerializer {
    return [AGRest performInternalSelector:@selector(_responseSerializer) withObject:nil];
}

+ (id<AGRestLogging>)logger {
    return [AGRest performInternalSelector:@selector(logger) withObject:nil];
}

#pragma mark - Configure
#pragma mark -

+ (void)setCachingEnabled:(BOOL)enabled {
    _cachingEnabled = enabled;
    if ([[self class] didAGRestInitialized]) {
        [_restManager core];
    }
}

+ (BOOL)isCachingEnabled {
    return _cachingEnabled;
}

+ (void)setLoggingEnable:(BOOL)enabled level:(AGRestLoggingLevel)level {
    _loggingEnabled = enabled;
    if ([self didAGRestInitialized]) {
        [_restManager.logger setLogLevel:(!enabled)?AGRestLoggingLevelNone:level];
    }
}

+ (BOOL)isLoggingEnabled {
    return _loggingEnabled;
}

+ (void)setObjectMappingEnabled:(BOOL)enabled {
    _objectMappingEnabled = enabled;
}

+ (BOOL)isObjectMappingEnabled {
    return _objectMappingEnabled;
}

#pragma mark - Register Subclass
#pragma mark -

+ (BOOL)registerSubclass:(nonnull Class)newModelClass {
    return [[AGRest performInternalSelector:@selector(_registerSubclass:) withObject:newModelClass] boolValue];
}

#pragma mark - Private()
#pragma mark -

+ (AGRestManager *)_currentManager {
    return _restManager;
}

+ (void)_clearCurrentManager {
    _restManager = nil;
}

#pragma mark - Internal
#pragma mark -

+ (BOOL)didAGRestInitialized {
    return (_restManager && _restManager.baseUrl);
}

+ (id)performInternalSelector:(SEL)selector withObject:(id)object {
    if ([[self class] didAGRestInitialized]) {
        if ([AGRest respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            return [[AGRest class] performSelector:selector withObject:object];
#pragma clang diagnostic pop
        }
    } else {
        [NSException raise:NSInternalInconsistencyException format:@"'AGRest' should be initialized first calling +initializeRestWithBaseUrl"];
    }
    return nil;
}

+ (NSString *)_getRestBaseUrl {
    return _restManager.baseUrl;
}

+ (void)_setSessionController:(id<AGRestSessionProtocol>)sessionController {
    [_restManager setSessionController:sessionController];
}

+ (void)_setObjectMapper:(id<AGRestObjectMapperProtocol>)objectMapper {
    [_restManager setObjectMapper:objectMapper];
}

+ (void)_setServerInstance:(id<AGRestServerProtocol>)server {
    [_restManager setRequestServer:server];
}

+ (void)_setResponseSerializer:(id<AGRestResponseSerializerProtocol>)responseSerializer {
    [_restManager setResponseSerializer:responseSerializer];
}

+ (void)_setLogger:(id<AGRestLogging>)logger {
    [_restManager setLogger:logger];
}

+ (id<AGRestSessionProtocol>)_sessionController {
    return [_restManager sessionController];
}

+ (id<AGRestServerProtocol>)_serverInstance {
    return [_restManager requestServer];
}

+ (id<AGRestResponseSerializerProtocol>)_responseSerializer {
    return [_restManager responseSerializer];
}

+ (id<AGRestLogging>)_logger {
    return [_restManager logger];
}

+ (NSNumber *)_registerSubclass:(nonnull Class)newModelClass {
    BOOL isClassRegistered = [[_restManager objectMapper] registerSubclass:newModelClass];
    return @(isClassRegistered);
}

@end
