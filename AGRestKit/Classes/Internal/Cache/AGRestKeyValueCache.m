//
//  AGRestKeyValueCache.m
//  AGRestStack
//
//  Created by Adrien Greiner on 26/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestKeyValueCache.h"

@implementation AGRestKeyValueCache

@synthesize dataSource = _dataSource;

- (instancetype)initWithDataSource:(id<AGRestCoreManagerDataSource>)dataSource {
    self = [super init];
    if (self) {
        _dataSource = dataSource;
    }
    return self;
}

- (void)setObject:(NSString *)object forKey:(NSString *)key {
    
}

- (NSString *)objectForKey:(NSString *)key maxAge:(NSTimeInterval)age {
    return nil;
}

- (void)removeObjectForKey:(NSString *)key {
    
}

- (void)removeAllObjects {
    
}

@end


