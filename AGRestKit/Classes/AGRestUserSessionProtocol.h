//
//  AGUserSessionProtocol.h
//  AGRestStack
//
//  Created by Adrien Greiner on 14/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#ifndef AGUserSessionProtocol_h
#define AGUserSessionProtocol_h

#import "AGRestConstants.h"

@protocol AGRestUserSessionProtocol

@optional

+ (nullable id<AGRestObjectMapping>)currentUser;

+ (nullable id<AGRestObjectMapping>)logInWithEmail:(nonnull NSString *)email
                                          password:(nonnull NSString *)password;

+ (nullable id<AGRestObjectMapping>)logInWithEmail:(nonnull NSString *)email
                                          password:(nonnull NSString *)password
                                             error:(NSError * _Nullable __autoreleasing * _Nullable)error;

+ (void)logInWithEmailInBackground:(nonnull NSString *)email
                          password:(nonnull NSString *)password
                            target:(nonnull id)target
                          selector:(nonnull SEL)selector;

+ (void)logInWithEmailInBackground:(nonnull NSString *)email
                          password:(nonnull NSString *)password
                       resultBlock:(nullable AGRestObjectCompletionBlock)block;

+ (BOOL)logOutCurrentUser;

+ (BOOL)logOutCurrentUser:(NSError * _Nullable __autoreleasing * _Nullable)error;

+ (void)logOutCurrentUserInBackground:(nullable AGRestBooleanCompletionBlock)block;

@end

#endif /* AGRestUserSessionProtocol_h */
