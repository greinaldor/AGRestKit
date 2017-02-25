//
//  AGRestFileManager.m
//  AGRestStack
//
//  Created by Adrien Greiner on 27/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestFileManager.h"

#import <Bolts/Bolts.h>

#import "BFTask+Private.h"
#import "AGRestFileLockController.h"

static NSDictionary *_AGRestFileManagerDefaultDirectoryFileAttributes() {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    return @{ NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication };
#else
    return nil;
#endif
}

static NSDataWritingOptions _AGRestFileManagerDefaultDataWritingOptions() {
    NSDataWritingOptions options = NSDataWritingAtomic;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    options |= NSDataWritingFileProtectionCompleteUntilFirstUserAuthentication;
#endif
    return options;
}

NSString * const AGRestDefaultCacheDirectory = @"caches";
NSString * const AGRestDefaultDataDirectory = @"data";

@interface AGRestFileManager()

@property (nonatomic, copy) NSString * restRootDirectory;

@end

@implementation AGRestFileManager

@synthesize restRootDirectory = _restRootDirectory;

#pragma mark - Init
#pragma mark -

- (instancetype)initWithRestDirectory:(NSString *)restDirectory {
    self = [super init];
    if (!self) return nil;
    _restRootDirectory = restDirectory;
    // Create the root directory if don't exists
    [[self class] createDirectoryIfNeededAsyncAtPath:_restRootDirectory];
    return self;
}

#pragma mark - Domain Directory
#pragma mark -

+ (NSString *)applicationSupport {
    return NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
}

+ (NSString *)libraryDirectory {
    return NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
}

+ (NSString *)documentsDirectory {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}

+ (NSString *)cacheDirectory {
    return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
}

- (NSString *)restRootDirectory {
    return _restRootDirectory;
}

- (NSString *)restDataDirectory {
    return [_restRootDirectory stringByAppendingPathComponent:AGRestDefaultDataDirectory];
}

- (NSString *)restCacheDirectory {
    return [_restRootDirectory stringByAppendingPathComponent:AGRestDefaultCacheDirectory];
}

#pragma mark - Directory Management
#pragma mark -

#pragma mark Create Directory

+ (BFTask *)createDirectoryIfNeededAsyncAtPath:(nonnull NSString *)directoryPath {
    return [[self class] createDirectoryIfNeededAsyncAtPath:directoryPath
                                               withExecutor:[BFExecutor defaultPriorityBackgroundExecutor]];
}

+ (BFTask *)createDirectoryIfNeededAsyncAtPath:(nonnull NSString *)directoryPath
                                  withExecutor:(nonnull BFExecutor *)executor
{
    BFTask *task = [BFTask taskFromExecutor:executor withBlock:^id{
        if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath]) {
            NSError *error = nil;
            if (![[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                          withIntermediateDirectories:YES
                                                           attributes:_AGRestFileManagerDefaultDirectoryFileAttributes()
                                                                error:&error])
            {
                return [BFTask taskWithError:error];
            }
        }
        return nil;
    }];
    return task;
}

#pragma mark - Move Directory Contents

+ (BFTask *)moveDirectoryContentsAsyncFromPath:(nonnull NSString *)fromPath
                                        toPath:(nonnull NSString *)toPath
{
    return [[self class] moveDirectoryContentsAsyncFromPath:fromPath
                                                     toPath:toPath
                                               withExecutor:[BFExecutor defaultPriorityBackgroundExecutor]];
}

+ (BFTask *)moveDirectoryContentsAsyncFromPath:(nonnull NSString *)fromPath
                                        toPath:(nonnull NSString *)toPath
                                  withExecutor:(nonnull BFExecutor *)executor
{
    BFTask *task = [[[self class] createDirectoryIfNeededAsyncAtPath:toPath withExecutor:executor] continueWithBlock:^id(BFTask *task) {
        NSError *error = nil;
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fromPath
                                                                                error:&error];
        if (error) {
            return [BFTask taskWithError:error];
        }
        
        NSMutableArray *fileTasks = [NSMutableArray arrayWithCapacity:contents.count];
        for (NSString * filename in contents) {
            BFTask *fileTask = [BFTask taskFromExecutor:executor withBlock:^id{
                NSError *error = nil;
                NSString *fromFilePath = [fromPath stringByAppendingPathComponent:filename];
                NSString *toFilePath = [toPath stringByAppendingPathComponent:filename];
                if (![[NSFileManager defaultManager] moveItemAtPath:fromFilePath toPath:toFilePath error:&error]) {
                    return [BFTask taskWithError:error];
                }
                return nil;
            }];
            [fileTasks addObject:fileTask];
        }
        return [BFTask taskForCompletionOfAllTasks:fileTasks];
    }];
    return task;
}

