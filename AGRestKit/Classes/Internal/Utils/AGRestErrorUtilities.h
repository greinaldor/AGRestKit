//
//  AGRestErrorUtilities.h
//  AGRestStack
//
//  Created by Adrien Greiner on 21/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @class AGRestErrorUtilities
 
 @discussion Error utility class for constructing AGRestSDK based NSError.
 */
@interface AGRestErrorUtilities : NSObject

/*!
 @abstract Construct an error object from a code and a message.
 @discussion Note that this logs all errors given to it.
 You should use `errorWithCode:message:shouldLog:` to explicitly control whether it logs.
 @param code    AGRest Error Code
 @param message Error description
    
 @return Instance of `NSError` or `nil`.
*/
+ (nullable NSError *)errorWithCode:(NSInteger)code message:(nullable NSString *)message;
+ (nullable NSError *)errorWithCode:(NSInteger)code message:(nullable NSString *)message shouldLog:(BOOL)shouldLog;

/*!
 @abstract Construct an error object from a code, a message and an underlying error.
 @param code    AGRest Error Code
 @param message Error description
 @param underlyingError Underlying error of the new error.
 @return Instance of `NSError` or `nil`.
 */
+ (nullable NSError *)errorWithCode:(NSInteger)code message:(NSString *)message underlyingError:(NSError *)underlyingError;

/*!
 @abstract Construct an error object from a result dictionary the API returned.
 @discussion Note that this logs all errors given to it.
 You should use `errorFromResult:shouldLog:` to explicitly control whether it logs.
 @param result Network error request result.
 @return Instance of `NSError` or `nil`.
 */
+ (nullable NSError *)errorFromResult:(nonnull NSDictionary *)result;
+ (nullable NSError *)errorFromResult:(nonnull NSDictionary *)result shouldLog:(BOOL)shouldLog;

@end

NS_ASSUME_NONNULL_END
