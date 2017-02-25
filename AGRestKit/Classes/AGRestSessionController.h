//
//  AGRestSessionManager.h
//  AGRestStack
//
//  Created by Adrien Greiner on 22/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AGRestConstants.h"
#import "AGRestSessionProtocol.h"

/*!
 @class AGRestSessionController
 */
@interface AGRestSessionController : NSObject <AGRestSessionProtocol>

@property (strong, nullable) NSString   * baseUrl;
@property (strong, nullable) NSString   * logInEndPoint;
@property (strong, nullable) NSString   * logOutEndPoint;
@property (strong, nullable) NSString   * resetPwdEndPoint;

@property (strong, nonnull) NSString    * templateKeyEmailLogin;
@property (strong, nonnull) NSString    * templateKeyPasswordLogin;
@property (strong, nonnull) NSString    * templateKeyEmailResetPassword;
@property (strong, nonnull) NSString    * templateTokenExtractionKey;

@property (unsafe_unretained, nonnull, setter=setBaseUserClass:) Class<AGRestObjectMapping> baseUserClass;

- (nullable instancetype)initWithDataSource:(nonnull id<AGRestCoreManagerDataSource>)dataSource
                                withBaseUrl:(nonnull NSString *)baseUrl;

- (nullable instancetype)initWithBaseUrl:(nullable NSString *)baseUrl
                           loginEndPoint:(nullable NSString *)logInEndPoint
                          logOutEndPoint:(nullable NSString *)logOutEndPoint
            requestResetPasswordEndPoint:(nullable NSString *)resetPwdEndPoint;

- (nullable id<AGRestObjectMapping>)getCurrentUser;

- (void)logInCurrentUserWithSessionToken:(nonnull NSString *)sessionToken
                                   email:(nonnull NSString *)email
                                    user:(nonnull id<AGRestObjectMapping>)user
                              completion:(void (^ _Nullable)(BOOL succeeded, NSError * _Nullable error))block;

- (void)logInCurrentUserWithEmail:(nonnull NSString *)email
                         password:(nonnull NSString *)password
                 revocableSession:(BOOL)revocableSession
                       completion:( void (^ _Nullable )(BOOL succeeded, AGRestResponse * _Nullable response))block;

- (void)logOutCurrentUserWithCompletion:(void (^ _Nullable)(BOOL succeeded, AGRestResponse * _Nullable response))block;

- (void)requestResetPasswordForEmail:(nonnull NSString *)email
                          completion:(void (^ _Nullable)(BOOL succeeded, AGRestResponse * _Nullable object))block;

@end
