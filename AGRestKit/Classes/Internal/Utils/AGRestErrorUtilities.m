//
//  AGRestErrorUtilities.m
//  AGRestStack
//
//  Created by Adrien Greiner on 21/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <CocoaLumberjack/CocoaLumberjack.h>

#import "AGRestErrorUtilities.h"

#import "AGRestConstants.h"
#import "AGRestLogger.h"

@implementation AGRestErrorUtilities

+ (nullable NSError *)errorWithCode:(NSInteger)code message:(nullable NSString *)message
{
    return [self errorWithCode:code message:message shouldLog:YES];
}

+ (nullable NSError *)errorWithCode:(NSInteger)code message:(NSString *)message underlyingError:(NSError *)error {
    NSDictionary *result = @{ @"code" : @(code),
                              @"error" : message };
    return [self errorFromResult:result underlyingError:error shouldLog:NO];
}

+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message shouldLog:(BOOL)shouldLog {
    NSDictionary *result = @{ @"code" : @(code),
                              @"error" : message };
    return [self errorFromResult:result shouldLog:shouldLog];
}

+ (NSError *)errorFromResult:(NSDictionary *)result {
    return [self errorFromResult:result shouldLog:YES];
}

+ (NSError *)errorFromResult:(NSDictionary *)result shouldLog:(BOOL)shouldLog
{
    return [self errorFromResult:result underlyingError:nil shouldLog:shouldLog];
}

+ (NSError *)errorFromResult:(NSDictionary *)result underlyingError:(NSError *)error shouldLog:(BOOL)shouldLog
{
    NSInteger errorCode = [[result objectForKey:@"code"] integerValue];
    NSString *errorExplanation = [result objectForKey:@"error"];
    
    if (shouldLog) {
        AGRestLogError(@"%@ (code: %ld, version: %@)",errorExplanation,(long)errorCode,[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:result];
    if (errorExplanation) {
        userInfo[NSLocalizedDescriptionKey] = errorExplanation;
    }
    if (error) {
        userInfo[NSUnderlyingErrorKey] = error;
    }
    return [NSError errorWithDomain:AGRestErrorDomain code:errorCode userInfo:userInfo];
}

@end
