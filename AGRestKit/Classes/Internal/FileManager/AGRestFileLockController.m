//
//  AGRestFileLockController.m
//  AGRestStack
//
//  Created by Adrien Greiner on 27/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestFileLockController.h"

#import "AGRestFileLock.h"

@interface AGRestFileLockController () {
    dispatch_queue_t    _synchronizationQueue;
    NSMutableDictionary *_locksDictionary;
    NSMutableDictionary *_contentAccessDictionary;
}

@end

@implementation AGRestFileLockController

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    _synchronizationQueue = dispatch_queue_create("com.AGRest.fileprocesslock.controller", DISPATCH_QUEUE_CONCURRENT);
    
    _locksDictionary = [NSMutableDictionary dictionary];
    _contentAccessDictionary = [NSMutableDictionary dictionary];
    
    return self;
}

+ (instancetype)sharedController {
    static AGRestFileLockController *controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [[AGRestFileLockController alloc] init];
    });
    return controller;
}

- (void)beginLockContentOfFileAtPath:(NSString *)filePath {
    dispatch_barrier_sync(_synchronizationQueue, ^{
        AGRestFileLock *fileLock = _locksDictionary[filePath];
        if (!fileLock) {
            fileLock = [AGRestFileLock fileLockForFileAtPath:filePath];
            _locksDictionary[filePath] = fileLock;
        }
        
        [fileLock lock];
        
        NSUInteger contentAccess = [_contentAccessDictionary[filePath] unsignedIntegerValue];
        _contentAccessDictionary[filePath] = @(contentAccess + 1);
    });
}

- (void)endLockContentOfFileAtPath:(NSString *)filePath {
    dispatch_barrier_sync(_synchronizationQueue, ^{
        AGRestFileLock *fileLock = _locksDictionary[filePath];
        [fileLock unlock];
        
        if (fileLock && [_contentAccessDictionary[filePath] unsignedIntegerValue] == 0) {
            [_locksDictionary removeObjectForKey:filePath];
            [_contentAccessDictionary removeObjectForKey:filePath];
        }
    });
}

- (NSUInteger)lockedContentAccessCountForFileAtPath:(NSString *)filePath {
    __block NSUInteger value = 0;
    dispatch_sync(_synchronizationQueue, ^{
        value = [_contentAccessDictionary[filePath] unsignedIntegerValue];
    });
    return value;
}

@end
