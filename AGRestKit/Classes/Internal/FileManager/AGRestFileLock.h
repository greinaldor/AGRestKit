//
//  AGRestFileLock.h
//  AGRestStack
//
//  Created by Adrien Greiner on 27/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AGRestFileLock : NSObject

@property (nonatomic, copy, readonly) NSString    *filePath;
@property (nonatomic, copy, readonly) NSString    *lockFilePath;

- (instancetype)initFileLockWithFileAtPath:(NSString *)filePath;
+ (instancetype)fileLockForFileAtPath:(NSString *)path;

- (void)lock;
- (void)unlock;

@end
