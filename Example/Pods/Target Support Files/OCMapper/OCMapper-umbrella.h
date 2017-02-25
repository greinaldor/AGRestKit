#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "ObjectMapper.h"
#import "ObjectMappingInfo.h"
#import "OCMapper.h"
#import "NSDictionary+ObjectMapper.h"
#import "NSObject+ObjectMapper.h"
#import "CommonLoggingProvider.h"
#import "LoggingProvider.h"
#import "InstanceProvider.h"
#import "ManagedObjectInstanceProvider.h"
#import "ObjectInstanceProvider.h"
#import "MappingProvider.h"
#import "InCodeMappingProvider.h"

FOUNDATION_EXPORT double OCMapperVersionNumber;
FOUNDATION_EXPORT const unsigned char OCMapperVersionString[];