#pragma mark - Remove Directory Contents

+ (BFTask *)removeDirectoryContentsAsyncAtPath:(nonnull NSString *)directoryPath {
    return [[self class] removeDirectoryContentsAsyncAtPath:directoryPath
                                               withExecutor:[BFExecutor defaultPriorityBackgroundExecutor]];
}

+ (BFTask *)removeDirectoryContentsAsyncAtPath:(NSString *)directoryPath
                                  withExecutor:(BFExecutor *)executor
{
    BFTask *task = [[BFTask taskFromExecutor:executor withBlock:^id{
        [[AGRestFileLockController sharedController] beginLockContentOfFileAtPath:directoryPath];
        NSError *error = nil;
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
        if (error) {
            return [BFTask taskWithError:error];
        }
        NSMutableArray *fileTasks = [NSMutableArray arrayWithCapacity:contents.count];
        for (NSString * filename in contents) {
            NSString *filePath = [directoryPath stringByAppendingPathComponent:filename];
            BFTask *fileTask = [[[self class] removeItemAsynAtPath:filePath shouldLock:NO withExecutor:executor] continueWithBlock:^id(BFTask *task) {
                if (task.faulted) {
                    NSLog(@"<FileManager> Failed to remove file at path %@", filePath);
                }
                return nil;
            }];
            [fileTasks addObject:fileTask];
        }
        return [BFTask taskForCompletionOfAllTasks:fileTasks];
    }] continueWithBlock:^id(BFTask *task) {
        [[AGRestFileLockController sharedController] endLockContentOfFileAtPath:directoryPath];
        return nil;
    }];
    return task;
}

#pragma mark - Remove Item

+ (BFTask *)removeItemAsynAtPath:(nonnull NSString *)itemPath shouldLock:(BOOL)lock
 {
    return [[self class] removeItemAsynAtPath:itemPath
                                   shouldLock:lock
                                 withExecutor:[BFExecutor defaultPriorityBackgroundExecutor]];
}

+ (BFTask *)removeItemAsynAtPath:(nonnull NSString *)itemPath
                      shouldLock:(BOOL)lock
                    withExecutor:(nonnull BFExecutor *)executor
{
    BFTask *task = [[BFTask taskFromExecutor:executor withBlock:^id{
        if (lock) {
            [[AGRestFileLockController sharedController] beginLockContentOfFileAtPath:itemPath];
        }
        NSError * error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:itemPath
                                                       error:&error]) {
            return [BFTask taskWithError:error];
        }
        return nil;
    }] continueWithBlock:^id(BFTask *task) {
        if (lock) {
            [[AGRestFileLockController sharedController] endLockContentOfFileAtPath:itemPath];
        }
        return nil;
    }];
    return task;
}

#pragma mark - Copy Item

+ (BFTask *)copyItemAsyncAtPath:(nonnull NSString *)atPath
                         toPath:(nonnull NSString *)toPath
{
    return [[self class] copyItemAsyncAtPath:atPath
                                      toPath:toPath
                                withExecutor:[BFExecutor defaultPriorityBackgroundExecutor]];
}

+ (BFTask *)copyItemAsyncAtPath:(nonnull NSString *)atPath
                         toPath:(nonnull NSString *)toPath
                   withExecutor:(nonnull BFExecutor *)executor
{
    BFTask *task = [BFTask taskFromExecutor:executor withBlock:^id{
        NSError *error = nil;
        if (![[NSFileManager defaultManager] copyItemAtPath:atPath toPath:toPath error:&error]) {
            return [BFTask taskWithError:error];
        }
        return nil;
    }];
    return task;
}

