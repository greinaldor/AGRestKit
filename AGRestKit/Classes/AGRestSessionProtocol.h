//
//  AGRestSessionProtocol.h
//  AGRestStack
//
//  Created by Adrien Greiner on 24/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestModule.h"

@protocol AGRestObjectMapping;

/*!
    @protocol AGRestSessionProtocol
 */
@protocol AGRestSessionProtocol <AGRestModuleProtocol>

/*!
    @abstract Authenticate a user with an existing session token and make the logged-in user the current User.
    @param sessionToken The session token used to authenticate the user
    @param email    User's email address.
    @param user     An instance of a user.
    @param block    A result block.
 */
- (void)logInCurrentUserWithSessionToken:(nonnull NSString *)sessionToken
                                   email:(nonnull NSString *)email
                                    user:(nonnull id<AGRestObjectMapping>)user
                              completion:(void (^ _Nullable)(BOOL succeeded, NSError * _Nullable error))block;

/*!
    @abstract Authenticate a user with an email and a password by sending the login request to the server and make the logged-in user the current user.
    @param email A valid email.
    @param password A password
    @param revocableSession YES if the session is revocable. NO otherwise.  
    @param block A result block.
 */
- (void)logInCurrentUserWithEmail:(nonnull NSString *)email
                         password:(nonnull NSString *)password
                 revocableSession:(BOOL)revocableSession
                       completion:( void (^ _Nullable )(BOOL succeeded, AGRestResponse * _Nullable response))block;

/*!
    @abstract Log out the user with a valid session token.
    @param block Log out completion block.
 */
- (void)logOutCurrentUserWithCompletion:(void (^ _Nullable)(BOOL succeeded, AGRestResponse * _Nullable response))block;

/*!
    @abstract Return the current logged in user.
    @return An instance of the user object.
 */
- (nullable id<AGRestObjectMapping>)getCurrentUser;

@optional

/*!
    @discussion Request a password reset for user with email.
    @param email The user's email that needs a reset password.
    @param block A result block.
 */
- (void)requestResetPasswordForEmail:(nonnull NSString *)email
                          completion:(void (^ _Nullable)(BOOL succeeded, AGRestResponse * _Nullable object))block;

@end
