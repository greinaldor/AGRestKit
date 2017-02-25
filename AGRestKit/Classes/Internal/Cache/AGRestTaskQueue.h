//
//  AGRestTaskQueue.h
//  AGRestStack
//
//  Created by Adrien Greiner on 28/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BFTask;

@interface AGRestTaskQueue : NSObject

// The lock for this task queue.
@property (nonatomic, strong, readonly) NSObject *mutex;

- (BFTask *)enqueueTask:(BFTask *(^)(BFTask *toAwait))task;

@end
