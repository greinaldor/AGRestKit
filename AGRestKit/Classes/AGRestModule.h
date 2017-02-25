//
//  AGRestModule.h
//  AGRestStack
//
//  Created by Adrien Greiner on 23/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AGRestCoreManagerDataSource;

@protocol AGRestModuleProtocol <NSObject>

@property (nonatomic, weak) id<AGRestCoreManagerDataSource> dataSource;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(nullable id<AGRestCoreManagerDataSource>)dataSource;

@end

NS_ASSUME_NONNULL_END