#pragma mark - Move Item

+ (BFTask *)moveItemAsyncFromPath:(nonnull NSString *)fromPath
                           toPath:(nonnull NSString *)toPath
{
    return [[self class] moveItemAsyncFromPath:fromPath
                                        toPath:toPath
                                  withExecutor:[BFExecutor defaultExecutor]];
}

+ (BFTask *)moveItemAsyncFromPath:(nonnull NSString *)fromPath
                           toPath:(nonnull NSString *)toPath
                     withExecutor:(nonnull BFExecutor *)executor
{
    BFTask * task = [BFTask taskFromExecutor:executor withBlock:^id{
        if ([fromPath isEqualToString:toPath]) {
            return [BFTask taskWithResult:nil];
        }
        
        NSError *error = nil;
        if (![[NSFileManager defaultManager] moveItemAtPath:fromPath toPath:toPath error:&error]) {
            return [BFTask taskWithError:error];
        }
        return nil;
    }];
    return task;
}

#pragma mark - File Management
#pragma mark -

#pragma mark Write String File

+ (BFTask *)writeStringAsync:(nonnull NSString *)string
                toFileAtPath:(nonnull NSString *)filePath
{
    return [[self class] writeStringAsync:string
                             toFileAtPath:filePath
                             withExecutor:[BFExecutor defaultPriorityBackgroundExecutor]];
}

+ (BFTask *)writeStringAsync:(nonnull NSString *)string
                toFileAtPath:(nonnull NSString *)filePath
                withExecutor:(nonnull BFExecutor *)executor
{
    BFTask *task = [BFTask taskFromExecutor:executor withBlock:^id{
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        return [[self class] writeDataAsync:data
                               toFileAtPath:filePath
                               withExecutor:executor];
    }];
    return task;
}

#pragma mark - Write Data File

+ (BFTask *)writeDataAsync:(nonnull NSData *)data
              toFileAtPath:(nonnull NSString *)filePath
{
    return [[self class] writeDataAsync:data
                           toFileAtPath:filePath
                           withExecutor:[BFExecutor defaultPriorityBackgroundExecutor]];
}

+ (BFTask *)writeDataAsync:(NSData *)data
              toFileAtPath:(NSString *)filePath
              withExecutor:(BFExecutor *)executor
{
    BFTask *task = [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSError *error = nil;
        [data writeToFile:filePath
                  options:_AGRestFileManagerDefaultDataWritingOptions()
                    error:&error];
        if (error) {
            return [BFTask taskWithError:error];
        }
        return nil;
    }];
    return task;
}

#pragma - Read Content String File

+ (BFTask *)contentStringAsyncFromFile:(nonnull NSString *)filePath {
    return [[self class] contentStringAsyncFromFile:filePath
                                       withExecutor:[BFExecutor defaultPriorityBackgroundExecutor]];
}

+ (BFTask *)contentStringAsyncFromFile:(nonnull NSString *)filePath
                          withExecutor:(BFExecutor *)executor
{
    return [[[self class] contentDataAsyncFromFile:filePath withExecutor:executor] continueWithBlock:^id(BFTask *task) {
        if (!task.faulted) {
            NSString *contentString = [[NSString alloc] initWithData:task.result encoding:NSUTF8StringEncoding];
            return [BFTask taskWithResult:contentString];
        }
        return task;
    }];
}

#pragma mark - Read Content Data File

+ (BFTask *)contentDataAsyncFromFile:(nonnull NSString *)filePath {
    return [[self class] contentDataAsyncFromFile:filePath
                                     withExecutor:[BFExecutor defaultPriorityBackgroundExecutor]];
}

+ (BFTask *)contentDataAsyncFromFile:(nonnull NSString *)filePath
                        withExecutor:(nonnull BFExecutor *)executor
{
    BFTask * task = [BFTask taskFromExecutor:executor withBlock:^id{
        NSError *error = nil;
        NSData *fileContentString = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
        if (error) {
            return [BFTask taskWithError:error];
        }
        return [BFTask taskWithResult:fileContentString];
    }];
    return task;
}

@end
