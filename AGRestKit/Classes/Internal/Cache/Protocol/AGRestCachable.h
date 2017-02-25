//
//  AGRestCachable.h
//  AGRestStack
//
//  Created by Adrien Greiner on 27/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AGRestCachable <NSObject>

- (instancetype)initWithDictionary:(nonnull NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;

+ (BOOL)isValidDictionaryRepresentation:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
