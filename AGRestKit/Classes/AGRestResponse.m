//
//  AGRestResponse.m
//  AGRestStack
//
//  Created by Adrien Greiner on 18/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestResponse.h"

#import "AGRestConstants.h"
#import "AGRest.h"
#import "AGRestResponseSerializerProtocol.h"

#define kHTTPResponseContentType        @"Content-Type"
#define kHTTPResponseContentEncoding    @"Content-Encoding"
#define kHTTPResponseLastModified       @"Last-Modified"

@interface AGRestResponse() {
    NSString *_contentType;
    NSString *_contentEncoding;
    NSString *_contentString;
    NSDate   *_lastModified;
    NSDate   *_date;
}

@property (strong) NSDictionary     *header_;
@property (assign) NSInteger        statusCode_;

@end

@implementation AGRestResponse

- (void)dealloc {
}

#pragma mark - Initialize
#pragma mark -

+ (nullable instancetype)responseWithError:(NSError *)error {
    return [AGRestResponse responseWithError:error statusCode:-1];
}

+ (nullable instancetype)responseWithError:(nonnull NSError *)error statusCode:(NSInteger)statusCode
{
    if (error) {
        AGRestResponse  *response = [[AGRestResponse alloc] init];
        response.responseError = error;
        response.statusCode_ = statusCode;
        return response;
    }
    return nil;
}

+ (nullable instancetype)responseWithData:(nullable id)data header:(nullable NSDictionary *)header
{
    return [AGRestResponse responseWithData:data header:header statusCode:-1];
}

+ (nullable instancetype)responseWithData:(nullable id)data header:(nullable NSDictionary *)header statusCode:(NSInteger)statusCode
{
    AGRestResponse *response = [[AGRestResponse alloc] init];
    response.responseData = data;
    response.header_ = [NSDictionary dictionaryWithDictionary:header];
    response.statusCode_ = statusCode;
    return response;
}

#pragma mark - Response Status
#pragma mark -

- (BOOL)succeeded
{
    return (self.responseError)?NO:YES;
}

- (BOOL)cancelled
{
    if (self.responseError && self.responseError.code == NSURLErrorCancelled) {
        return YES;
    }
    return NO;
}

- (NSInteger)httpStatusCode
{
    return self.statusCode_;
}

#pragma mark - HTTP Response
#pragma mark -

- (nullable NSDictionary *)responseHeader
{
    return self.header_;
}

- (nullable NSString *)contentString {
    NSString *contentString = nil;
    if (self.header_ && self.responseData)
    {
        if ([self.responseData isKindOfClass:[NSString class]]) {
            contentString = [NSString stringWithString:self.responseData];
        } else {
            BOOL lossy = NO;
            [NSString stringEncodingForData:self.responseData
                            encodingOptions:nil
                            convertedString:&contentString
                        usedLossyConversion:&lossy];
            if (!contentString) {
                // Execute the response serializer block
                if ([[AGRest responseSerializer] objectFromResponseSerializeBlock]) {
                    contentString = (NSString *)[[AGRest responseSerializer] objectFromResponseSerializeBlock](self);
                }
            }
        }
        if ([contentString isKindOfClass:[NSString class]]) {
            _contentString = contentString;
        }
    }
    return contentString;
}

- (nullable NSString *)contentType {
    if (self.header_) {
        if (!_contentType) {
            [self.header_ enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([[key lowercaseString] isEqualToString:[kHTTPResponseContentType lowercaseString]]) {
                    _contentType = [NSString stringWithString:obj];
                    *stop = YES;
                }
            }];
        }
    }
    return _contentType;
}

- (nullable NSString *)contentEncoding {
    if (self.header_) {
        if (!_contentEncoding) {
            [self.header_ enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([[key lowercaseString] isEqualToString:[kHTTPResponseContentEncoding lowercaseString]]) {
                    _contentEncoding = [NSString stringWithString:obj];
                    *stop = YES;
                }
            }];
        }
    }
    return _contentEncoding;
}

- (nullable NSDate *)lastModified {
    if (self.header_) {
        if (!_lastModified) {
            [self.header_ enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([[key lowercaseString] isEqualToString:[kHTTPResponseLastModified lowercaseString]]) {
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:kHTTPTimestampFormat];
                    [dateFormatter setLenient:YES];
                    _lastModified = [dateFormatter dateFromString:obj];
                    *stop = YES;
                }
            }];
        }
    }
    return _lastModified;
}

@end
