//
//  AGRestCaching.h
//  AGRestStack
//
//  Created by Adrien Greiner on 26/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AGRestModule.h"

@protocol AGRestKeyValueCaching <AGRestModuleProtocol>

///--------------------------------------
/// @name Setting
///--------------------------------------

- (void)setObject:(NSString *)object forKey:(NSString *)key;

///--------------------------------------
/// @name Getting
///--------------------------------------

- (NSString *)objectForKey:(NSString *)key maxAge:(NSTimeInterval)age;

///--------------------------------------
/// @name Removing
///--------------------------------------

- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;

@end
