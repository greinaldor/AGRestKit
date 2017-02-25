//
//  AGRestSessionManager.m
//  AGRestStack
//
//  Created by Adrien Greiner on 22/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestSessionController.h"

#import <Bolts/BFTask.h>
#import <objc/runtime.h>

#import "AGRestSessionStore.h"
#import "AGRestResponse.h"
#import "AGRestRequest.h"
#import "AGRestServer.h"
#import "AGRestObjectMapper.h"
#import "AGRestErrorUtilities.h"
#import "AGRestObjectMapping.h"
#import "AGUserSessionProtocol.h"
#import "AGRestLogger.h"
#import "AGRestCore.h"

#import "AGRest_Private.h"
#import "BFTask+Private.h"

#define kAGRestSessionControllerDefaultTemplateKeyEmail @"email"
#define kAGRestSessionControllerDefaultTemplateKeyPassword @"password"
#define kAGRestSessionControllerDefaultTemplateKeyResetPassword @"email"

@interface AGRestSessionController()

@property (strong) id<AGRestObjectMapping> currentUser_;

- (BOOL)_makeCurrentUserWithObject:(nonnull id<AGRestObjectMapping>)user
                             error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (nullable NSString *)_extractTokenFromResponse:(nonnull AGRestResponse *)response;
- (nonnull NSError *)_handleLogInErrorResponse:(nonnull AGRestResponse *)error;

@end

@implementation AGRestSessionController

@synthesize baseUserClass=_baseUserClass;
@synthesize dataSource=_dataSource;

- (instancetype)initWithDataSource:(id<AGRestCoreManagerDataSource>)dataSource {
    self = [super init];
    if (!self) return nil;
    
    // Set default session store
    self.currentUser_ = nil;
    self.templateKeyEmailLogin = kAGRestSessionControllerDefaultTemplateKeyEmail;
    self.templateKeyPasswordLogin = kAGRestSessionControllerDefaultTemplateKeyPassword;
    self.templateKeyEmailResetPassword = kAGRestSessionControllerDefaultTemplateKeyResetPassword;
    self.templateTokenExtractionKey = AGRestSessionTokenExtractionKey;
    
    self.dataSource = dataSource;
    
    return self;
}

- (nullable instancetype)initWithDataSource:(nonnull id<AGRestCoreManagerDataSource>)dataSource
                                withBaseUrl:(nonnull NSString *)baseUrl {
    if ((self = [self initWithDataSource:dataSource])) {
        self.baseUrl = baseUrl;
    }
    return self;
}

- (nullable instancetype)initWithBaseUrl:(nullable NSString *)baseUrl
                           loginEndPoint:(nullable NSString *)logInEndPoint
                          logOutEndPoint:(nullable NSString *)logOutEndPoint
            requestResetPasswordEndPoint:(nullable NSString *)resetPwdEndPoint
{
    if ((self = [self initWithDataSource:nil])) {
        self.baseUrl = baseUrl;
        self.logInEndPoint = logInEndPoint;
        self.logOutEndPoint = logOutEndPoint;
        self.resetPwdEndPoint = resetPwdEndPoint;
    }
    return self;
}

- (void)logInCurrentUserWithSessionToken:(nonnull NSString *)sessionToken
                                   email:(nonnull NSString *)email
                                    user:(nonnull id<AGRestObjectMapping>)user
                              completion:(void (^ _Nullable)(BOOL succeeded, NSError * _Nullable error))block {
    
    if (sessionToken && sessionToken.length &&
        email && email.length &&
        user && [user conformsToProtocol:@protocol(AGRestObjectMapping)]) {
        
        // Store session token
        NSError *error = nil;
        BOOL isStored = [self.dataSource.sessionStore storeSessionToken:sessionToken forIdentifier:email error:&error];
        if (isStored && !error) {
            // Update server's session token
            [self.dataSource.requestServer setValue:sessionToken forHTTPHeaderField:self.templateTokenExtractionKey];
            
            // Make user the current user
            isStored = [self _makeCurrentUserWithObject:user error:&error];
        }
        
        // Call block
        if (block) {
            block(isStored, error);
        }
    } else {
        // Bad parameters
    }
}

