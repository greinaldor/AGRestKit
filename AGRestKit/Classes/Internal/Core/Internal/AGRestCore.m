//
//  AGRestManager.m
//  AGRestStack
//
//  Created by Adrien Greiner on 20/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestCore.h"

#import "AGRestManager.h"
#import "AGRestCachedRequestController.h"
#import "AGRestReachabilityManager.h"
#import "AGRestServerProtocol.h"

@interface AGRestCore() {
    dispatch_queue_t _controllerAccessQueue;
}

@property (nonatomic, weak) AGRestReachabilityManager *reachabilityManager;
@property (assign) BOOL  cachingEnabled;

@end

@implementation AGRestCore

@synthesize requestController   = _requestController;
@synthesize dataSource = _dataSource;
@synthesize cachingEnabled = _cachingEnabled;

#pragma mark - Init
#pragma mark -

- (instancetype)initWithDataSource:(id<AGRestCoreManagerDataSource>)dataSource baseUrl:(NSString *)baseUrl {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;
    _controllerAccessQueue = dispatch_queue_create("com.AGRest.core.controllerAccessQueue", DISPATCH_QUEUE_SERIAL);
    
    // Create a reachability manager for current domain
    _reachabilityManager = [AGRestReachabilityManager sharedManager];
    
    return self;
}

+ (instancetype)coreWithDataSource:(id<AGRestCoreManagerDataSource>)dataSource baseUrl:(NSString *)baseUrl {
    return [[AGRestCore alloc] initWithDataSource:dataSource baseUrl:baseUrl];
}

#pragma mark - Caching
#pragma mark -

- (void)setCachingEnabled:(BOOL)caching {
    if (self.cachingEnabled != caching) {
        dispatch_sync(_controllerAccessQueue, ^{
            _requestController = nil;
        });
    }
    _cachingEnabled = caching;
}

- (BOOL)cachingEnabled {
    return _cachingEnabled;
}

#pragma mark - Request Controller
#pragma mark -

- (AGRestRequestController *)requestController {
    __block AGRestRequestController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_requestController) {
            if (_cachingEnabled) {
                _requestController = [AGRestCachedRequestController controllerWithDataSource:self.dataSource];
            } else {
                _requestController = [AGRestRequestController controllerWithDataSource:self.dataSource];
            }
        }
        controller = _requestController;
    });
    return controller;
}

- (void)setRequestController:(AGRestRequestController *)requestController {
    dispatch_async(_controllerAccessQueue, ^{
        _requestController = requestController;
    });
}

@end
