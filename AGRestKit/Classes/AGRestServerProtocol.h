//
//  AGRestServerProtocl.h
//  AGRestStack
//
//  Created by Adrien Greiner on 24/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestConstants.h"
#import "AGRestRequestRunning.h"

@class AGRestRequest;
@class AGRestResponse;

NS_ASSUME_NONNULL_BEGIN

/*!
    @discussion AGRestServerProtocol defines base methods to implement for any Server intending to serve AGRestRequest.
 */
@protocol AGRestServerProtocol <AGRestRequestRunning>

/*!
 @brief Reset server
 */
- (void)reset;

/*!
    @brief Set global HTTP Headers for all executing requests.
    @param value    Valid http header field value.
    @param key      Value http header field key.
 */
- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(nonnull NSString *)key;

@optional

/*!
    @brief Set the acceptable content types from HTTP response.
    @param contentTypes NSSet of string that contains all acceptable types.
 */
- (void)setAcceptableContentTypes:(NSSet *)contentTypes;

/*!
    @brief Set the acceptable status codes from HTTP response.
    @param httpStatusCodes  NSIndexSet of valid http status code.
 */
- (void)setAcceptableStatusCodes:(NSIndexSet *)httpStatusCodes;

@end

NS_ASSUME_NONNULL_END