- (void)logInCurrentUserWithEmail:(nonnull NSString *)email
                         password:(nonnull NSString *)password
                 revocableSession:(BOOL)revocableSession
                       completion:(void (^ _Nullable)(BOOL succeeded, AGRestResponse * _Nullable response))block
{
    if (email && email.length &&
        password && password.length &&
        self.baseUrl && self.baseUrl.length &&
        self.logInEndPoint && self.logInEndPoint.length)
    {
        
        // Build the credentials dictionnary
        NSDictionary *userCredentials = @{self.templateKeyEmailLogin:email,
                                          self.templateKeyPasswordLogin:password};
        
        // Build the login AGRestRequest
        AGRestRequest   *logInRequest = [AGRestRequest POSTRequestWithUrl:self.baseUrl
                                                                 endPoint:self.logInEndPoint
                                                                     body:userCredentials];
        
        // Send login request
        weakify(self)
        [[logInRequest sendRequestInBackground] continueWithBlock:^id(BFTask *task) {
            strongify(weakSelf)
            AGRestResponse *response = (AGRestResponse *)task.result;
            if (strongSelf && response)
            {
                if (response.succeeded) {
                    
                    // Extract the session token from the response header
                    NSString *sessionToken = [strongSelf _extractTokenFromResponse:response];
                    NSError *error = nil;
                    
                    // Store session token with session store and use email as identifier
                    BOOL isStored = [strongSelf.dataSource.sessionStore storeSessionToken:sessionToken forIdentifier:email error:&error];
                    if (isStored) {
                        // Update server's session token.
                        [self.dataSource.requestServer setValue:sessionToken forHTTPHeaderField:self.templateTokenExtractionKey];
                        
                        // Make user the current user
                        id<AGRestObjectMapping> userObject = response.responseData;
                        
                        // Store current user and make it current user
                        isStored = [strongSelf _makeCurrentUserWithObject:userObject error:&error];
                    }
                    
                    if (error) {
                        response.responseError = [AGRestErrorUtilities errorWithCode:error.code
                                                                             message:error.localizedDescription
                                                                     underlyingError:response.responseError];
                    }
                    
                    // Call the block
                    if (block) block(isStored, response);
                } else if (response.cancelled) {
                    // Do not store and call the block
                    if (block) block(NO, response);
                } else {
                    // Handle the server error response
                    NSError *error = [strongSelf _handleLogInErrorResponse:response];
                    response.responseError = error;
                    // Broadcast error
                    if (block) block(NO, response);
                }
            }
            else if (!response)
            {
                if (block) block(NO, nil);
            }
            return nil;
        }];
        
    } else {
        
        // return bock with error
        NSError *error;
        if (!email || !email.length || !password || !password.length) {
            error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal message:@"Email or password are nil or empty."];
        } else if (!self.baseUrl || !self.logInEndPoint || !self.logInEndPoint.length) {
            error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal message:@"Base url or logIn endPoint are nil or empty.\
                                                                                        Check that the AGRestSessionManager are properly configured."];
        } else {
            error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal message:@"Unknown error."];
        }
        
        if (block) {
            AGRestResponse *response = [AGRestResponse responseWithError:error];
            block(NO, response);
        }
    }
}

- (void)logOutCurrentUserWithCompletion:(void (^ _Nullable)(BOOL succeeded, AGRestResponse * _Nullable response))block {
    
    AGRestRequest   *logoutRequest = [AGRestRequest DELETERequestWithUrl:self.baseUrl
                                                                endPoint:self.logOutEndPoint
                                                                    body:nil];
    [logoutRequest setObjectMappingEnabled:NO];
    weakify(self);
    [[logoutRequest sendRequestInBackground] continueWithBlock:^id(BFTask *task) {
        strongify(weakSelf);
        if (strongSelf) {
            BOOL isSucceeded = NO;
            NSError *error = nil;
            AGRestResponse *response = task.result;
            if (response.succeeded) {
                isSucceeded = [weakSelf _clearCurrentSession:&error];
                if (error) {
                    response.responseError = error;
                }
            } else {
                error = response.responseError;
            }
            
            if (block) {
                block(isSucceeded, response);
            }
        }
        return nil;
    }];
}

