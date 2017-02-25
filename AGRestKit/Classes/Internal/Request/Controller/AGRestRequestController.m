//
//  AGRestRequestController.m
//  AGRestStack
//
//  Created by Adrien Greiner on 20/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestRequestController.h"

#import "Bolts.h"
#import "BFTask+Private.h"

#import "AGRestConstants.h"
#import "AGRestDataProvider.h"
#import "AGRestRequestRunning.h"
#import "AGRestRequest.h"
#import "AGRestResponse.h"
#import "AGRestResponseSerializer.h"
#import "AGRestRequestCache.h"
#import "AGRest_Private.h"
#import "AGRestLogger.h"
#import "AGRestErrorUtilities.h"

@interface AGRestRequestController()

@property (nonatomic, weak) AGRestRequestControllerDataSource dataSource;

@end

@implementation AGRestRequestController

@synthesize dataSource=_dataSource;

#pragma mark - Init
#pragma mark -

- (instancetype)initWithDataSource:(nonnull AGRestRequestControllerDataSource)dataSource {
    self = [super init];
    if (self) {
        _dataSource = dataSource;
    }
    return self;
}

+ (instancetype)controllerWithDataSource:(nonnull AGRestRequestControllerDataSource)dataSource {
    return [[AGRestRequestController alloc] initWithDataSource:dataSource];
}

#pragma mark - AGRestRequestControllerSubclass
#pragma mark -

- (BFTask *)runRequestAsync:(nonnull AGRestRequest *)request withCancellationToken:(nullable BFCancellationToken *)cancellationToken {
    if (cancellationToken.cancellationRequested) {
        return [BFTask cancelledTask];
    }
    
    weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        strongify(weakSelf)
        if (cancellationToken.cancellationRequested) {
            return [BFTask cancelledTask];
        }
        
        // Execute the request whith request runner for class
        return [strongSelf _runRequestAsync:request withCancellationToken:cancellationToken];
    }] continueWithBlock:^id(BFTask *task) {
        strongify(weakSelf)
        
        // Get the AGRestResponse from task result
        AGRestResponse *response = task.result;
        
        // Return task with AGRestResponse result
        if ([response isKindOfClass:[AGRestResponse class]])
        {
            // If request failed internally, fill response.responseError
            if (!response.responseError && task.faulted) {
                NSError *error = (task.error)?:[AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal
                                                                           message:task.error.localizedDescription
                                                                         shouldLog:NO];
                response.responseError = error;
            }
            // Attach the original request to the response
            response.request = request;
            task = [strongSelf _handleRequest:request withResponse:response];
        }
        else
        {
            // If request failed internally, fill response.responseError
            NSError *error = (task.error)?task.error:[AGRestErrorUtilities errorWithCode:kAGErrorInternalLocal
                                                                                 message:task.error.localizedDescription
                                                                               shouldLog:NO];
            AGRestResponse *errorResponse = [AGRestResponse responseWithError:error];
            task = [BFTask taskWithResult:errorResponse];
        }
        return task;
    } cancellationToken:cancellationToken];
}

- (BFTask *)_runRequestAsync:(nonnull AGRestRequest *)request
      withCancellationToken:(nullable BFCancellationToken *)cancellationToken
{
    return [self.dataSource.requestRunner runRequestAsync:request
                                              withOptions:AGRestRequestRunningOptionRetryIfFailed
                                        cancellationToken:cancellationToken];
}

#pragma mark - Default Request Handling
#pragma mark -

- (BFTask *)_handleRequest:(AGRestRequest *)request withResponse:(AGRestResponse *)response {
    // Handle request with error
    if (response.responseError)
    {
        return [self _handleRequest:request failedWithResponse:response];
    }
    
    // Handle request with data
    if (response.responseData) {
        [self _handleRequest:request succeedWithResponse:response];
    }
    return [BFTask taskWithResult:response];
}

- (BFTask *)_handleRequest:(AGRestRequest *)request failedWithResponse:(AGRestResponse *)response {
    
    NSError *error = response.responseError;
    // Process response error
    switch (error.code) {
        // Error - No connectivity
        case NSURLErrorNetworkConnectionLost:
        case NSURLErrorNotConnectedToInternet:
        {
            // If request should run eventually then enqueue request for later execution
            if (request.shouldRunEventually) {
                if ([AGRest isCachingEnabled]) {
                    return [[self.dataSource eventuallyQueue] enqueueRequestInBackground:request];
                } else {
                    AGRestLogWarn(@"<AGRestRequestController> Can't enqueue eventual request, AGRest caching disabled !");
                }
            }
            
        } break;
        // Error - User not identified
        case NSURLErrorUserAuthenticationRequired:
        {
            
        } break;
        // Error - Bad server reponse
        case NSURLErrorBadServerResponse:
        {
            
        } break;
        // Other errors
        default: {
            
        } break;
    }
    
    // Deserialize response error from response data
    if (response.responseData) {
        response.responseError = [self.dataSource.responseSerializer errorResponseFromResponse:response];
    }
    
    return [BFTask taskWithResult:response];
}

- (void)_handleRequest:(AGRestRequest *)request succeedWithResponse:(AGRestResponse *)response {
    // Deserialize response data from response if mapping enabled
    if ([AGRest isObjectMappingEnabled] && [request isObjectMappingEnabled])
    {
        response.targetClass = request.targetClass;
        response.responseData = [self.dataSource.responseSerializer objectResponseFromResponse:response];
    }
}

@end
