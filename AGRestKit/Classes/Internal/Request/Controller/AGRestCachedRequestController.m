//
//  AGRestCachedRequestController.m
//  AGRestStack
//
//  Created by Adrien Greiner on 24/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestCachedRequestController.h"

#import <Bolts/Bolts.h>

#import "AGRestKeyValueCache.h"
#import "AGRestRequest.h"
#import "AGRestResponse.h"

@implementation AGRestCachedRequestController

- (instancetype)initWithDataSource:(nonnull AGRestCachedRequestControllerDataSource)dataSource {
    return [super initWithDataSource:(AGRestRequestControllerDataSource)dataSource];
}

+ (instancetype)controllerWithDataSource:(nonnull AGRestCachedRequestControllerDataSource)dataSource {
    return [[AGRestCachedRequestController alloc] initWithDataSource:dataSource];
}

#pragma mark - AGRestRequestController Overriding
#pragma mark -

- (BFTask *)runRequestAsync:(AGRestRequest *)request withCancellationToken:(BFCancellationToken *)cancellationToken {
    
    if (cancellationToken.cancellationRequested) {
        return [BFTask cancelledTask];
    }
    
    switch (request.cachePolicy) {
            
        // Load from network and ignore cache
        case kAGRestRequestIgnoreCache: return [super runRequestAsync:request withCancellationToken:cancellationToken]; break;
            
        // Load from network then cache result
        case kAGRestRequestNetworkOnly: {
            return [[super runRequestAsync:request withCancellationToken:cancellationToken] continueWithSuccessBlock:^id(BFTask *task) {
                return [self _saveRequestResultAsync:task.result];
            }];
        } break;
            
        // Load from network then cache if network failed
        case kAGRestRequestNetworkElseCache: {
            return [[super runRequestAsync:request withCancellationToken:cancellationToken] continueWithBlock:^id(BFTask *task) {
                AGRestResponse *response = task.result;
                if (response.responseError || task.error) {
                    return [self _runRequestAsyncFromCache:request withCancellationToken:cancellationToken];
                }
                return [task continueWithBlock:^id(BFTask *task) {
                    return [self _saveRequestResultAsync:response];
                }];
            }];
        } break;
        
        // Load from cache, if fails load from network
        case kAGRestRequestCacheElseNetwork: {
            return [[self _runRequestAsyncFromCache:request withCancellationToken:cancellationToken] continueWithBlock:^id(BFTask *task) {
                AGRestResponse *response = task.result;
                if (response.responseError || task.error) {
                    return [[super runRequestAsync:request withCancellationToken:cancellationToken] continueWithBlock:^id(BFTask *task) {
                        return [self _saveRequestResultAsync:response];
                    }];
                }
                return task;
            }];
        } break;
        
        // Load from Cache then from Network
        case kAGRestRequestCacheThenNetwork: {
            NSLog(@"kAGRestRequestCacheThenNetwork : Not implemented");
            return [self _runRequestAsyncFromCache:request withCancellationToken:cancellationToken];
        } break;
            
        // Unknown Cache Policy
        default: {
            return [BFTask taskWithException:[NSException exceptionWithName:NSInternalInconsistencyException
                                                                     reason:@"Unknown cache policy"
                                                                   userInfo:@{@"cachePolicy":@(request.cachePolicy)}]];
        } break;
    }
}


#pragma mark - Cache
#pragma mark -

- (BFTask *)_runRequestAsyncFromCache:(AGRestRequest *)request withCancellationToken:(BFCancellationToken *)cancellationToken {
    
    // Load request from cache
    /// TODO: implement caching
    
    return [BFTask taskWithResult:request];
}

- (BFTask *)_saveRequestResultAsync:(AGRestResponse *)response {

    // Save result to cache
    /// TODO: implement caching
    
    // Roll-back result
    return [BFTask taskWithResult:response];
}

@end