- (void)requestResetPasswordForEmail:(nonnull NSString *)email
                          completion:(void (^ _Nullable )(BOOL succeeded, AGRestResponse * _Nullable response))block {
    if (email && email.length) {
        
    } else if (block) {
        
    }
}

- (nullable id<AGRestObjectMapping>)getCurrentUser {
    if (!self.currentUser_) {
        self.currentUser_ = [self _loadCurrentUser];
    }
    return self.currentUser_;
}

- (void)setBaseUserClass:(Class<AGRestObjectMapping>)aClass {
    _baseUserClass = aClass;
    
    // Make sure the baseUserClass is registered
    [[self.dataSource objectMapper] registerSubclass:aClass];
    
    // Swizzling for User base class with UserSessionProtocol methods
    [self _extendUserBaseClassWithSessionProtocolImpl:aClass];
}

- (Class<AGRestObjectMapping>)baseUserClass {
    return _baseUserClass;
}

#pragma mark - Private()
#pragma mark -

- (nullable id<AGRestObjectMapping>)_loadCurrentUser {

    id<AGRestObjectMapping> currentUser = nil;
    
    // Retrieve last session token and update server with
    NSString *currentSessionToken = [self.dataSource.sessionStore sessionTokenWithIdentifier:nil];
    if (currentSessionToken)
    {
        NSData *currentUserData = [self.dataSource.sessionStore dataForIdentifier:AGRestSessionStoreCurrentUserKey];
        id object = [NSKeyedUnarchiver unarchiveObjectWithData:currentUserData];
        
        if ([object isKindOfClass:[NSDictionary class]])
        {
            // Instanciate user object to baseUserClass from source dictionary
            NSError *error = nil;
            if (self.baseUserClass) {
                currentUser = [self.dataSource.objectMapper objectFromSource:object
                                                           toInstanceOfClass:self.baseUserClass
                                                                       error:&error];
            } else {
                error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal
                                                    message:@"<SessionStore> Base user class not defined or not registered : %@"
                                                  shouldLog:NO];
            }
            
            if (error) {
                AGRestLogError(@"<SessionStore> Load current user failed : %@", error);
            }
        }
        else if ([object conformsToProtocol:@protocol(AGRestObjectMapping)] && [object isKindOfClass:self.baseUserClass])
        {
            currentUser = object;
        }
        
        // If current user has been found, update server with session token
        if (currentUser) {
            [self.dataSource.requestServer setValue:currentSessionToken forHTTPHeaderField:self.templateTokenExtractionKey];
        }
    }
    return currentUser;
}

- (BOOL)_makeCurrentUserWithObject:(nonnull id<AGRestObjectMapping>)user
                            error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    NSData *userData = nil;
    BOOL    isStored = NO;
    
    // Check user not nil and is same type of user base class
    if (user && self.baseUserClass && [user isKindOfClass:self.baseUserClass])
    {
        // Check that user is supported Class
        if ([[user class] conformsToProtocol:@protocol(AGRestObjectMapping)] && [[user class] respondsToSelector:@selector(classURI)])
        {
            // If user instance conforms to NSCoding then use KeyedArchiver
            if ([user conformsToProtocol:@protocol(NSCoding)]) {
                userData  = [NSKeyedArchiver archivedDataWithRootObject:user];
            }
            // Else try to use the objectMapper to create source dictionary and then use KeyedArchiver
            else {
                NSDictionary *userDic = [self.dataSource.objectMapper sourceFromObject:user error:error];
                if (userDic && *error == nil) {
                    userData = [NSKeyedArchiver archivedDataWithRootObject:userDic];
                }
            }
            
            // If data not nil then store data with the session store and assign current user instance with user
            if (userData && userData.length) {                
                if ((isStored = [self.dataSource.sessionStore storeData:userData forIdentifier:AGRestSessionStoreCurrentUserKey error:error])) {
                    self.currentUser_ = user;
                }
            } else if (error) {
                *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal
                                                     message:[NSString stringWithFormat:@"<SessionStore> Failed to create data from user instance :\n%@\nerror:\n%@",
                                                              user, *error]];
            }
        } else if (error) {
            *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal
                                                 message:@"<SessionStore> User instance not responding to AGObjectMapping"];
        }
    }
    else if (error)
    {
        NSString *errMessage = (!user)?@"<SessionStore> User is nil : %@":@"<SessionStore> Base user class not defined or not conforming to AGObjectMapping : %@";
        *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal
                                             message:[NSString stringWithFormat:errMessage, (!user)?user:self.baseUserClass]];
    }
    return isStored;
}

