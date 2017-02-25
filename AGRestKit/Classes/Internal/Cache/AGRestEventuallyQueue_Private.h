//
//  AGRestEventuallyQueue_Private.h
//  AGRestStack
//
//  Created by Adrien Greiner on 28/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AGRestTaskQueue;

@protocol AGRestCachable;

@interface AGRestEventuallyQueue() {
    @protected
        dispatch_queue_t        _synchronizationQueue;
        BFExecutor              *_synchronizationExecutor;
        dispatch_queue_t        _processingQueue;
    
    @private
        dispatch_source_t       _processingQueueSource;
        dispatch_semaphore_t    _retryingSemaphore;
        
        NSMutableDictionary     *_requestIdentifiers;
        NSMutableDictionary     *_taskCompletionSources;
        
        /*!
         Task queue that will enqueue command enqueueing task so that we enqueue the command
         one at a time.
         */
        AGRestTaskQueue         *_requestEnqueueTaskQueue;
}

- (NSArray *)_pendingRequestIdentifiers;

- (id<AGRestCachable>)_requestWithIdentifier:(NSString *)identifier error:(NSError **)error;

- (NSString *)_newIdentifierForRequest:(id<AGRestCachable>)request;

- (BFTask *)_didFinishRunningRequest:(id<AGRestCachable>)request
                      withIdentifier:(NSString *)identifier
                          resultTask:(BFTask *)resultTask;



@end
