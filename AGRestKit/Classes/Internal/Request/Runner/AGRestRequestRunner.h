//
//  AGRestRequestRunner.h
//  AGRestStack
//
//  Created by Adrien Greiner on 25/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AGRestRequestRunning.h"
#import "AGRestModule.h"


NS_ASSUME_NONNULL_BEGIN
/*!
    @class AGRestRequestRunner
    
    @discussion 
 */
@interface AGRestRequestRunner : NSObject <AGRestRequestRunning, AGRestModuleProtocol>

- (instancetype)initWithDataSource:(nullable id<AGRestCoreManagerDataSource>)dataSource;

- (BFTask *)runRequestAsync:(nonnull AGRestRequest *)request
                withOptions:(AGRestRequestRunningOptions)options;

- (BFTask *)runRequestAsync:(nonnull AGRestRequest *)request
                withOptions:(AGRestRequestRunningOptions)options
          cancellationToken:(nullable BFCancellationToken *)cancellationToken;

@end

NS_ASSUME_NONNULL_END
