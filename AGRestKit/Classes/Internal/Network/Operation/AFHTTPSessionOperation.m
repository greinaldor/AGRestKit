//
//  AFHTTPSessionOperation.m
//  AGRestStack
//
//  Created by Adrien Greiner on 19/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AFHTTPSessionOperation.h"
#import "AFNetworking.h"

@interface AFHTTPSessionManager (DataTask)

// this method is not publicly defined in @interface in .h, so we need to define our own interface for it

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                         success:(void (^)(NSURLSessionDataTask *, id))success
                                         failure:(void (^)(NSURLSessionDataTask *, NSError *))failure;
@end

@interface AFHTTPSessionOperation ()

@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, copy) NSString *method;
@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, copy) id parameters;
@property (nonatomic, copy) NSDictionary * headers;
@property (nonatomic, copy) void (^success)(NSURLSessionDataTask *task, id responseObject);
@property (nonatomic, copy) void (^failure)(NSURLSessionDataTask *task, NSError * error);

@property (nonatomic, weak) NSURLSessionTask *task;

@end

@implementation AFHTTPSessionOperation

+ (nullable instancetype)operationWithManager:(nonnull AFHTTPSessionManager *)manager
                                       method:(nonnull NSString *)method
                                    urlString:(nonnull NSString *)urlString
                                   parameters:(nullable id)parameters
                                      headers:(nullable NSDictionary *)headers
                                      success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                                      failure:(nullable void (^)(NSURLSessionDataTask *task, NSError * error))failure
{    
    AFHTTPSessionOperation *operation = [[self alloc] init];
    
    operation.manager = manager;
    operation.method = method;
    operation.urlString = urlString;
    operation.parameters = parameters;
    operation.headers = headers;
    operation.success = success;
    operation.failure = failure;
    
    return operation;
}

- (void)main {    
    NSURLSessionTask *task = [self dataTaskWithHTTPMethod:self.method
                                                urlString:self.urlString
                                               parameters:self.parameters
                                                  headers:self.headers
                                                  success:^(NSURLSessionDataTask *task, id responseObject) {
        if (self.success) {
            self.success(task, responseObject);
        }
        [self completeOperation];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (self.failure) {
            self.failure(task, error);
        }
        [self completeOperation];
    }];
    [task resume];
    self.task = task;
}

// Redefine dataTask provider method to handle custom headers for request
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       urlString:(NSString *)urlString
                                      parameters:(id)parameters
                                         headers:(NSDictionary *)headers
                                         success:(void (^)(NSURLSessionDataTask *, id))success
                                         failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSString *url = [[NSURL URLWithString:urlString relativeToURL:self.manager.baseURL] absoluteString];
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.manager.requestSerializer requestWithMethod:method
                                                                           URLString:url
                                                                          parameters:parameters
                                                                               error:&serializationError];
    if (serializationError) {
        if (failure) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.manager.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
#pragma clang diagnostic pop
        }
        
        return nil;
    }
    
    // Add custom headers for request
    for (NSString * httpHeaderKey in [headers allKeys]) {
        NSString * httpHeaderValue = headers[httpHeaderKey];
        [request addValue:httpHeaderValue forHTTPHeaderField:httpHeaderKey];
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self.manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(dataTask, error);
            }
        } else {
            if (success) {
                success(dataTask, responseObject);
            }
        }
    }];
    
    return dataTask;
}

- (void)completeOperation {
    self.failure = nil;
    self.success = nil;
    
    [super completeOperation];
}

- (void)resume {
    [self.task resume];
}

- (void)suspend {
    [self.task suspend];
}

- (void)cancel {
    [self.task cancel];
    [super cancel];
}

@end
