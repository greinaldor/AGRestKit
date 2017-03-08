//
//  AGRestResponseSerializer.h
//  AGRestStack
//
//  Created by Adrien Greiner on 25/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AGRestResponseSerializerProtocol.h"

@protocol AGRestObjectMapperProvider;

NS_ASSUME_NONNULL_BEGIN

@interface AGRestResponseSerializer : NSObject <AGRestResponseSerializerProtocol>

@property (nonatomic, copy) id(^objectFromResponseSerializeBlock)(AGRestResponse * _Nonnull response);
@property (nonatomic, copy) NSError*(^errorFromResponseSerializeBlock)(AGRestResponse * _Nonnull response);

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(id<AGRestObjectMapperProvider>)dataSource NS_DESIGNATED_INITIALIZER;

///-----------------------
/// @name AGRestResponseSerializerProtocol
///-----------------------

- (id)objectResponseFromResponse:(nonnull AGRestResponse *)response;
- (NSError *)errorResponseFromResponse:(AGRestResponse *)response;

@end

NS_ASSUME_NONNULL_END
