//
//  AGRestManager.m
//  AGRestStack
//
//  Created by Adrien Greiner on 20/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestManager.h"

#import "AGRestCore.h"
#import "AGRestServer.h"
#import "AGRestRequestRunner.h"
#import "AGRestRequestCache.h"
#import "AGRestObjectMapper.h"
#import "AGRestSessionController.h"
#import "AGRestSessionStore.h"
#import "AGRestFileManager.h"
#import "AGRestResponseSerializer.h"
#import "AGRestKeyValueCache.h"
#import "AGRestLogger.h"

@interface AGRestManager() <AGRestCoreManagerDataSource> {
    dispatch_queue_t _eventuallyQueueAccessQueue;
    dispatch_queue_t _loggerAccessQueue;
    dispatch_queue_t _fileManagerAccessQueue;
    dispatch_queue_t _requestRunnerAccessQueue;
    dispatch_queue_t _requestServerAccessQueue;
    dispatch_queue_t _keyValueCacheAccessQueue;
    dispatch_queue_t _coreAccessQueue;
    dispatch_queue_t _sessionControllerAccessQueue;
    dispatch_queue_t _sessionStoreAccessQueue;
    dispatch_queue_t _objectMapperAccessQueue;
    dispatch_queue_t _responseSerializerAccessQueue;
    dispatch_queue_t _preloadQueue;
}

@end

@implementation AGRestManager

@synthesize core = _core;
@synthesize requestServer = _requestServer;
@synthesize objectMapper = _objectMapper;
@synthesize sessionController = _sessionController;
@synthesize sessionStore = _sessionStore;
@synthesize baseUrl = _baseUrl;
@synthesize responseSerializer = _responseSerializer;
@synthesize requestRunner = _requestRunner;
@synthesize keyValueCache = _keyValueCache;
@synthesize eventuallyQueue = _eventuallyQueue;
@synthesize fileManager = _fileManager;
@synthesize logger = _logger;

- (void)dealloc {
    [self reset];
}

- (instancetype)initWithBaseUrl:(NSString *)baseUrl {

    self = [super init];
    if (!self) return nil;
    
    _coreAccessQueue                = dispatch_queue_create("com.AGRest.core.coreAccessQueue",              DISPATCH_QUEUE_SERIAL);
    _requestRunnerAccessQueue       = dispatch_queue_create("com.AGRest.core.requesrRunnerAccessQueue",     DISPATCH_QUEUE_SERIAL);
    _requestServerAccessQueue       = dispatch_queue_create("com.AGRest.core.requestServerAccessQueue",     DISPATCH_QUEUE_SERIAL);
    _eventuallyQueueAccessQueue     = dispatch_queue_create("com.AGRest.core.eventuallyQueueAccessQueue",   DISPATCH_QUEUE_SERIAL);
    _keyValueCacheAccessQueue       = dispatch_queue_create("com.AGRest.core.keyValueCacheAccessQueue",     DISPATCH_QUEUE_SERIAL);
    _sessionControllerAccessQueue   = dispatch_queue_create("com.AGRest.core.sessionControllerAccessQueue", DISPATCH_QUEUE_SERIAL);
    _sessionStoreAccessQueue        = dispatch_queue_create("com.AGRest.core.sessionStoreAccessQueue",      DISPATCH_QUEUE_SERIAL);
    _objectMapperAccessQueue        = dispatch_queue_create("com.AGRest.core.objectMapperAccessQueue",      DISPATCH_QUEUE_SERIAL);
    _responseSerializerAccessQueue  = dispatch_queue_create("com.AGRest.core.responseSerializerAccessQueue", DISPATCH_QUEUE_SERIAL);
    _fileManagerAccessQueue         = dispatch_queue_create("com.AGRest.core.fileManagerAcceessQueue",      DISPATCH_QUEUE_SERIAL);
    _preloadQueue                   = dispatch_queue_create("com.AGRest.core.preloadAccessQueue",           DISPATCH_QUEUE_SERIAL);
    _loggerAccessQueue              = dispatch_queue_create("com.AGRest.core.loggerAccessQueue",            DISPATCH_QUEUE_SERIAL);
    
    self.baseUrl = baseUrl;
    
    return self;
}