- (BOOL)_clearCurrentSession:(NSError * _Nullable __autoreleasing * _Nullable)error {
    
    // Clear session data from the store
    BOOL isSessionCleared = [self.dataSource.sessionStore resetCurrentSession:error];
    
    // Clear session token from server / currentUser
    if (isSessionCleared) {
        [self.dataSource.requestServer setValue:nil forHTTPHeaderField:self.templateTokenExtractionKey];
        self.currentUser_ = nil;
    }
    return isSessionCleared;
}

- (nullable NSString *)_extractTokenFromResponse:(nonnull AGRestResponse *)response
{
    if (response && response.responseHeader && response.responseHeader.count) {
        // Look for case-insensitive header field 'authorization'
        NSUInteger tokenIndex = [[response.responseHeader allKeys] indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [[obj lowercaseString] isEqualToString:[self.templateTokenExtractionKey lowercaseString]];
        }];
        
        if (tokenIndex != NSNotFound) {
            NSString *headerKey = [[response.responseHeader allKeys] objectAtIndex:tokenIndex];
            return [response.responseHeader objectForKey:headerKey];
        }
        
        // If not found in the header try to find the session key in the response data
        if (tokenIndex == NSNotFound && response.responseData) {
            NSDictionary *responseData = (NSDictionary *)[response responseData];
            if ([responseData isKindOfClass:[NSDictionary class]]) {
                __block NSString *sessionToken = nil;
                [responseData enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    if ([[key lowercaseString] isEqualToString:[self.templateTokenExtractionKey lowercaseString]]) {
                        sessionToken = [NSString stringWithString:obj];
                        *stop = YES;
                    }
                }];
            }
        }
    }
    return nil;
}

- (nonnull NSError *)_handleLogInErrorResponse:(nonnull AGRestResponse *)response {
    NSError *error = nil;
    NSMutableDictionary *errorDict = [NSMutableDictionary dictionary];
    
    if (response.responseError) {
        errorDict[NSUnderlyingErrorKey] = response.responseError;
    }
    
    if (response && response.httpStatusCode)
    {
        switch (response.httpStatusCode) {
            case 400:
                [errorDict addEntriesFromDictionary:@{@"code":@(kAGErrorInvalidQuery),
                                                      @"error":@"Login failed: Request not recognized or bad syntax."}];
                break;
            case 403:
                [errorDict addEntriesFromDictionary:@{@"code":@(kAGErrorServerRefused),
                                                      @"error":@"Login failed: The server refused the request."}];
                break;
            case 404:
                [errorDict addEntriesFromDictionary:@{@"code":@(kAGErrorAuthBadCredentials),
                                                      @"error":@"Login failed: The email or password is invalid."}];
                break;
            case 500:
                [errorDict addEntriesFromDictionary:@{@"code":@(kAGErrorInternalServer),
                                                      @"error":@"Login failed: Internal server error."}];
                break;
            default:
                [errorDict addEntriesFromDictionary:@{@"code":@(kAGErrorUnknown),
                                                      @"error":@"Unknown error."}];
                break;
        }
    }
    else if (response.responseError)
    {
        switch (response.responseError.code)
        {
            case NSURLErrorNotConnectedToInternet:
                [errorDict addEntriesFromDictionary:@{@"code":@(kAGErrorNoInternetConnection),
                                                      @"error":@"Login failed: No internet connection."}];
                break;
            case NSURLErrorNetworkConnectionLost:
                [errorDict addEntriesFromDictionary:@{@"code":@(kAGErrorInternetConnectionLost),
                                                      @"error":@"Login failed: Connection lost."}];
                break;
            default: {
                [errorDict addEntriesFromDictionary:@{@"code":@(kAGErrorUnknown),
                                                      @"error":@"Unknown error."}];
            } break;
        }
    }
    else {
        [errorDict addEntriesFromDictionary:@{@"code":@(kAGErrorUnknown),
                                              @"error":@"Unknown error."}];
    }
    error = [AGRestErrorUtilities errorFromResult:errorDict];
    return error;
}

