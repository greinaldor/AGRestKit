//
//  AGRestRequestCache.h
//  AGRestStack
//
//  Created by Adrien Greiner on 27/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AGRestEventuallyQueue.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AGRestRequestRunning;

extern unsigned long long const AGRestRequestsCacheDefaultDiskCacheSize;

@interface AGRestRequestCache : AGRestEventuallyQueue

+ (instancetype)cacheWithRequestRunner:(nonnull id<AGRestRequestRunning>)runner
                        cacheDirectory:(nonnull NSString *)cacheDirectory
                          maxCacheSize:(NSUInteger)maxCacheSize;

- (instancetype)initWithRequestRunner:(nonnull id<AGRestRequestRunning>)runner
                       cacheDirectory:(nonnull NSString *)cacheDirectory
                         maxCacheSize:(NSUInteger)maxCacheSize NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithRequestRunner:(nonnull id<AGRestRequestRunning>)runner
                          maxAttempts:(NSUInteger)maxAttemps
                        retryInterval:(NSTimeInterval)retryInterval NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