- (void)preload {
    
    if ([AGRest isLoggingEnabled]) {
        AGRestLogInfo(@"<AGRest> Initialize rest with base url : %@", _baseUrl);
    }
    dispatch_sync(_preloadQueue, ^{
        // Load the file manager
        [self fileManager];
        // Load KeyValue Cache
        [self keyValueCache];
        // Load Server
        [self requestServer];
        // Load request runner
        [self requestRunner];
        // Load core
        [self core];
        // Load the eventually queue
        [self eventuallyQueue];
    });
    if ([AGRest isLoggingEnabled]) {
        AGRestLogInfo(@"<AGRest> Modules loaded.");
    }
}

- (void)reset {
    _fileManager = nil;
    _keyValueCache = nil;
    _requestRunner = nil;
    _eventuallyQueue = nil;
    [_requestServer reset];
    _requestRunner = nil;
    _core = nil;
}

#pragma mark - Core
#pragma mark -

- (AGRestCore *)core {
    __block AGRestCore *core = nil;
    dispatch_sync(_coreAccessQueue, ^{
        if (!_core) {
            _core = [AGRestCore coreWithDataSource:self baseUrl:self.baseUrl];
        }
        core = _core;
    });
    return core;
}

- (void)setCore:(AGRestCore *)core {
    dispatch_sync(_coreAccessQueue, ^{
        _core = core;
    });
}

#pragma mark - BaseUrl
#pragma mark -

- (void)setBaseUrl:(NSString *)baseUrl {
    dispatch_sync(_coreAccessQueue, ^{
        _baseUrl = baseUrl;
    });
}

- (NSString *)baseUrl {
    return _baseUrl;
}

#pragma mark - Object Mapper
#pragma mark -

- (id<AGRestObjectMapperProtocol>)objectMapper {
    __block id<AGRestObjectMapperProtocol> objecMapper = nil;
    dispatch_sync(_objectMapperAccessQueue, ^{
        if (!_objectMapper) {
            _objectMapper = [[AGRestObjectMapper alloc] init];
        }
        objecMapper = _objectMapper;
    });
    return objecMapper;
}

- (void)setObjectMapper:(id<AGRestObjectMapperProtocol>)objectMapper {
    dispatch_sync(_objectMapperAccessQueue, ^{
        _objectMapper = objectMapper;
    });
}

#pragma mark - Session Controller
#pragma mark -

- (id<AGRestSessionProtocol>)sessionController {
    __block id<AGRestSessionProtocol> sessionController = nil;
    dispatch_sync(_sessionControllerAccessQueue, ^{
        if (!_sessionController) {
            _sessionController = [[AGRestSessionController alloc] initWithDataSource:self];
        }
        sessionController = _sessionController;
    });
    return sessionController;
}

- (void)setSessionController:(id<AGRestSessionProtocol>)sessionController {
    dispatch_async(_sessionControllerAccessQueue, ^{
        _sessionController = sessionController;
        if (![_sessionController dataSource]) {
            [_sessionController setDataSource:self];
        }
    });
}

#pragma mark - Session Store
#pragma mark -

- (id<AGRestSessionStoreProtocol>)sessionStore {
    __block id<AGRestSessionStoreProtocol> sessionStore = nil;
    dispatch_sync(_sessionStoreAccessQueue, ^{
        if (!_sessionStore) {
            _sessionStore = [[AGRestSessionStore alloc] init];
        }
        sessionStore = _sessionStore;
    });
    return sessionStore;
}

- (void)setSessionStore:(id<AGRestSessionStoreProtocol>)sessionStore {
    dispatch_sync(_sessionStoreAccessQueue, ^{
        _sessionStore = sessionStore;
    });
}

#pragma mark - KeyValueCache
#pragma mark -

- (id<AGRestKeyValueCaching>)keyValueCache {
    __block id<AGRestKeyValueCaching> keyValueCache = nil;
    dispatch_sync(_keyValueCacheAccessQueue, ^{
        if (!_keyValueCache) {
            _keyValueCache = [[AGRestKeyValueCache alloc] initWithDataSource:self];
        }
        keyValueCache = _keyValueCache;
    });
    return keyValueCache;
}

- (void)setKeyValueCache:(id<AGRestKeyValueCaching>)keyValueCache {
    dispatch_sync(_keyValueCacheAccessQueue, ^{
        _keyValueCache = keyValueCache;
    });
}


#pragma mark - Request Server
#pragma mark -

