//
//  AGRestRequestCache.m
//  AGRestStack
//
//  Created by Adrien Greiner on 27/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestRequestCache.h"

#import <Bolts/BFTask.h>
#import <Bolts/BFTaskCompletionSource.h>
#import "BFTask+Private.h"

#import "AGRestFileManager.h"
#import "AGRestFileLockController.h"
#import "AGRestRequest.h"
#import "AGRestRequest_Private.h"
#import "AGRestResponse.h"
#import "AGRestErrorUtilities.h"
#import "AGRestEventuallyQueue_Private.h"

static NSString *const _AGRestRequestCacheDiskCacheDirectoryName = @"RequestsCache";
unsigned long long const AGRestRequestsCacheDefaultDiskCacheSize = 10 * 1024 * 1024; // 10 MB

@interface AGRestRequestCache() {
    unsigned int _fileCounter;
}

@property (nonatomic, assign, readwrite, setter=_setDiskCacheSize:) unsigned long long diskCacheSize;
@property (nonatomic, copy) NSString * cacheUrlPath;

@end

@implementation AGRestRequestCache

+ (instancetype)cacheWithRequestRunner:(nonnull id<AGRestRequestRunning>)runner
                        cacheDirectory:(nonnull NSString *)cacheDirectory
                          maxCacheSize:(NSUInteger)maxCacheSize {
    AGRestRequestCache *requestCache = [[AGRestRequestCache alloc] initWithRequestRunner:runner
                                                                          cacheDirectory:cacheDirectory
                                                                            maxCacheSize:maxCacheSize];
    [requestCache start];
    return requestCache;
}

- (instancetype)initWithRequestRunner:(nonnull id<AGRestRequestRunning>)runner
                       cacheDirectory:(nonnull NSString *)cacheDir
                         maxCacheSize:(NSUInteger)maxCacheSize {
    self = [super initWithRequestRunner:runner
                            maxAttempts:AGRestEventuallyQueueDefaultMaxAttemps
                          retryInterval:AGRestEventuallyQueueDefaultRetryTimeInterval];
    if (self) {
        _cacheUrlPath = cacheDir;
        [self _setDiskCacheSize:maxCacheSize];
        [self _createDiskCachePathIfNeeded];
    }
    return self;
}

- (void)removeAllRequests {
    [self pause];
    
    [super removeAllRequests];
    
    NSArray *requestIdentifiers = [self _pendingRequestIdentifiers];
    NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:[requestIdentifiers count]];
    
    for (NSString *identifier in requestIdentifiers) {
        BFTask *task = [self _removeFileForRequestWithIdentifier:identifier];
        [tasks addObject:task];
    }
    
    [[BFTask taskForCompletionOfAllTasks:tasks] waitUntilFinished];
    
    [self resume];
}

#pragma mark PFEventuallyQueueSubclass

- (NSString *)_newIdentifierForRequest:(AGRestRequest *)request {
    // Start with current time - so we can sort identifiers and get the oldest one first.
    return [NSString stringWithFormat:@"Request-%016qx-%08x-%@",
            (unsigned long long)[NSDate timeIntervalSinceReferenceDate],
            _fileCounter++,
            [[NSUUID UUID] UUIDString]];
}

- (NSArray *)_pendingRequestIdentifiers {
    NSArray *result = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.cacheUrlPath error:nil];
    result = [result filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", @"Request"]];
    return [result sortedArrayUsingSelector:@selector(compare:)];
}

- (AGRestRequest *)_requestWithIdentifier:(NSString *)identifier error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    [[AGRestFileLockController sharedController] beginLockContentOfFileAtPath:self.cacheUrlPath];
    
    NSError *innerError = nil;
    NSData *jsonData = [NSData dataWithContentsOfFile:[self _filePathForRequestWithIdentifier:identifier]
                                              options:NSDataReadingUncached
                                                error:&innerError];
    
    [[AGRestFileLockController sharedController] endLockContentOfFileAtPath:self.cacheUrlPath];
    
    if (innerError || !jsonData) {
        NSString *message = [NSString stringWithFormat:@"Failed to read request from cache. %@",
                             innerError ? [innerError localizedDescription] : @""];
        innerError = [AGRestErrorUtilities errorWithCode:kSSErrorInternalLocal
                                                 message:message];
        if (error) {
            *error = innerError;
        }
        return nil;
    }
    
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:0
                                                      error:&innerError];
    if (innerError) {
        NSString *message = [NSString stringWithFormat:@"Failed to deserialiaze request from cache. %@",
                             [innerError localizedDescription]];
        innerError = [AGRestErrorUtilities errorWithCode:kSSErrorInternalLocal
                                                 message:message];
    } else {
        if ([AGRestRequest isValidDictionaryRepresentation:jsonObject]) {
            return [AGRestRequest requestWithDictionary:jsonObject];
        }
        innerError = [AGRestErrorUtilities errorWithCode:kSSErrorInternalLocal
                                                 message:@"Failed to construct eventually request from cache."
                                               shouldLog:NO];
    }
    if (innerError && error) {
        *error = innerError;
    }
    
    return nil;
}

