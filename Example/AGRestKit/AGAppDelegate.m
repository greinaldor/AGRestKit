//
//  AGAppDelegate.m
//  AGRestKit
//
//  Created by greinaldor on 02/25/2017.
//  Copyright (c) 2017 greinaldor. All rights reserved.
//

#import "AGAppDelegate.h"

@import AGRestKit;
@import Bolts;

#import "GoogleBookVolume.h"

#define kGoogleBookAPI  @"https://www.googleapis.com/books/v1/"
#define kGoogleClientId @"8251937846-j7apn80mg71lnjscairmo73n0ctnodmm.apps.googleusercontent.com"
#define kGoogleAPIKey   @"AIzaSyA4L3mlUaaE_I39aDF2wR_l4LDIssGFVZs"

@implementation AGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    [AGRest initializeRestWithBaseUrl:kGoogleBookAPI];
    [AGRest setLoggingEnable:YES level:AGRestLoggingLevelInfo];
    [AGRest registerSubclass:[GoogleBookVolume class]];
    [AGRest registerSubclass:[GoogleBookVolumesList class]];
    
    AGRestRequest *request = [AGRestRequest GETRequestWithUrl:kGoogleBookAPI
                                                     endPoint:@"volumes"
                                                         body:@{@"q":@"isbn:9781451648546"}];
    [request setTargetClass:[GoogleBookVolumesList class]];
    
    [[request sendRequestInBackground] continueWithBlock:^id _Nullable(BFTask * _Nonnull t) {
        if (t.error || t.cancelled) {
            NSLog(@"failed: %@", t.error);
        } else {
            AGRestResponse *response = t.result;
            NSLog(@"result: %@", response.responseData);
        }
        return t;
    }];
    
    //[request cancel];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
