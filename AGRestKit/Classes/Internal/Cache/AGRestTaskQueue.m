//
//  AGRestTaskQueue.m
//  AGRestStack
//
//  Created by Adrien Greiner on 28/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestTaskQueue.h"

#import <Bolts/BFTask.h>

@interface AGRestTaskQueue()

@property (nonatomic, strong, readwrite) BFTask *tail;
@property (nonatomic, strong, readwrite) NSObject *mutex;

@end

@implementation AGRestTaskQueue

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    self.mutex = [[NSObject alloc] init];
    
    return self;
}

- (BFTask *)enqueueTask:(BFTask *(^)(BFTask *toAwait))taskStart {
    @synchronized (self.mutex) {
        BFTask *oldTail = self.tail ?: [BFTask taskWithResult:nil];
        
        // The task created by taskStart is responsible for waiting on the
        // task passed to it before doing its work. This gives it an opportunity
        // to do startup work or save state before waiting for its turn in the queue.
        BFTask *task = taskStart(oldTail);
        
        // The tail task should be dependent on the old tail as well as the newly-created
        // task. This prevents cancellation of the new task from causing the queue to run
        // out of order.
        self.tail = [BFTask taskForCompletionOfAllTasks:@[oldTail, task]];
        
        return task;
    }
}

@end
