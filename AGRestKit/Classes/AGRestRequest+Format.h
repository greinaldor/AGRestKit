//
//  AGRestRequest+AGRestRequest_Format.h
//  Pods
//
//  Created by Adrien Greiner on 02/11/2015.
//
//

#import "AGRestRequest.h"

@interface AGRestRequest (Format)

///-----------------------
#pragma mark - Format
/// @name Format
///-----------------------

/*!
 @return Returns the HTTP method of the request as a string.
 */
- (NSString *)httpMethodString;

/*!
 @return Returns the request as cURL command string.
 */
- (NSString *)cURLRequestString;

/*!
 @return Returns the request as a NSURlRequest.
 */
- (NSMutableURLRequest *)mutableUrlRequest;

@end
