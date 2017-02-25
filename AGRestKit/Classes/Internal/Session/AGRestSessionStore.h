//
//  AGRestSessionStore.h
//  AGRestStack
//
//  Created by Adrien Greiner on 23/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @protocol AGRestSessionStoreProtocol
 */
@protocol AGRestSessionStoreProtocol <NSObject>

@required

/*!
 @abstract Return the current session token with the identifier used to stored it.
 @param idenfifier    The identifier used. or nil if no session token found.
 @return              The session token string or nil if can't be found.
 */
- (nullable NSString *)sessionTokenWithIdentifier:(NSString * _Nullable __autoreleasing * _Nullable)identifier;

/*!
 @abstract Safely Store a session token for an identifier.
 @param token         The token to store.
 @param identifier    The identifier used to store the session token.
 @param error         The error, if any, which occured during store operation.
 @return              YES if the session token has been stored. NO otherwise with error.
 */
- (BOOL)storeSessionToken:(nonnull NSString *)token
            forIdentifier:(nonnull NSString *)identifier
                    error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
 @abstract Safely Store data for an identifier.
 @param data          The data to be stored.
 @param identifier    The identifier used to store the data.
 @param error         The error, if any, which occured during store operation.
 @return              YES if data has been stored successfully, NO otherwise with error.
 */
- (BOOL)storeData:(nonnull NSData *)data
    forIdentifier:(nonnull NSString *)identifier
            error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
 @abstract Remove the stored data with given identifier.
 @param identifier    The identifier used to store the data.
 @param error         The error, if any, which occured during store operation.
 @return              YES if data has been removed successfully, NO otherwise with error.
 */
- (BOOL)removeDataForIdentifier:(nonnull NSString *)identifier
                          error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
 @discussion Returns stored data for identifier.
 @param identifier The identifier used to retrieve data.
 @return NSData
 */
- (nullable NSData *)dataForIdentifier:(nonnull NSString *)identifier;

/*!
 @abstract Reset the currently stored session token and current user.
 @param error         The error, if any, which occured during the operation.
 @return              YES if current session token has been reset successfully, NO otherwise with error.
 */
- (BOOL)resetCurrentSession:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

/*!
 @class AGRestSessionStore
 */
@interface AGRestSessionStore : NSObject <AGRestSessionStoreProtocol>

- (nullable NSString *)sessionTokenWithIdentifier:(NSString * _Nullable __autoreleasing * _Nullable)identifier;

- (BOOL)storeSessionToken:(nonnull NSString *)token
            forIdentifier:(nonnull NSString *)identifier
                    error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)storeData:(nonnull NSData *)data
    forIdentifier:(nonnull NSString *)identifier
            error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)removeDataForIdentifier:(nonnull NSString *)identifier
                          error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)resetCurrentSession:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end
