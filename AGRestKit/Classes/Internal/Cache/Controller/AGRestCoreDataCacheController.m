//
//  AGRestDataManager.m
//  AGRestStack
//
//  Created by Adrien Greiner on 18/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestCoreDataCacheController.h"

#import "AGRestServer.h"

@implementation AGRestCoreDataCacheController

- (BOOL)save
{
    return NO;
}

- (void)reset
{
    
}

- (void)handleFatalCoreDataError:(NSError*)error
{
    
}

+ (instancetype)sharedDataManager
{
    static AGRestCoreDataCacheController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
    });
    return sharedInstance;
}

@end