- (void)_extendUserBaseClassWithSessionProtocolImpl:(nonnull Class __unsafe_unretained)userBaseClass {
    // Check if the User base class asks to support AGUserSessionProtocol
    if ([(Class)_baseUserClass conformsToProtocol:@protocol(AGUserSessionProtocol)])
    {
        // Then add default implementation UserSessionProtocol methods
        Class metaClass = object_getClass(_baseUserClass);
        
        if (![metaClass instancesRespondToSelector:@selector(currentUser)]) {
            if (!class_addMethod(metaClass, @selector(currentUser), (IMP)_swizzle_currentUser, "@v:")) {
                AGRestLogWarn(@"<AGRestSessionManager> Failed to add method : +currentUser");
            }
        }
        if (![metaClass instancesRespondToSelector:@selector(logInWithEmail:password:)]) {
            if (!class_addMethod(metaClass, @selector(logInWithEmail:password:), (IMP)_swizzle_logInWithEmailPassword, "@v:@@")) {
                AGRestLogWarn(@"<AGRestSessionManager> Failed to add method : +logInWithEmail:password:");
            }
        }
        if (![metaClass instancesRespondToSelector:@selector(logInWithEmail:password:error:)]) {
            if (!class_addMethod(metaClass, @selector(logInWithEmail:password:error:), (IMP)_swizzle_logInWithEmailPassword_error, "@v:@@^@")) {
                AGRestLogWarn(@"<AGRestSessionManager> Failed to add method : +logInWithEmail:password:error:");
            }
        }
        if (![metaClass instancesRespondToSelector:@selector(logInWithEmailInBackground:password:resultBlock:)]) {
            if (!class_addMethod(metaClass, @selector(logInWithEmailInBackground:password:resultBlock:),
                                 (IMP)_swizzle_logInWithEmailPasswordInBackground_block, "v@:@@^@")) {
                AGRestLogWarn(@"<AGRestSessionManager> Failed to add method : +logInWithEmailInBackground:password:resultBlock:");
            }
        }
        if (![metaClass instancesRespondToSelector:@selector(logInWithEmailInBackground:password:target:selector:)]) {
            if (!class_addMethod(metaClass, @selector(logInWithEmailInBackground:password:target:selector:),
                                 (IMP)_swizzle_logInWithEmailPasswordInBackground_target, "v@:@@@:")) {
                AGRestLogWarn(@"<AGRestSessionManager> Failed to add method : +logInWithEmailInBackground:password:target:selector:");
            }
        }
        if (![metaClass instancesRespondToSelector:@selector(logOutCurrentUser)]) {
            if (!class_addMethod(metaClass, @selector(logOutCurrentUser), (IMP)_swizzle_logOutCurrentUser, "B")) {
                AGRestLogWarn(@"<AGRestSessionManager> Failed to add method : +logOutCurrentUser");
            }
        }
        if (![metaClass instancesRespondToSelector:@selector(logOutCurrentUser:)]) {
            if (!class_addMethod(metaClass, @selector(logOutCurrentUser:), (IMP)_swizzle_logOutCurrentUser_error, "B")) {
                AGRestLogWarn(@"<AGRestSessionManager> Failed to add method : +logOutCurrentUser:");
            }
        }
        if (![metaClass instancesRespondToSelector:@selector(logOutCurrentUserInBackground:)]) {
            if (!class_addMethod(metaClass, @selector(logOutCurrentUserInBackground:), (IMP)_swizzle_logOutCurrentUserInBackground, "vB^@")) {
                AGRestLogWarn(@"<AGRestSessionManager> Failed to add method : +logOutCurrentUserInBackground:");
            }
        }
    }
}

