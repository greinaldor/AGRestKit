//
//  AGRestExecutor.h
//  AGRestStack
//
//  Created by Adrien Greiner on 25/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Bolts/Bolts.h>

@interface BFExecutor (AGRest)

+ (instancetype)defaultPriorityBackgroundExecutor;

@end

@interface BFTask (AGRest)

- (instancetype)continueAsyncWithBlock:(BFContinuationBlock)block;
- (instancetype)continueAsyncWithSuccessBlock:(BFContinuationBlock)block;

- (instancetype)continueWithResult:(id)result;
- (instancetype)continueWithSuccessResult:(id)result;

- (id)waitForResult:(NSError **)error;
- (id)waitForResult:(NSError **)error withMainThreadWarning:(BOOL)warningEnabled;

@end
