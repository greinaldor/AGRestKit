//
//  AGRestConstants.h
//  AGRestStack
//
//  Created by Adrien Greiner on 18/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Macro Definitions

#define weakify(instance)           __weak typeof(instance) weakSelf = instance;
#define strongify(instance)         __strong typeof(instance) strongSelf = weakSelf;

#define dispatch_async_block1(block, arg1) if (block) { dispatch_async(dispatch_get_main_queue(), ^{block(arg1);}); }
#define dispatch_async_block2(block, arg1, arg2) if (block) { dispatch_async(dispatch_get_main_queue(), ^{block(arg1, arg2);}); }

#define kHTTPTimestampFormat @"EEE, dd MMM yyyy HH:mm:ss z"

// Forward declarations

@class AGRestRequest;
@class AGRestResponse;

@protocol AGRestObjectMapping;

///-----------------------
#pragma mark - Constants String Definitions
/// @name Constants strings
///-----------------------
/*!
 *  The current SDK version.
 */
extern NSString *const _Nonnull AGRestSDKVersion;
/*!
 *  The default API base url.
 */
extern NSString *const _Nonnull AGRestAPIBaseUrl;
/*!
 *  The AGRest error domain identifier.
 */
extern NSString *const _Nonnull AGRestErrorDomain;
/*!
 *  The default session token extraction key.
 */
extern NSString *const _Nonnull AGRestSessionTokenExtractionKey;
/*!
 *  The key used to store the session token in the Keychain
 */
extern NSString *const _Nonnull AGRestSessionStoreSessionTokenKey;
/*!
 *  The key used to store the session user
 */
extern NSString *const _Nonnull AGRestSessionStoreCurrentUserKey;

///-----------------------
#pragma mark - Notification Definitions
/// @name Notifications
///-----------------------
extern NSString *const _Nonnull AGRestReachabilityStatusChanged;

///-----------------------
#pragma mark - Enum Definitions
/// @name Enums Definitions
///-----------------------
/*!
 @enum AGRestReachabilityStatus
 @discussion AGRestErrorCode enum contains all custom error codes that are used as code for NSError for callbacks on all classes.
 These codes are used when domain of NSError that you receive is set to AGRestErrorDomain.
 */
typedef NS_ENUM(NSInteger, AGRestErrorCode) {
    /*!
     @abstract Internal local error. No information available.
     */
    kAGErrorInternalLocal = -1,
    /*!
     @abstract Internal server error. No information available.
     */
    kAGErrorInternalServer = 1,
    /*!
     @abstract The server refused to respond the query.
     */
    kAGErrorServerRefused = 3,
    /*!
     @abstract Internet connection is missing
     */
    kAGErrorNoInternetConnection = 4,
    /*!
    @abstract Internet connection lost during opearation
     */
    kAGErrorInternetConnectionLost = 5,
    /*!
     @abstract The connection to the API server failed.
     */
    kAGErrorConnectionFailed = 100,
    /*!
     @abstract Object doesn't exist.
     */
    kAGErrorObjectNotFound = 101,
    /*!
     @abstract The query contains bad syntax or invalid
     */
    kAGErrorInvalidQuery = 102,
    /*!
     @abstract Missing object id.
     */
    kAGErrorMissingObjectId = 104,
    /*!
     @abstract Malformed json object. A json dictionary is expected.
     */
    kAGErrorInvalidJSON = 105,
    /*!
     @abstract Tried to access a feature only available internally.
     */
    kAGErrorOperationForbidden = 106,
    /*!
     @abstract The request timed out on the server. Typically this indicates the request is too expensive.
     */
    kAGErrorTimeout = 107,
    /*!
     @abstract The email address was invalid.
     */
    kAGErrorInvalidEmailAddress = 108,
    /*!
     @abstract The Apple server response is not valid.
     */
    kAGErrorInvalidServerResponse = 109,
    /*!
     @abstract Username is missing or empty.
     */
    kAGErrorUsernameMissing = 200,
    /*!
     @abstract Password is missing or empty.
     */
    kAGErrorUserPasswordMissing = 201,
    /*!
     @abstract Username has already been taken.
     */
    kAGErrorUsernameTaken = 202,
    /*!
     @abstract Email has already been taken.
     */
    kAGErrorUserEmailTaken = 203,
    /*!
     @abstract An existing Facebook account already linked to another user.
     */
    kAGErrorFacebookAccountAlreadyLinked = 204,
    /*!
     @abstract An existing account already linked to another user.
     */
    kAGErrorAccountAlreadyLinked = 205,
    /*!
     @abstract Error code indicating that the current session token is invalid.
     */
    kAGErrorInvalidSessionToken = 206,
    /*!
     @abstract Invalid Facebook session.
     */
    kAGErrorFacebookInvalidSession = 207,
    /*!
     @abstract Invalid linked session.
     */
    kAGErrorInvalidLinkedSession = 208,
    /*!
     @abstract Authentication failed with email / password
     */
    kAGErrorAuthBadCredentials = 209,
    /*!
     @abstract Unknown error
     */
    kAGErrorUnknown = 666
};

