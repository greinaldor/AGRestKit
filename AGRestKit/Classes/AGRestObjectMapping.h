//
//  AGObject+Mapping.h
//  AGRestStack
//
//  Created by Adrien Greiner on 25/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AGObjectMappingDictionaryKey    @"dictKey"
#define AGObjectMappingPropertyKey      @"propKey"
#define AGObjectMappingTransformerKey   @"trans"
#define AGObjectmappingClassKey         @"class"

#define AGObjectMappingMakeClassURI(scheme, host, version, class) \
        [NSString stringWithFormat:@"%@.%@.%@.%@", scheme, host, version, class]

/**
 *  @protocol AGRestObjectMapping
 *  @discussion The AGRestObjectMapping protocol defines base methods that any class should conforms to in order to be
 *  used with AGRestObjectMapper.
 */
@protocol AGRestObjectMapping <NSObject>

/**
 * @discussion Class URI that identify this class.
 * @return The class uri string.
 * @note The dafault implementation of AGRestObjectMapper uses the class URI to match response header Conten-Type field
 * describe in the <a href="http://jsonapi.org/format/">JSON API standards </a>
 */
+ (nonnull NSString *)classURI;

@optional

/*!
 @abstract Create a new instance.
 @return A new instance.
 */
+ (nullable instancetype)newInstance;

/**
 * @discussion Tells the mapper to map a dictionary key to the object's property key.
 * @param propertyKey   The property key that should return his mirrored dictionary key.
 * @return              The dictionary key that should match the propertyKey.
 */
- (nullable NSString *)dictionaryKeyToPropertyKey:(nonnull NSString *)propertyKey;
- (nullable NSString *)dictionaryKeyFromPropertyKey:(nonnull NSString *)propertyKey;
- (nullable NSDateFormatter *)dateFormatterForPropertyKey:(nonnull NSString *)propertyKey;
- (nullable NSDictionary *)objcClassFromDictionaryKeyToPropertyKey:(nonnull NSString *)propertyKey;
- (nullable NSDictionary *)transformerFromDictionaryKeyToPropertyKey:(nonnull NSString *)propertyKey;
- (nullable NSArray *)excludedPropertyKeys;

@end
