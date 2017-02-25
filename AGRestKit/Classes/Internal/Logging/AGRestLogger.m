//
//  AGRestLogger.m
//  AGRestStack
//
//  Created by Adrien Greiner on 28/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestLogger.h"

#import <CocoaLumberjack/CocoaLumberjack.h>

#import "AGRestManager.h"

@interface AGRestLogger() {
    AGRestLoggingLevel _logLevel;
}

@end

@implementation AGRestLogger

+ (void)initialize {
    // Activate XCode Colors
    setenv("XcodeColors", "YES", 0);
    
    UIColor *bgColor = [UIColor colorWithRed:0.f green:26.f/255.f blue:51.f/255.f alpha:0.0];
    UIColor *redColor = [UIColor colorWithRed:214.f/255.f green:0 blue:0 alpha:0.5];
    UIColor *greenColor = [UIColor colorWithRed:51.f/255.f green:153.f/255.f blue:0 alpha:1];
    
    // Setup Cocoalumberjack
    DDTTYLogger *ttyLoger = [DDTTYLogger sharedInstance];
    ttyLoger.colorsEnabled = YES;
    // Error color
    [ttyLoger setForegroundColor:redColor
                 backgroundColor:bgColor
                         forFlag:DDLogFlagError];
    // Warning color
    [ttyLoger setForegroundColor:[[UIColor orangeColor] colorWithAlphaComponent:0.7]
                 backgroundColor:bgColor
                         forFlag:DDLogFlagWarning];
    // Verbose color
    [ttyLoger setForegroundColor:greenColor
                 backgroundColor:bgColor
                         forFlag:DDLogFlagVerbose|DDLogFlagInfo];
    
    [DDLog addLogger:ttyLoger];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logLevel = AGRestLoggingLevelCrash;
    }
    return self;
}

+ (instancetype)sharedLogger {
    static AGRestLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[AGRestLogger alloc] init];
    });
    return logger;
}

- (void)setLogLevel:(AGRestLoggingLevel)level {
    _logLevel = level;
}

- (void)log:(AGRestLoggingLevel)logLevel message:(NSString *)message, ...
{
    if (_logLevel >= logLevel)
    {
        va_list ap;
        va_start(ap, message);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-security"
        switch (logLevel) {
            case AGRestLoggingLevelNone:    /* Do nothing*/          break;
            case AGRestLoggingLevelInfo:    { [self ddlog:DDLogLevelInfo    flag:DDLogFlagInfo format:message args:ap]; } break;
            case AGRestLoggingLevelDebug:   { [self ddlog:DDLogLevelDebug   flag:DDLogFlagDebug format:message args:ap]; } break;
            case AGRestLoggingLevelCrash:
            case AGRestLoggingLevelError:   { [self ddlog:DDLogLevelError   flag:DDLogFlagError format:message args:ap]; } break;
            case AGRestLoggingLevelWarning: { [self ddlog:DDLogLevelWarning flag:DDLogFlagWarning format:message args:ap]; } break;
            default: break;
        }
#pragma cland diagnostic pop
        va_end(ap);
    }
}

- (void)ddlog:(NSUInteger)level flag:(NSUInteger)flag format:(NSString *)format args:(va_list)args
{
    [DDLog log:YES
         level:level
          flag:flag
       context:0
           file:__FILE__
      function:__FUNCTION__
          line:__LINE__
           tag:nil
        format:format
          args:args];
}

@end
