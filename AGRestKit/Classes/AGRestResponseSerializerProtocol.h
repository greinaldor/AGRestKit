//
//  AGRestResponseSerializing.h
//  AGRestStack
//
//  Created by Adrien Greiner on 25/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestModule.h"

@class AGRestResponse;
@protocol AGRestObjectMapping;

NS_ASSUME_NONNULL_BEGIN

@protocol AGRestResponseSerializerProtocol

- (id)objectResponseFromResponse:(nonnull AGRestResponse *)response;
- (NSError *)errorResponseFromResponse:(nonnull AGRestResponse *)response;

@optional

@property (nonatomic, copy) id(^objectFromResponseSerializeBlock)(AGRestResponse * _Nonnull response);
@property (nonatomic, copy) NSError*(^errorFromResponseSerializeBlock)(AGRestResponse * _Nonnull response);

@end

NS_ASSUME_NONNULL_END
