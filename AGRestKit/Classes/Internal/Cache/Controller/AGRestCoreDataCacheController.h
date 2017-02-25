//
//  AGRestDataManager.h
//  AGRestStack
//
//  Created by Adrien Greiner on 18/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/*!
 @class AGRestCoreDataCacheController
 
 **important:** Not implemented yet.
 */
@interface AGRestCoreDataCacheController : NSObject {
    NSManagedObjectModel            * _managedObjectModel;
    NSManagedObjectContext          * _managedObjectContext;
    NSPersistentStoreCoordinator    * _persistentStoreCoordinator;
}

@property (nonatomic, readonly) NSPersistentStoreCoordinator    * persistentStoreCoordinator;
@property (nonatomic, readonly) NSManagedObjectModel            * managedObjectModel;
@property (nonatomic, readonly) NSManagedObjectContext          * managedObjectContext;

- (BOOL)save;
- (void)reset;
- (void)handleFatalCoreDataError:(NSError*)error;

/**
    @brief A shared instance of AGRestDataManager.
 */
+ (instancetype)sharedDataManager;

@end
