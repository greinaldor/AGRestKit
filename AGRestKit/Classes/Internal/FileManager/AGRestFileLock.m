//
//  AGRestFileLock.m
//  AGRestStack
//
//  Created by Adrien Greiner on 27/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestFileLock.h"

@interface AGRestFileLock() {
    dispatch_queue_t _synchronizationQueue;
    int _fileDescriptor;
}

@property (nonatomic, copy, readwrite) NSString *filePath;
@property (nonatomic, copy, readwrite) NSString *lockFilePath;

@end

@implementation AGRestFileLock

@synthesize filePath = _filePath;
@synthesize lockFilePath = _lockFilePath;

#pragma mark - Init
#pragma mark -

- (instancetype)initFileLockWithFileAtPath:(NSString *)filePath {
    self = [super init];
    if (self) {
        
        _filePath = [filePath copy];
        _lockFilePath = [filePath stringByAppendingPathExtension:@"lock"];
        
        NSString *queueName = [NSString stringWithFormat:@"com.AGRest.fileprocesslock.%@", [[filePath lastPathComponent] stringByDeletingPathExtension]];
        _synchronizationQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

+ (instancetype)fileLockForFileAtPath:(NSString *)path {
    return [[AGRestFileLock alloc] initFileLockWithFileAtPath:path];
}

#pragma mark - Locking
#pragma mark -

- (void)lock {
    dispatch_sync(_synchronizationQueue, ^{
        // Greater than zero means that the lock was already succesfully acquired.
        if (_fileDescriptor > 0) {
            return;
        }
        BOOL locked = NO;
        while (!locked) @autoreleasepool {
            locked = [self _tryLock];
            if (!locked) {
                [NSThread sleepForTimeInterval:0.002];
            }
        }
    });
}

- (void)unlock {
    dispatch_sync(_synchronizationQueue, ^{
        // Only descriptor that is greater than zero is going to be open.
        if (_fileDescriptor <= 0) {
            return;
        }
        // Close the file with _fileDescriptor
        close(_fileDescriptor);
        _fileDescriptor = 0;
    });
}

#pragma mark - Private()
#pragma mark -

- (BOOL)_tryLock {
    const char *filePath = [self.lockFilePath fileSystemRepresentation];
    // Open the file
    _fileDescriptor = open(filePath, (O_RDWR | O_CREAT | O_EXLOCK),
                           ((S_IRUSR | S_IWUSR | S_IXUSR) | (S_IRGRP | S_IWGRP | S_IXGRP) | (S_IROTH | S_IWOTH | S_IXOTH)));
    return (_fileDescriptor > 0);
}

@end
