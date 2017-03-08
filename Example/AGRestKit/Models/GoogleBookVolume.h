//
//  Post.h
//  AGRestKit
//
//  Created by Adrien Greiner on 07/03/17.
//  Copyright © 2017 greinaldor. All rights reserved.
//

#import <Foundation/Foundation.h>

@import AGRestKit;

@interface GoogleBookVolume : NSObject <AGRestObjectMapping>

@property (nonatomic, strong) NSString  *kind;
@property (nonatomic, strong) NSString  *etag;
@property (nonatomic, strong) NSNumber  *volumeId;
@property (nonatomic, strong) NSString  *selfLink;

@end

@interface GoogleBookVolumesList : NSObject <AGRestObjectMapping>

@property (nonatomic, strong) NSString *kind;
@property (nonatomic, strong) NSArray<GoogleBookVolume *> *items;
@property (nonatomic, strong) NSNumber *totalItems;

@end
