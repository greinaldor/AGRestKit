//
//  AGRestReachabilityManager.m
//  AGRestStack
//
//  Created by Adrien Greiner on 27/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestReachabilityManager.h"

#import <SystemConfiguration/SystemConfiguration.h>

#import"AGRestManager.h"

@interface AGRestReachabilityManager() {
    dispatch_queue_t _synchronizationQueue;
    NSMutableArray *_listenersArray;
    
    SCNetworkReachabilityRef _networkReachability;
}

@property (nonatomic, assign, readwrite) SCNetworkReachabilityFlags flags;

@end

static void _reachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
    AGRestReachabilityManager *reachability = (__bridge AGRestReachabilityManager *)info;
    reachability.flags = flags;
}

@implementation AGRestReachabilityManager

@synthesize flags = _flags;

#pragma mark - Init
#pragma mark -

- (instancetype)initWithUrl:(NSURL *)url {
    self = [super init];
    if (!self) return nil;
    
    _synchronizationQueue = dispatch_queue_create("com.AGRest.reachability", DISPATCH_QUEUE_CONCURRENT);
    _listenersArray = [NSMutableArray array];
    
    [self _startMonitoringReachabilityWithURL:url];
    
    return self;
}

/*
 Return a singleton of `AGRestReachabilityManager`.
 */
+ (instancetype)sharedManager {
    static AGRestReachabilityManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *baseUrl = [NSString stringWithString:[AGRest getRestBaseUrl]];
        NSURL *url = [NSURL URLWithString:baseUrl];
        manager = [[AGRestReachabilityManager alloc] initWithUrl:url];
    });
    return manager;
}

- (void)dealloc {
    if (_networkReachability != NULL) {
        SCNetworkReachabilitySetCallback(_networkReachability, NULL, NULL);
        SCNetworkReachabilitySetDispatchQueue(_networkReachability, NULL);
        CFRelease(_networkReachability);
        _networkReachability = NULL;
    }
}

#pragma mark - Listening
#pragma mark -

- (void)addListener:(id<AGRestReachabilityListener>)listener {
    __weak typeof(listener) weakListener = listener;
    dispatch_barrier_sync(_synchronizationQueue, ^{
        [_listenersArray addObject:weakListener];
    });
}

- (void)removeListener:(id<AGRestReachabilityListener>)listener {
    dispatch_barrier_sync(_synchronizationQueue, ^{
        [_listenersArray filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return (evaluatedObject == nil || evaluatedObject == listener);
        }]];
    });
}

- (void)removeAllListeners {
    dispatch_barrier_sync(_synchronizationQueue, ^{
        [_listenersArray removeAllObjects];
    });
}

- (void)_notifyAllListeners {
    weakify(self);
    dispatch_async(_synchronizationQueue, ^{
        strongify(weakSelf);
        AGRestReachabilityStatus state = [[strongSelf class] _reachabilityStateForFlags:_flags];
        for (id<AGRestReachabilityListener> value in _listenersArray) {
            [value reachability:strongSelf didReachabilityChanged:state];
        }
        
        dispatch_barrier_async(_synchronizationQueue, ^{
            [_listenersArray filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELf != nil"]];
        });
    });
}

#pragma mark - Accessors
#pragma mark -

- (void)setFlags:(SCNetworkReachabilityFlags)flags {
    dispatch_barrier_async(_synchronizationQueue, ^{
        if (_flags != flags)
        {
            _flags = flags;
            [self _notifyAllListeners];
        }
    });
}

- (SCNetworkReachabilityFlags)flags {
    __block SCNetworkReachabilityFlags flags;
    dispatch_sync(_synchronizationQueue, ^{
        flags = _flags;
    });
    return flags;
}

- (AGRestReachabilityStatus)currentState {
    return [[self class] _reachabilityStateForFlags:self.flags];
}

#pragma mark - Reachability
#pragma mark -

- (void)_startMonitoringReachabilityWithURL:(NSURL *)url {
    dispatch_barrier_async(_synchronizationQueue, ^{
        const char *host = [[url host] UTF8String];
        if (!host) return ;
        _networkReachability = SCNetworkReachabilityCreateWithName(NULL, host);
        if (_networkReachability != NULL) {
            // Set the initial flags
            SCNetworkReachabilityFlags flags;
            SCNetworkReachabilityGetFlags(_networkReachability, &flags);
            self.flags = flags;
            
            // Set up notification for changes in reachability.
            SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
            if (SCNetworkReachabilitySetCallback(_networkReachability, _reachabilityCallback, &context)) {
                if (!SCNetworkReachabilitySetDispatchQueue(_networkReachability, _synchronizationQueue)) {
                    //LogError(@"Unable to start listening for network connectivity status.");
                }
            }
        }
    });
}

+ (AGRestReachabilityStatus)_reachabilityStateForFlags:(SCNetworkConnectionFlags)flags {
    AGRestReachabilityStatus reachabilityState = AGRestReachabilityStatusNotReachable;
    
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
        // if target host is not reachable
        return reachabilityState;
    }
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        // if target host is reachable and no connection is required
        //  then we'll assume (for now) that your on Wi-Fi
        reachabilityState = AGRestReachabilityStatusReachableVieWifi;
    }
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
        // ... and the connection is on-demand (or on-traffic) if the
        //     calling application is using the CFSocketStream or higher APIs
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            // ... and no [user] intervention is needed
            reachabilityState = AGRestReachabilityStatusReachableVieWifi;
        }
    }
    
#if TARGET_OS_IPHONE
    if (((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) &&
        ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)) {
        // ... but WWAN connections are OK if the calling application
        //     is using the CFNetwork (CFSocketStream?) APIs.
        // ... and a network connection is not required (kSCNetworkReachabilityFlagsConnectionRequired)
        //     which could be et w/connection flag (e.g. IsWWAN) indicating type of connection required.
        reachabilityState = AGRestReachabilityStatusReachableViaWan;
    }
#endif
    
    return reachabilityState;
}


@end
