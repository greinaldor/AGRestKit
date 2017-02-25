//
//  AGRestResponseSerializer.m
//  AGRestStack
//
//  Created by Adrien Greiner on 25/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestResponseSerializer.h"

#import "AGRestResponse.h"
#import "AGRestObjectMapper.h"
#import "AGRestErrorUtilities.h"
#import "AGRestLogger.h"
#import "AGRestManager.h"

@interface AGRestResponseSerializer()

@property (nonatomic, weak) id<AGRestObjectMapperProvider> dataSource;

@end

@implementation AGRestResponseSerializer

@synthesize dataSource=_dataSource;

#pragma mark - AGRestModule Protocol
#pragma mark -

- (instancetype)initWithDataSource:(id<AGRestObjectMapperProvider>)dataSource {
    self = [super init];
    if (!self) return nil;
    
    _dataSource = dataSource;
    return self;
}

#pragma mark - AGRestResponseSerializer
#pragma mark -

- (id)objectResponseFromResponse:(AGRestResponse *)response {
    // If custom response serialize block is defined then use it instead.
    if (self.objectFromResponseSerializeBlock) {
        return self.objectFromResponseSerializeBlock(response);
    }
    // or use the built-in parseResponse
    return [self _parseResponse:response];
}

- (NSError *)errorResponseFromResponse:(nonnull AGRestResponse *)response {
    // If custom error serialize block is defined then use it instead.
    if (self.errorFromResponseSerializeBlock) {
        return self.errorFromResponseSerializeBlock(response);
    }
    // or use the built-in parseReponse
    return [self _parseResponse:response];
}

#pragma mark - Parse Responses
#pragma mark -

- (id)_parseResponse:(AGRestResponse *)response {
    id result = nil;
    @autoreleasepool {
        // If data and no error
        if (response.responseData && !response.responseError)
        {
            if ([response.responseData isKindOfClass:[NSDictionary class]]) {
                NSError *error = nil;
                if (!(result = [self _objectFromResponse:response error:&error])) {
                    response.responseError = error;
                }
            } else {
                AGRestLogWarn(@"<ResponseSerializer> Response data is not processed : %@", response.responseData);
            }
        }
        // If data and error
        else if (response.responseData && response.responseError)
        {
            if ([response.responseData isKindOfClass:[NSDictionary class]]) {
                result = [self _errorFromResponse:response];
            } else {
                result = response.responseError;
            }
        }
        else {
            result = response.responseError;
            AGRestLogWarn(@"<ResponseSerializer> No response data or response error found to serialize");
        }
    }
    return result;
}

- (id)_objectFromResponse:(AGRestResponse *)response error:(NSError * __autoreleasing *)error {
    if (response.responseData && response.responseHeader)
    {
        // The object to return
        id object = nil;
        
        // Get the dictionary from the response data
        NSDictionary    *data = [response responseData];
        
        Class targetClass = nil;
        if (response.targetClass)
        {
            // Get the class from the response targetClass
            if (!(targetClass = response.targetClass) && error) {
                NSString *message = [NSString stringWithFormat:@"<ResponseSerializer> Can't find any class uri from response header : %@", response.responseHeader];
                *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal
                                                     message:message];
            }
        }
        else
        {
            // Get the class from the response response header
            NSString *classURI = [self _classURIFromResponseHeader:response.responseHeader];
            targetClass = [self.dataSource.objectMapper classForClassURI:classURI];
            if (!targetClass && error) {
                NSString *message = [NSString stringWithFormat:@"<ResponseSerializer> Can't find any registered class from class uri : %@", classURI];
                *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal
                                                     message:message];
            }
        }
        
        // If a class has be found then map response data into instance of class.
        if (targetClass && !(*error)) {
            NSError *err = (error)?*error:nil;
            // Finally return the mapped object of registered class from the source dictionary.
            object = [self.dataSource.objectMapper objectFromSource:data
                                                  toInstanceOfClass:targetClass
                                                              error:&err];
        }
        return object;
    } else if (error) {
        *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal
                                             message:@"<ResponseSerializer> Response is invalid : no data / header found"];
    }
    return nil;
}

- (NSError *)_errorFromResponse:(AGRestResponse *)response {
    return response.responseError;
}

- (NSString *)_classURIFromResponseHeader:(NSDictionary *)header {
    if (header && header.count) {
        NSString *classURI = nil;
        
        // Get the Content-Type from the header
        NSString *contentType = header[@"Content-Type"];
        contentType = [contentType componentsSeparatedByString:@";"].firstObject;
        contentType = [contentType componentsSeparatedByString:@"."].lastObject;
        if (contentType && contentType.length) {
            NSArray *components = [contentType componentsSeparatedByString:@"+"];
            if (components && components.count == 2) {
                classURI = [components firstObject];
            } else {
                AGRestLogWarn(@"<ResponseSerializer> Failed to match any class+json in header field content-type : %@", contentType);
            }
            contentType = nil;
            components = nil;
            
        } else {
            AGRestLogWarn(@"<ResponseSerializer> Failed to match any class+json in header field content-type : %@", contentType);
        }
        return classURI;
    }
    return nil;
}

@end
