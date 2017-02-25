//
//  AGRestKeyValueCache.h
//  AGRestStack
//
//  Created by Adrien Greiner on 26/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AGRestKeyValueCaching.h"

/*!
 @class AGRestKeyValueCache
 
 **Important:** Not implemented yet.
 */
@interface AGRestKeyValueCache : NSObject <AGRestKeyValueCaching>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(id<AGRestCoreManagerDataSource>)dataSource NS_DESIGNATED_INITIALIZER;

///-----------------------
/// @name AGRestKeyValueCaching
///-----------------------

- (void)setObject:(NSString *)object forKey:(NSString *)key;
- (NSString *)objectForKey:(NSString *)key maxAge:(NSTimeInterval)age;

- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;

@end