#pragma mark - AGUserSessionProtocol Methods Swizzling
#pragma mark -


id<AGRestObjectMapping> _swizzle_currentUser(id self, SEL _cmd) {
    return [[AGRest _currentManager].sessionController getCurrentUser];
}

id<AGRestObjectMapping> _swizzle_logInWithEmailPassword(id self, SEL _cmd, NSString *email, NSString *password) {
    return _swizzle_logInWithEmailPassword_error(self, _cmd, email, password, nil);
}

id<AGRestObjectMapping> _swizzle_logInWithEmailPassword_error(id self, SEL _cmd, NSString *email, NSString *password, NSError ** error) {
    __weak __block id<AGRestObjectMapping> user = nil;
    __weak __block NSError *anError = nil;
    BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];
    [[AGRest _currentManager].sessionController logInCurrentUserWithEmail:email
                                                                 password:password
                                                         revocableSession:NO
                                                               completion:^(BOOL succeeded, AGRestResponse * _Nullable response)
     {
         user = response.responseData;
         if (!succeeded) {
             anError = response.responseError;
             *error = anError;
         }
         [taskCompletion setResult:response];
     }];
    // Block the current thread before returning
    [taskCompletion.task waitUntilFinished];
    return user;
}

void _swizzle_logInWithEmailPasswordInBackground_target(id self, SEL _cmd, NSString *email, NSString *password, id target, SEL selector)
{
    [[AGRest _currentManager].sessionController logInCurrentUserWithEmail:email
                                                                 password:password
                                                         revocableSession:NO
                                                               completion:^(BOOL succeeded, AGRestResponse * _Nullable response)
     {
         if (target && [target respondsToSelector:@selector(performSelectorOnMainThread:withObject:waitUntilDone:)])
         {
             [target performSelectorOnMainThread:selector
                                      withObject:response
                                   waitUntilDone:YES];
         }
     }];
}

void _swizzle_logInWithEmailPasswordInBackground_block(id self, SEL _cmd, NSString *email, NSString *password, AGRestObjectCompletionBlock block) {
    [[AGRest _currentManager].sessionController logInCurrentUserWithEmail:email
                                                                 password:password
                                                         revocableSession:NO
                                                               completion:^(BOOL succeeded, AGRestResponse * _Nullable response)
     {
         dispatch_async_block2(block, response.responseData, response.responseError);
     }];
}

BOOL _swizzle_logOutCurrentUser() {
    return _swizzle_logOutCurrentUser_error(nil);
}

BOOL _swizzle_logOutCurrentUser_error(NSError * __autoreleasing * error) {
    __block BOOL ret = NO;
    __weak __block NSError *anError = nil;
    BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];
    [[AGRest _currentManager].sessionController logOutCurrentUserWithCompletion:^(BOOL succeeded, AGRestResponse * _Nullable response) {
        ret = succeeded;
        if (!succeeded) {
            anError = response.responseError;
            if (error) {
                *error = anError;
            }
        }
        [taskCompletion setResult:@(succeeded)];
    }];
    // Block the current thread before returning
    [taskCompletion.task waitUntilFinished];
    return ret;
}

void _swizzle_logOutCurrentUserInBackground(AGRestBooleanCompletionBlock block) {
    [[AGRest _currentManager].sessionController logOutCurrentUserWithCompletion:^(BOOL succeeded, AGRestResponse * _Nullable response) {
        dispatch_async_block2(block, succeeded, response.responseError);
    }];
}

@end
