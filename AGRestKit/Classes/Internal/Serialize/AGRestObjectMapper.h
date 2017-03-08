//
//  AGRestObjectMapper.h
//  AGRestStack
//
//  Created by Adrien Greiner on 24/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AGRestConstants.h"

#import "AGRestObjectMapperProtocol.h"

/**
 * @class AGRestObjectMapper
 * @abstract The object mapper is responsible for mapping objects from a NSDictionary sourcce to an instance of a registered class.
 * Every registered class should conforms to the AGRestObjectMapping protocol.
 * An object mapper should be registered to the AGRestCoordinator in order to be used, note that only one mapper can be registered at a time.
 * <br><br>The AGRestCoordinator will use his object mapper to automatically map server's responses to registered classes instances and attach those into request responses.
 * @note AGRestObjectMapper is the default object mapper implementation used by AGRestCoordinator.
 * @note You are encouraged to subclass or provide a class that conforms to AGRestObjectMapperProtocol in order to implement you own mapping solution.
 */
@interface AGRestObjectMapper : NSObject <AGRestObjectMapperProtocol>

+ (BOOL)isSupportedClass:(nonnull Class __unsafe_unretained)aClass;

- (nullable id<AGRestObjectMapping>)objectFromSource:(nonnull id)source
                                   toInstanceOfClass:(nonnull Class __unsafe_unretained)targetClass
                                               error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (nullable NSDictionary *)sourceFromObject:(nonnull id<AGRestObjectMapping>)object
                                      error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (nullable NSArray *)sourcesFromArray:(nonnull NSArray< id<AGRestObjectMapping> > *)objects
                                 error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)registerSubclass:(nonnull Class __unsafe_unretained)newClass;

- (nullable NSArray*)allRegisteredClasses;

- (BOOL)isRegisteredClass:(nonnull Class __unsafe_unretained)aClass;


@end
