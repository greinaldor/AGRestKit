//
//  AFHTTPSessionOperation.h
//  AGRestStack
//
//  Created by Adrien Greiner on 19/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestConcurrentOperation.h"

@class AFHTTPSessionManager;

NS_ASSUME_NONNULL_BEGIN

@interface AFHTTPSessionOperation : AGRestConcurrentOperation

+ (nullable instancetype)operationWithManager:(nonnull AFHTTPSessionManager *)manager
                                       method:(nonnull NSString *)method
                                    urlString:(nonnull NSString *)urlString
                                   parameters:(nullable id)parameters
                                      headers:(nullable NSDictionary *)headers
                                      success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                                      failure:(nullable void (^)(NSURLSessionDataTask *task, NSError * error))failure;

- (void)resume;
- (void)suspend;

@end

NS_ASSUME_NONNULL_END
