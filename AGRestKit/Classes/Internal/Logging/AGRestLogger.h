//
//  AGRestLogger.h
//  AGRestStack
//
//  Created by Adrien Greiner on 28/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CocoaLumberjack/DDLogMacros.h>

#import "AGRestLogging.h"
#import "AGRest_Private.h"
#import "AGRestManager.h"

#ifdef DEBUG
static int ddLogLevel = DDLogLevelVerbose;
#else
static int ddLogLevel = DDLogLevelError;
#endif

#define AGRestLog(level, format, ...)  \
    do { if (level && format) [[AGRest _currentManager].logger log:level message:(format), ##__VA_ARGS__]; } while (0)

#define AGRestLogWarn(format, ...)     AGRestLog(AGRestLoggingLevelWarning, format, ##__VA_ARGS__)
#define AGRestLogInfo(format, ...)     AGRestLog(AGRestLoggingLevelInfo,    format, ##__VA_ARGS__)
#define AGRestLogError(format, ...)    AGRestLog(AGRestLoggingLevelError,   format, ##__VA_ARGS__)
#define AGRestLogCrash(format, ...)    AGRestLog(AGRestLoggingLevelCrash,   format, ##__VA_ARGS__)

/*!
    @class AGRestLogger
 
    @discussion Default singleton logger conforming to protocol AGRestLogging.
    AGRestLogger uses CocoaLumberjack as a base logger.
 */
@interface AGRestLogger : NSObject <AGRestLogging>

/*!
 @return Shared instance of AGRestLogger.
 */
+ (instancetype)sharedLogger;

- (void)log:(AGRestLoggingLevel)logLevel message:(NSString *)message, ... NS_FORMAT_FUNCTION(2,3);

@end
