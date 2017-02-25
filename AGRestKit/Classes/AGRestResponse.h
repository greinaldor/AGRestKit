//
//  AGRestResponse.h
//  AGRestStack
//
//  Created by Adrien Greiner on 18/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AGRestRequest;

/*!
 @class AGRestResponse
 
 @discussion The AGRestResponse class represents a server's response from the API server. It contains the result object(s), error(s)
 from an executed AGRestRequest.
 */
@interface AGRestResponse : NSObject

///--------------
/// @name Properties
///--------------
/*!
 @abstract The request executed that leads to the response.
 */
@property (nonatomic, weak, nullable) AGRestRequest    *request;
/*!
 @abstract If occured, the NSError representing the request failure.
 */
@property (nonatomic, strong, nullable) NSError        *responseError;
/*!
 @abstract The parsed and serialized response data from the HTTP response.
 @note If objectMapping enabled, an instance of NSObject conforming AGRestObjectMapping.
 */
@property (nonatomic, strong, nullable) id             responseData;
/*!
 @abstract The target class to map with the response data.
 */
@property (nonatomic, copy, nullable) Class            targetClass;

///---------------
/// @name HTTP Response
///---------------
/*!
 @return The HTTP header attached to the response.
 */
- (nullable NSDictionary *)responseHeader;
/*!
 @return The HTTP status code attached to the response.
 */
- (NSInteger)httpStatusCode;
/*!
 @return The response's data as a NSString.
 @note This returns nil if response data has been mapped.
 */
- (nullable NSString *)contentString;
/*!
 @return The HTTP content type in the response's header.
 */
- (nullable NSString *)contentType;
/*!
 @return The HTTP content encoding in the response's header.
 */
- (nullable NSString *)contentEncoding;
/*!
 @return The HTTP Last Modified date in the response's header.
 */
- (nullable NSDate *)lastModified;

///---------------
/// @name Response Status
///---------------
/*!
 @abstract Whether the initial request failed or succeeded
 @return YES if succeeded, NO otherwise.
 */
- (BOOL)succeeded;
/*!
 @abstract Whether the initial request has been cancelled.
 @return YES if cancelled, NO otherwise.
 */
- (BOOL)cancelled;

///---------------
/// @name Init
///---------------
/*!
 @param error NSError attached to the response.
 @return Returns an initialized `AGRestResponse` with response NSError.
 */
+ (nullable instancetype)responseWithError:(nonnull NSError *)error;
/*!
 @param error NSError attached to the response.
 @param statusCode The HTTP status code attached to the response.
 @return Returns an initialized `AGRestResponse` with response NSError.
 */
+ (nullable instancetype)responseWithError:(nonnull NSError *)error statusCode:(NSInteger)statusCode;
/*!
 @return Return an initialized `AGRestResponse` with response data.
 @param data The response data.
 @param header The HTTP response's header.
 */
+ (nullable instancetype)responseWithData:(nullable id)data header:(nullable NSDictionary *)header;
/*!
 @return Return an initialized `AGRestResponse` with response data.
 @param data The response data.
 @param header The HTTP response's header.
 @param statusCode The HTTP status code attached to the response.
 */
+ (nullable instancetype)responseWithData:(nullable id)data header:(nullable NSDictionary *)header statusCode:(NSInteger)statusCode;

@end
