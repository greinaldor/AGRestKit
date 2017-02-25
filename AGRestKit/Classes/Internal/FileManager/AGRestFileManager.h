//
//  AGRestFileManager.h
//  AGRestStack
//
//  Created by Adrien Greiner on 27/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BFTask;
@class BFExecutor;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const AGRestDefaultCacheDirectory;
extern NSString * const AGRestDefaultDataDirectory;

/*!
 @class AGRestFileManager
 
 @discussion Asynchronous file manager using Bolts and used in AGRestSDK to access the filesystem.
 */
@interface AGRestFileManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

///-----------------------
#pragma mark - Initialize
/// @name Init
///-----------------------
- (instancetype)initWithRestDirectory:(NSString *)restDirectory;

///-----------------------
#pragma mark - Domain Directories
/// @name Domain Directories
///-----------------------
/*!
 @return The system defined application's support directory.
 */
+ (NSString *)applicationSupport;
/*!
 @return The system defined application's document directory.
 */
+ (NSString *)documentsDirectory;
/*!
 @return The system defined application's library directory.
 */
+ (NSString *)libraryDirectory;
/*!
 @return The application cache directory.
 */
+ (NSString *)cacheDirectory;
/*!
 @return The AGRestSDK default document directory.
 */
- (NSString *)restRootDirectory;
/*!
 @return The AGRestSDK default document directory.
 */
- (NSString *)restDataDirectory;
/*!
 @return The AGRestSDK default document directory.
 */
- (NSString *)restCacheDirectory;

///-----------------------
#pragma mark - Directory Management
/// @name Directory Management
///-----------------------
/*!
 @abstract Create a new directory at the given path asynchronously only if doesn't already exists.
 @param directoryPath   Directory path where to create the new directory.
 @return On-going BFTask.
 */
+ (BFTask *)createDirectoryIfNeededAsyncAtPath:(nonnull NSString *)directoryPath;
/*!
 @abstract Create a new directory at the given path asynchronously only if don't already exists using a given BFExecutor.
 @param directoryPath   Directory path where to create the new directory.
 @param executor        BFExecutor to use for the operation.
 @return On-going BFTask.
 */
+ (BFTask *)createDirectoryIfNeededAsyncAtPath:(nonnull NSString *)directoryPath
                                  withExecutor:(nonnull BFExecutor *)executor;
/*!
 @abstract Remove directory's content asynchronously at the given path.
 @param directoryPath Directory path where to remove contents.
 @return On-going BFTask.
 */
+ (BFTask *)removeDirectoryContentsAsyncAtPath:(nonnull NSString *)directoryPath;

/*!
 @abstract Remove directory's content asynchronously at the given path using a given BFExecutor.
 @param directoryPath   Directory path where to remove contents.
 @param executor        BFExecutor to use for the operation.
 @return On-going BFTask.
 */
+ (BFTask *)removeDirectoryContentsAsyncAtPath:(NSString *)directoryPath
                                  withExecutor:(BFExecutor *)executor;

/*!
 @abstract Move a directory's content asynchronously from path to path.
 @param fromPath    The actual directory path.
 @param toPath      The new directory path.
 @return On-going BFTask.
 */
+ (BFTask *)moveDirectoryContentsAsyncFromPath:(nonnull NSString *)fromPath
                                        toPath:(nonnull NSString *)toPath;

/*!
 @abstract Move a directory's content asynchronously from path to path using a given BFExecutor.
 @param fromPath    The actual directory path.
 @param toPath      The new directory path.
 @param executor    BFExecutor to use for the operation.
 @return On-going BFTask.
 */
+ (BFTask *)moveDirectoryContentsAsyncFromPath:(nonnull NSString *)fromPath
                                        toPath:(nonnull NSString *)toPath
                                  withExecutor:(nonnull BFExecutor *)executor;

/*!
 @abstract Move an item asynchronously from path to path.
 @param fromPath    The actual item path.
 @param toPath      The new item path.
 @return On-going BFTask.
 */
+ (BFTask *)moveItemAsyncFromPath:(nonnull NSString *)fromPath
                           toPath:(nonnull NSString *)toPath;

/*!
 @abstract Move an item asynchronously from path to path using a given BFExecutor.
 @param fromPath    The actual item path.
 @param toPath      The new item path.
 @param executor    BFExecutor to use for the operation.
 @return On-going BFTask.
 */
+ (BFTask *)moveItemAsyncFromPath:(nonnull NSString *)fromPath
                           toPath:(nonnull NSString *)toPath
                     withExecutor:(nonnull BFExecutor *)executor;

