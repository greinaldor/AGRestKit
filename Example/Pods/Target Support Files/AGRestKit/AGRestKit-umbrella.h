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

#import "AGRestConstants.h"
#import "AGRestKeyValueCaching.h"
#import "AGRestKit.h"
#import "AGRestLogging.h"
#import "AGRestManager.h"
#import "AGRestModule.h"
#import "AGRestObjectMapperProtocol.h"
#import "AGRestObjectMapping.h"
#import "AGRestRequest+Format.h"
#import "AGRestRequest.h"
#import "AGRestRequestRunning.h"
#import "AGRestResponse.h"
#import "AGRestResponseSerializerProtocol.h"
#import "AGRestServerProtocol.h"
#import "AGRestSessionController.h"
#import "AGRestSessionProtocol.h"
#import "AGUserSessionProtocol.h"
#import "AGRestEventuallyQueue.h"
#import "AGRestEventuallyQueue_Private.h"
#import "AGRestKeyValueCache.h"
#import "AGRestRequestCache.h"
#import "AGRestTaskQueue.h"
#import "AGRestCoreDataCacheController.h"
#import "AGRestCachable.h"
#import "AGRestManager.h"
#import "AGRestCore.h"
#import "AGRestDataProvider.h"
#import "AGRest_Private.h"
#import "BFTask+Private.h"
#import "AGRestFileLock.h"
#import "AGRestFileLockController.h"
#import "AGRestFileManager.h"
#import "AGRestLogger.h"
#import "AGRestServer.h"
#import "AFHTTPSessionOperation.h"
#import "AGRestConcurrentOperation.h"
#import "AGRestReachabilityManager.h"
#import "AGRestRequest_Private.h"
#import "AGRestCachedRequestController.h"
#import "AGRestRequestController.h"
#import "AGRestRequestRunner.h"
#import "AGRestObjectMapper.h"
#import "AGRestResponseSerializer.h"
#import "AGRestSessionStore.h"
#import "AGRestErrorUtilities.h"

FOUNDATION_EXPORT double AGRestKitVersionNumber;
FOUNDATION_EXPORT const unsigned char AGRestKitVersionString[];

