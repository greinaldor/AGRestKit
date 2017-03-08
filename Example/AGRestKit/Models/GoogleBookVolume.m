//
//  Post.m
//  AGRestKit
//
//  Created by Adrien Greiner on 07/03/17.
//  Copyright © 2017 greinaldor. All rights reserved.
//

#import "GoogleBookVolume.h"

@implementation GoogleBookVolume

+ (nonnull NSString *)classURI {
    return @"GoogleBookVolume";
}

//- (NSString *)description {
//    NSString *desc = [NSString stringWithFormat:@"<GoogleBookVolume>"];
//    return desc;
//}

- (nullable NSString *)dictionaryKeyToPropertyKey:(nonnull NSString *)propertyKey {
    if ([propertyKey isEqualToString:@"volumeId"]) {
        return @"id";
    }
    return nil;
}

@end

@implementation GoogleBookVolumesList

+ (NSString *)classURI {
    return NSStringFromClass(self);
}

- (NSDictionary *)objcClassFromDictionaryKeyToPropertyKey:(NSString *)propertyKey {
    if ([propertyKey isEqualToString:@"items"]) {
        return @{@"items":NSStringFromClass([GoogleBookVolume class])};
    }
    return nil;
}

@end
