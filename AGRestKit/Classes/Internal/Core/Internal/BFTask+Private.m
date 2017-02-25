//
//  AGRestExecutor.m
//  AGRestStack
//
//  Created by Adrien Greiner on 25/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "BFTask+Private.h"

@implementation BFExecutor (AGRest)

+ (instancetype)defaultPriorityBackgroundExecutor {
    static BFExecutor *executor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        executor = [BFExecutor executorWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    });
    return executor;
}

@end

@implementation BFTask (AGRest)

- (instancetype)continueAsyncWithBlock:(BFContinuationBlock)block {
    return [self continueWithExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:block];
}

- (instancetype)continueAsyncWithSuccessBlock:(BFContinuationBlock)block {
    return [self continueWithExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withSuccessBlock:block];
}

- (instancetype)continueWithResult:(id)result {
    return [self continueWithBlock:^id(BFTask *task) {
        return result;
    }];
}

- (instancetype)continueWithSuccessResult:(id)result {
    return [self continueWithSuccessBlock:^id(BFTask *task) {
        return result;
    }];
}

- (id)waitForResult:(NSError **)error {
    return [self waitForResult:error withMainThreadWarning:YES];
}

- (id)waitForResult:(NSError **)error withMainThreadWarning:(BOOL)warningEnabled {
    if (warningEnabled) {
        [self waitUntilFinished];
    } else {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [self continueWithBlock:^id(BFTask *task) {
            dispatch_semaphore_signal(semaphore);
            return nil;
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    if (self.cancelled) {
        return nil;
    } else if (self.exception) {
        @throw self.exception;
    }
    if (self.error && error) {
        *error = self.error;
    }
    return self.result;
}

@end
