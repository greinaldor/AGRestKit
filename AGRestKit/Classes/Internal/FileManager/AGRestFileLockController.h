//
//  AGRestFileLockController.h
//  AGRestStack
//
//  Created by Adrien Greiner on 27/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AGRestFileLockController : NSObject

+ (instancetype)sharedController;

- (void)beginLockContentOfFileAtPath:(NSString *)filePath;
- (void)endLockContentOfFileAtPath:(NSString *)filePath;

- (NSUInteger)lockedContentAccessCountForFileAtPath:(NSString *)filePath;

@end