- (BFTask *)_enqueueRequestInBackground:(AGRestRequest *)request
                             identifier:(NSString *)identifier {
    return [self _saveRequestToCacheInBackground:request identifier:identifier];
}

- (BFTask *)_didFinishRunningRequest:(AGRestRequest *)request
                      withIdentifier:(NSString *)identifier
                          resultTask:(BFTask *)resultTask
{
    [[self _removeFileForRequestWithIdentifier:identifier] waitUntilFinished];
    return [super _didFinishRunningRequest:request withIdentifier:identifier resultTask:resultTask];
}

#pragma mark - Disk Cache

- (BFTask *)_cleanupDiskCacheWithRequiredFreeSize:(NSUInteger)requiredSize {
    return [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id{
        NSUInteger size = requiredSize;
        
        NSMutableDictionary *requestSizes = [NSMutableDictionary dictionary];
        
        [[AGRestFileLockController sharedController] beginLockContentOfFileAtPath:self.cacheUrlPath];
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.cacheUrlPath];
        
        NSString *identifier = nil;
        while ((identifier = [enumerator nextObject])) {
            NSNumber *fileSize = [enumerator fileAttributes][NSFileSize];
            if (fileSize) {
                requestSizes[identifier] = fileSize;
                size += [fileSize unsignedIntegerValue];
            }
        }
        
        [[AGRestFileLockController sharedController] endLockContentOfFileAtPath:self.cacheUrlPath];
        
        if (size > self.diskCacheSize) {
            // Get identifiers and sort them to remove oldest requests first
            NSArray *identifiers = [[requestSizes allKeys] sortedArrayUsingSelector:@selector(compare:)];
            for (NSString *identifier in identifiers) @autoreleasepool {
                [self _removeFileForRequestWithIdentifier:identifier];
                size -= [requestSizes[identifier] unsignedIntegerValue];
                
                if (size <= self.diskCacheSize) {
                    break;
                }
                [requestSizes removeObjectForKey:identifier];
            }
        }
        
        return [BFTask taskWithResult:nil];
    }];
}

- (void)_setDiskCacheSize:(unsigned long long)diskCacheSize {
    _diskCacheSize = diskCacheSize;
}

#pragma mark - Files

- (BFTask *)_saveRequestToCacheInBackground:(AGRestRequest *)request
                                 identifier:(NSString *)identifier {
    weakify(self);
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        strongify(weakSelf);
        
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:[request dictionaryRepresentation]
                                                       options:0
                                                         error:&error];
        NSUInteger requestSize = [data length];
        if (requestSize > strongSelf.diskCacheSize) {
            error = [AGRestErrorUtilities errorWithCode:kSSErrorInternalLocal
                                            message:@"Failed to run request, because it's too big."];
        } else if (requestSize <= 4) {
            error = [AGRestErrorUtilities errorWithCode:kSSErrorInternalLocal
                                            message:@"Failed to run request, because it's empty."];
        }
        
        if (error) {
            return [BFTask taskWithError:error];
        }
        
        [[AGRestFileLockController sharedController] beginLockContentOfFileAtPath:self.cacheUrlPath];
        return [[[self _cleanupDiskCacheWithRequiredFreeSize:requestSize] continueWithBlock:^id(BFTask *task) {
            NSString *filePath = [self _filePathForRequestWithIdentifier:identifier];
            return [AGRestFileManager writeDataAsync:data toFileAtPath:filePath];
        }] continueWithBlock:^id(BFTask *task) {
            [[AGRestFileLockController sharedController] endLockContentOfFileAtPath:self.cacheUrlPath];
            return task;
        }];
    }];
}

- (BFTask *)_removeFileForRequestWithIdentifier:(NSString *)identifier {
    NSString *filePath = [self _filePathForRequestWithIdentifier:identifier];
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        [[AGRestFileLockController sharedController] beginLockContentOfFileAtPath:self.cacheUrlPath];
        return [AGRestFileManager removeItemAsynAtPath:filePath shouldLock:NO];
    }] continueWithBlock:^id(BFTask *task) {
        [[AGRestFileLockController sharedController] endLockContentOfFileAtPath:self.cacheUrlPath];
        return task; // Roll-forward the previous task.
    }];
}

- (NSString *)_filePathForRequestWithIdentifier:(NSString *)identifier {
    return [self.cacheUrlPath stringByAppendingPathComponent:identifier];
}

- (void)_createDiskCachePathIfNeeded {
    [[[AGRestFileManager createDirectoryIfNeededAsyncAtPath:_cacheUrlPath] waitForResult:nil withMainThreadWarning:NO]
     continueWithBlock:^id(BFTask *task) {
        if (task.faulted) {
            NSLog(@"Failed to create request cache directory");
        }
        return nil;
    }];
}

@end