/*!
 @abstract Remove an item asynchronously at path.
 @param itemPath    The item filepath.
 @param lock        Whether the item should be locked during the operation or not.
 @return On-going BFTask.
 */
+ (BFTask *)removeItemAsynAtPath:(nonnull NSString *)itemPath
                      shouldLock:(BOOL)lock;

/*!
 @abstract Remove an item asynchronously at path using a given BFExecutor.
 @param itemPath    The item filepath.
 @param lock        Whether the item should be locked during the operation or not.
 @param executor    BFExecutor to use for the operation.
 @return On-going BFTask.
 */
+ (BFTask *)removeItemAsynAtPath:(nonnull NSString *)itemPath
                      shouldLock:(BOOL)lock
                    withExecutor:(nonnull BFExecutor *)executor;

/*!
 @abstract Copy an item asynchronously at path to path.
 @param atPath      The item filepath.
 @param toPath      The new item filepath.
 @return On-going BFTask.
 */
+ (BFTask *)copyItemAsyncAtPath:(nonnull NSString *)atPath
                         toPath:(nonnull NSString *)toPath;

/*!
 @abstract Copy an item asynchronously at path to path using a given BFExecutor.
 @param atPath      The item filepath.
 @param toPath      The new item filepath.
 @param executor    BFExecutor to use for the operation.
 @return On-going BFTask.
 */
+ (BFTask *)copyItemAsyncAtPath:(nonnull NSString *)atPath
                         toPath:(nonnull NSString *)toPath
                   withExecutor:(nonnull BFExecutor *)executor;

///-----------------------
#pragma mark - File Management
/// @name File Management
///-----------------------
/*!
 @abstract Write a given string asynchronously to a given filepath.
 @param string      The NSString to write.
 @param filePath    The destination filepath.
 @return On-going BFTask.
 */
+ (BFTask *)writeStringAsync:(nonnull NSString *)string
                toFileAtPath:(nonnull NSString *)filePath;

/*!
 @abstract Write a given string asynchronously to a given filepath using a given BFExecutor.
 @param string      The NSString to write.
 @param filePath    The destination filepath.
 @param executor    BFExecutor to use for the operation.
 @return On-going BFTask.
 */
+ (BFTask *)writeStringAsync:(nonnull NSString *)string
                toFileAtPath:(nonnull NSString *)filePath
                withExecutor:(nonnull BFExecutor *)executor;

/*!
 @abstract Write given data asynchronously to a given filepath.
 @param data        The NSData to write.
 @param filePath    The destination filepath.
 @return On-going BFTask.
 */
+ (BFTask *)writeDataAsync:(nonnull NSData *)data
              toFileAtPath:(nonnull NSString *)filePath;

/*!
 @abstract Write given data asynchronously to a given filepath using a given BFExecutor.
 @param data        The NSData to write.
 @param filePath    The destination filepath.
 @param executor    BFExecutor to use for the operation.
 @return On-going BFTask.
 */
+ (BFTask *)writeDataAsync:(NSData *)data
              toFileAtPath:(NSString *)filePath
              withExecutor:(BFExecutor *)executor;

/*!
 @abstract Get an item's content as NSString asynchronously to a given filepath.
 @param filePath    The item's filepath.
 @return On-going BFTask.
 */
+ (BFTask *)contentStringAsyncFromFile:(nonnull NSString *)filePath;

/*!
 @abstract Get content as NSString asynchronously to a given filepath using a given BFExecutor.
 @param filePath    The item's filepath.
 @param executor    BFExecutor to use for the operation.
 @return On-going BFTask.
 */
+ (BFTask *)contentStringAsyncFromFile:(nonnull NSString *)filePath
                          withExecutor:(nonnull BFExecutor *)executor;

/*!
 @abstract Get an item's content as NSData asynchronously to a given filepath.
 @param filePath    The item's filepath.
 @return On-going BFTask.
 */
+ (BFTask *)contentDataAsyncFromFile:(nonnull NSString *)filePath;

/*!
 @abstract Get an item's content as NSData asynchronously to a given filepath using a given BFExecutor.
 @param filePath    The item's filepath.
 @param executor    BFExecutor to use for the operation.
 @return On-going BFTask.
 */
+ (BFTask *)contentDataAsyncFromFile:(nonnull NSString *)filePath
                        withExecutor:(nonnull BFExecutor *)executor;

@end

NS_ASSUME_NONNULL_END