/*!
 @enum AGRestRequestHTTPMethod
 @discussion AGRestRequestHTTPMethod enum contains all supported HTTP methods.
 */
typedef NS_ENUM(uint8_t, AGRestRequestHTTPMethod) {
    /*!
     @abstract HTTP POST METHOD
     */
    AGRestRequestMethodHttpPOST     = 1,
    /*!
     @abstract HTTP GET METHOD
     */
    AGRestRequestMethodHttpGET      ,
    /*!
     @abstract HTTP PUT METHOD
     */
    AGRestRequestMethodHttpPUT      ,
    /*!
     @abstract HTTP DELETE METHOD
     */
    AGRestRequestMethodHttpDELETE   ,
    /*!
     @abstract HTTP HEAD METHOD
     */
    AGRestRequestMethodHttpHEAD     ,
    /*!
     @abstract HTTP PATCH METHOD
     */
    AGRestREquestMethodHttpPATCH
};

/*!
 @enum AGRestLoggingLevel
 @discussion AGRestLogginLevel enum contains all supported log level.
 */
typedef NS_ENUM(uint8_t, AGRestLoggingLevel) {
    /*!
    @abstract Don't log anything
     */
    AGRestLoggingLevelNone,
    /*!
    @abstract Log info message
     */
    AGRestLoggingLevelInfo,
    /*!
    @abstract Log debug message.
     */
    AGRestLoggingLevelDebug,
    /*!
    @abstract Log Warning message.
     */
    AGRestLoggingLevelWarning,
    /*!
    @abstract Log Error message.
     */
    AGRestLoggingLevelError,
    /*!
    @abstract Log Crash dump info.
     */
    AGRestLoggingLevelCrash
};

/*!
 @enum AGRestReachabilityStatus
 @discussion AGRestReachabilityStatus lists all mobile reachability status supported by AGRestSDK.
 */
typedef NS_ENUM(NSUInteger, AGRestReachabilityStatus) {
    /*!
     @abstract Not reachable.
     */
    AGRestReachabilityStatusNotReachable,
    /*!
     @abstract Reachable via Edge, 2G, 3G, 4G
     */
    AGRestReachabilityStatusReachableViaWan,
    /*!
     @abstract Reachable via Wifi.
     */
    AGRestReachabilityStatusReachableVieWifi,
    /*!
     @abstract Unknow reachability status. Occured when connection broke and cell is searching for Carrier.
     */
    AGRestReachabilityStatusUnknown
};

///-----------------------
#pragma mark - Block Definitions
/// @name Block Definitions
///-----------------------

/*!
 @abstract Block returning fetch request's result with AGRestResponse instance.
 @param response AGRestResponse returned from fetch request operation.
 */
typedef void (^AGRestRequestResultBlock)(AGRestResponse * _Nonnull response);
/*!
 @abstract Block returning batch request's results with NSArray of AGRestResponse instances.
 @param responses NSArray of AGRestResponse.
 */
typedef void (^AGRestBatchResponseCompletionBlock)(NSArray * _Nonnull responses);
/*!
 @abstract Block returning when a AGRestRequest timed out.
 @param request     AGRestRequest The timed out request.
 @return Boolean value indicating wether the request should retry or stop.
 */
typedef BOOL (^AGRestRequestTimeoutCompletionBlock)(AGRestRequest * _Nullable request);
/*!
 @abstract Block returning a boolean value representing success of an operation and an NSError if occured.
 @param succeeded   BOOL indicating success.
 @param error       NSError defined if occured.
 */
typedef void (^AGRestBooleanCompletionBlock)(BOOL succeeded, NSError * _Nullable error);
/*!
 @abstract Block returning an instance of an object conformimg to AGRestObjectMapping, an NSError if occured.
 @param object  An instance of a mapped object conforming to AGRestObjectMapping.
 @param error   NSError defined if occured
 */
typedef void (^AGRestObjectCompletionBlock)(id<AGRestObjectMapping> _Nullable object, NSError * _Nullable error);


