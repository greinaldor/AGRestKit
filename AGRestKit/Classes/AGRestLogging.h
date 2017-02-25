//
//  AGRestLogging.h
//  AGRestStack
//
//  Created by Adrien Greiner on 28/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AGRestConstants.h"

/*!
 @protocol AGRestLogging
 @discussion The AGRestLoggin protocol defines base methods for logging any warnings, errors, crash that could occurs
 internally.
 */
@protocol AGRestLogging <NSObject>

/*!
 @abstract Set the global logLevel
 @param level Logging level
 */
- (void)setLogLevel:(AGRestLoggingLevel)level;

/*!
 @abstract Log message on TTY with given AGRestLoggingLevel.
 @param logLevel AGRestLoggingLevel describing the log level.
 @param message     Message format.
 @param ...         Message parameters list.
 */
- (void)log:(AGRestLoggingLevel)logLevel message:(NSString *)message, ... NS_FORMAT_FUNCTION(2, 3);

@end
