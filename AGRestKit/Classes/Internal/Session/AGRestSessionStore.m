//
//  AGRestSessionStore.m
//  AGRestStack
//
//  Created by Adrien Greiner on 23/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestSessionStore.h"

#import <Valet/Valet.h>

#import "AGRestConstants.h"
#import "AGRestErrorUtilities.h"

#define kAGRestSessionStoreTokenUnion @"||"

@interface AGRestSessionStore()

@property (strong) VALValet                 *valet;

- (nullable NSString *)_extractSessionTokenWithIdentifier:(NSString * _Nullable __autoreleasing * _Nullable)identifier;

@end

@implementation AGRestSessionStore

- (instancetype)init
{
    if ((self = [super init])) {
        // Check if iCloud is available for the device, in that case create a SynchronizedValet
        if ([VALSynchronizableValet supportsSynchronizableKeychainItems]) {
            self.valet = [[VALSynchronizableValet alloc] initWithIdentifier:@"TheSocialSuperstore"
                                                              accessibility:VALAccessibilityAfterFirstUnlock];
        }
        // iCloud not available then create a Valet
        else {
            self.valet = [[VALValet alloc] initWithIdentifier:@"TheSocialSuperstore"
                                                accessibility:VALAccessibilityAfterFirstUnlock];
        }
    }
    return self;
}

- (nullable NSString *)sessionTokenWithIdentifier:(NSString * _Nullable __autoreleasing * _Nullable)identifier {
    return [self _extractSessionTokenWithIdentifier:identifier];
}

- (BOOL)storeSessionToken:(nonnull NSString *)token
            forIdentifier:(nonnull NSString *)identifier
                    error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    @synchronized(self) {
        if (token && token.length &&
            identifier && identifier.length &&
            self.valet) {
            
            // Create a token string based on an identifier and the token
            NSString *tokenString = [self _tokenStringWithToken:token identifier:identifier];
            
            // Use valet to store the session token
            BOOL isValueStored = [self.valet setString:tokenString forKey:AGRestSessionStoreSessionTokenKey];
                        
            // Check if the operation succeed
            if (!isValueStored && error) {
                *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal message:@"<SessionStore> Valet failed to store the session token string !\
                                                                                            Keychain may not be available!"];
            }
            return isValueStored;
        } else if (error) {
            // Handle error cases
            if (!token || !token.length) {
                *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal message:@"<SessionStore> Token is nil or empty"];
            } else if (!identifier || !identifier.length) {
                *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal message:@"<SessionStore> Identifier is nil or empty"];
            } else if (!self.valet) {
                *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal message:@"<SessionStore> Valet is nil"];
            }
        }
    }
    return NO;
}

- (BOOL)storeData:(nonnull NSData *)data
    forIdentifier:(nonnull NSString *)identifier
            error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    
    if (data && data.length &&
        identifier && identifier.length
        && self.valet) {
        return [self.valet setObject:data forKey:identifier];
    } else if (error) {
        if (!data || !data.length) {
            *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal message:@"<SessionStore> Data is nil or empty"];
        } else if (!identifier || !identifier.length) {
            *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal message:@"<SessionStore> Identifier is nil or empty"];
        } else if (!self.valet) {
            *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal message:@"<SessionStore> Valet is nil"];
        }
    }
    return NO;
}

- (BOOL)removeDataForIdentifier:(nonnull NSString *)identifier
                          error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return NO;
}

- (nullable NSData *)dataForIdentifier:(nonnull NSString *)identifier {
    if (identifier && identifier.length) {
        return [self.valet objectForKey:identifier];
    }
    return nil;
}

- (BOOL)resetCurrentSession:(NSError * _Nullable __autoreleasing * _Nullable)error {
    
    BOOL isValueDeleted = NO;
    
    // Extract and get current session token
    NSString *sessionIdentifier = nil;
    NSString *currentSessionToken = [self _extractSessionTokenWithIdentifier:&sessionIdentifier];
    
    if (sessionIdentifier && currentSessionToken &&
        sessionIdentifier.length && currentSessionToken.length) {
        
        // Remove current token from Valet
        isValueDeleted = [self.valet removeObjectForKey:AGRestSessionStoreSessionTokenKey];
        // Remove current user data
        isValueDeleted = [self.valet removeObjectForKey:sessionIdentifier];
        
        if (!isValueDeleted && error) {
            *error = [AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal
                                                 message:@"Valet failed to delete the session token string / data !\
                      Keychain may not be available!"];
        }
    }
    return isValueDeleted;
}

#pragma mark - Private()
#pragma mark -

- (nullable NSString *)_extractSessionTokenWithIdentifier:(NSString * _Nullable __autoreleasing * _Nullable)identifier {
    if (self.valet) {
        // Find the token string with valet
        NSString *tokenString = [self.valet stringForKey:AGRestSessionStoreSessionTokenKey];
        if (tokenString && tokenString.length) {
            // Extract token from the token
            NSArray *splitToken = [tokenString componentsSeparatedByString:kAGRestSessionStoreTokenUnion];
            if (splitToken && splitToken.count == 2) {
                if (identifier) {
                    *identifier = [splitToken firstObject];
                }
                return [splitToken lastObject];
            }
        }
    }
    return nil;
}

- (nullable NSString *)_tokenStringWithToken:(nonnull NSString *)token identifier:(nonnull NSString *)identifier {
    if (token && token.length &&
        identifier && identifier.length) {
        return [NSString stringWithFormat:@"%@%@%@", identifier, kAGRestSessionStoreTokenUnion, token];
    }
    return nil;
}

@end
