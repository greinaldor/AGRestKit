//
//  AGRestRequestRunning.h
//  AGRestStack
//
//  Created by Adrien Greiner on 20/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BFTask;
@class BFCancellationToken;
@class AGRestRequest;

/*!
 @discussion Request running options interpreted by the server instance.
 */
typedef NS_ENUM(NSUInteger, AGRestRequestRunningOptions) {
    /*!
     @abstract Option indicating wether a failed request should retry.
     */
    AGRestRequestRunningOptionRetryIfFailed = 1 << 0,
};

NS_ASSUME_NONNULL_BEGIN

/*!
 @protocol AGRestRequestRunning
 @discussion AGRestRequestRunning defines the base methods that run a AGRestRequest.
 */
@protocol AGRestRequestRunning <NSObject>

@required

///-----------------------
#pragma mark - Data Request
/// Data Request
///-----------------------

/*!
 @abstract Run a request asynchronously.
 @param request AGRestRequest to execute.
 @param options AGRestRequestRunningOptions for running the request.
 @return Returns a BFTask as result.
 */
- (BFTask *)runRequestAsync:(nonnull AGRestRequest *)request
                withOptions:(AGRestRequestRunningOptions)options;

/*!
 @abstract Run a request asynchronously.
 @param request AGRestRequest to execute.
 @param options AGRestRequestRunningOptions for running the request.
 @param cancellationToken The BFCancellationToken for cancelling the request.
 @return Returns a BFTask as result.
 */
- (BFTask *)runRequestAsync:(nonnull AGRestRequest *)request
                withOptions:(AGRestRequestRunningOptions)options
          cancellationToken:(nullable BFCancellationToken *)token;

///-----------------------
#pragma mark - File Request
/// File Request
///-----------------------

// TODO: Design file upload/download interface

@end

NS_ASSUME_NONNULL_END