- (id<AGRestServerProtocol>)requestServer {
    __block id<AGRestServerProtocol> requestServer = nil;
    dispatch_sync(_requestServerAccessQueue, ^{
        if (!_requestServer) {
            if ([AGRestServer initializeWithBaseUrl:_baseUrl]) {
                _requestServer = [AGRestServer sharedServer];
            } else {
                [NSException raise:NSInternalInconsistencyException format:@"Server instance failed to initialize!"];
            }
        }
        requestServer = _requestServer;
    });
    return requestServer;
}

- (void)setRequestServer:(id<AGRestServerProtocol>)requestServer {
    if (!requestServer) {
        [NSException raise:NSInternalInconsistencyException format:@"`serverInstance` can't be nil."];
    }
    dispatch_sync(_requestServerAccessQueue, ^{
        _requestServer = requestServer;
    });
}

#pragma mark - Request Runner
#pragma mark -

- (id<AGRestRequestRunning>)requestRunner {
    __block id<AGRestRequestRunning> requestRunner = nil;
    dispatch_sync(_requestRunnerAccessQueue, ^{
        if (!_requestRunner) {
            _requestRunner = [[AGRestRequestRunner alloc] initWithDataSource:self];
        }
        requestRunner = _requestRunner;
    });
    return requestRunner;
}

- (void)setRequestRunner:(id<AGRestRequestRunning>)requestRunner {
    dispatch_sync(_requestRunnerAccessQueue, ^{
        if (!requestRunner) {
            [NSException raise:NSInternalInconsistencyException format:@"`requestRunner` can't be nil."];
        }
        _requestRunner = requestRunner;
    });
}

#pragma mark - Response Serializer
#pragma mark -

- (id<AGRestResponseSerializerProtocol>)responseSerializer {
    __block id<AGRestResponseSerializerProtocol> responseSerializer = nil;
    dispatch_sync(_responseSerializerAccessQueue, ^{
        if (!_responseSerializer) {
            _responseSerializer = [[AGRestResponseSerializer alloc] initWithDataSource:self];
        }
        responseSerializer = _responseSerializer;
    });
    return responseSerializer;
}

- (void)setResponseSerializer:(id<AGRestResponseSerializerProtocol>)responseSerializer {
    dispatch_sync(_responseSerializerAccessQueue, ^{
        if (!responseSerializer) {
            [NSException raise:NSInternalInconsistencyException format:@"`responseSerializer` can't be nil."];
        }
        _responseSerializer = responseSerializer;
    });
}

#pragma mark - Eventually Queue
#pragma mark -

- (AGRestEventuallyQueue *)eventuallyQueue {
    __block AGRestEventuallyQueue *eventuallyQueue = nil;
    dispatch_sync(_eventuallyQueueAccessQueue, ^{
        if (!_eventuallyQueue) {
            AGRestRequestCache *requestCache = [AGRestRequestCache cacheWithRequestRunner:self.requestRunner
                                                                           cacheDirectory:self.fileManager.restCacheDirectory
                                                                             maxCacheSize:(NSUInteger)AGRestRequestsCacheDefaultDiskCacheSize];
            
            _eventuallyQueue = requestCache;
        }
        eventuallyQueue = _eventuallyQueue;
    });
    return eventuallyQueue;
}

#pragma mark - File Manager
#pragma mark -

- (AGRestFileManager *)fileManager {
    __block AGRestFileManager * fileManager = nil;
    dispatch_sync(_fileManagerAccessQueue, ^{
        if (!_fileManager) {
            _fileManager = [[AGRestFileManager alloc] initWithRestDirectory:[[self class] restRootDirectory]];
        }
        fileManager = _fileManager;
    });
    return fileManager;
}

#pragma mark - Logger
#pragma mark -

- (id<AGRestLogging>)logger {
    __block id<AGRestLogging> logger = nil;
    dispatch_sync(_loggerAccessQueue, ^{
        if (!_logger) {
            _logger = [AGRestLogger sharedLogger];
        }
        logger = _logger;
    });
    return logger;
}

- (void)setLogger:(id<AGRestLogging>)logger {
    dispatch_sync(_loggerAccessQueue, ^{
        _logger = logger;
    });
}

#pragma mark - Private()
#pragma mark -

+ (NSString *)restRootDirectory {
    return [[AGRestFileManager applicationSupport] stringByAppendingPathComponent:@"AGRest"];
}

@end
