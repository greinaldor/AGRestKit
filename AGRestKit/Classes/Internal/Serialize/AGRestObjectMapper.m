//
//  AGRestObjectMapper.m
//  AGRestStack
//
//  Created by Adrien Greiner on 24/09/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#import "AGRestObjectMapper.h"

#import <objc/runtime.h>
#import <OCMapper/OCMapper.h>
#import <OCMapper/InCodeMappingProvider.h>

#import "SSObjectMapping.h"
#import "AGRestErrorUtilities.h"
#import "AGRestLogger.h"

@interface AGRestObjectMapper()

@property (strong) NSMutableDictionary  *supportedClasses_;
@property (strong) ObjectMapper         *mapper_;

- (void)configureMapper;

- (BOOL)_registerClass:(nonnull Class)newClass;
- (BOOL)_configureClass:(nonnull Class)aClass;
- (NSString *)_getObjectTypeStringFromPropertyAttributes:(objc_property_t)pAttributes;

@end

@implementation AGRestObjectMapper

- (instancetype)init {
    if ((self = [super init])) {
        [self configureMapper];
    }
    return self;
}

- (void)configureMapper {
    self.supportedClasses_ = [NSMutableDictionary dictionary];
    self.mapper_ = [[ObjectMapper alloc] init];
    
    InCodeMappingProvider *inCodeProvider = [[InCodeMappingProvider alloc] init];
    [self.mapper_ setMappingProvider:inCodeProvider];
}

- (nullable id)objectFromSource:(nonnull NSDictionary *)source
              toInstanceOfClass:(nonnull Class __unsafe_unretained)targetClass
                          error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    id object = nil;
    if (source && source.count && targetClass) {
        if ([self isRegisteredClass:targetClass]) {
            
            // Ask the mapper to instanciate an object from the source dictionary
            @try {
                object = [self.mapper_ objectFromSource:source toInstanceOfClass:targetClass];
            }
            @catch (NSException *exception) {
                NSString *errMessage = [NSString stringWithFormat:@"<ObjecMapper> Exception raised with reason : %@", exception.reason];
                if (error) {
                    *error = [AGRestErrorUtilities errorWithCode:kSSErrorInternalLocal message:errMessage];
                } else {
                    AGRestLogError(@"%@", errMessage);
                }
            }
            
            // TODO: add custom validation ability for registered class.
            
            // Check if object is an Array or a instance of the targetClass
            if (![object isKindOfClass:[NSArray class]] && ![object isKindOfClass:targetClass] && error) {
                *error = [AGRestErrorUtilities errorWithCode:kSSErrorInternalLocal
                                                     message:[NSString stringWithFormat:@"<ObjectMapper> Failed to instanciate an object or array instance of \
                                                              targeted class %@", targetClass]];
            }
        } else if (error) {
            *error = [AGRestErrorUtilities errorWithCode:kSSErrorInternalLocal
                                                 message:[NSString stringWithFormat:@"<ObjectMapper> The targetClass %@ is not a registered class.", targetClass]];
        }
    } else if (error) {
        *error = [AGRestErrorUtilities errorWithCode:kSSErrorInternalLocal
                                             message:@"<ObjectMapper> The source dictionary is nil or empty"];
    }
    return object;
}

- (nullable NSDictionary *)sourceFromObject:(nonnull id<AGRestObjectMapping>)object
                                      error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    NSDictionary *source = nil;
    if (object) {
        // Check if object class is registered
        if ([self isRegisteredClass:[object class]])
        {
            @try {
                // Unmap object to a dictionary
                source = [self.mapper_ dictionaryFromObject:object];
            }
            @catch (NSException *exception) {
                NSString *errMessage = [NSString stringWithFormat:@"<ObjecMapper> Exception raised with reason : %@", exception.reason];
                if (error) {
                    *error = [AGRestErrorUtilities errorWithCode:kSSErrorInternalLocal
                                                         message:errMessage];
                } else {
                    AGRestLogError(@"%@", errMessage);
                }
            }
        }
        else if (error) {
            *error = [AGRestErrorUtilities errorWithCode:kSSErrorInternalLocal
                                                 message:[NSString stringWithFormat:@"<ObjectMapper> The object class %@ is not a registered class.",
                                                          [object class]]];
        }
    } else if (error) {
        *error = [AGRestErrorUtilities errorWithCode:kSSErrorInternalLocal
                                             message:@"<ObjectMapper> The object is nil."];
    }
    return source;
}

- (nullable NSArray *)sourcesFromArray:(nonnull NSArray *)objects
                                 error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    if (objects && objects.count) {
        
        // Create the result sources array.
        NSMutableArray *sources = [NSMutableArray arrayWithCapacity:objects.count];
        
        // Create a errorUserInfo dictionary if error's pointer is not null.
        NSMutableDictionary *errorUserInfo = (error)?[NSMutableDictionary dictionaryWithCapacity:objects.count]:nil;
        
        // Loop through the array of objects
        for (id<AGRestObjectMapping> object in objects)
        {
            // Check if object class is registered
            if ([self isRegisteredClass:[object class]]) {
                
                // Unmap object to a dictionary
                NSDictionary *source = nil;
                @try {
                    [self.mapper_ dictionaryFromObject:object];
                }
                @catch (NSException *exception) {
                    if (errorUserInfo) {
                        errorUserInfo[@"code"] = @(kSSErrorInternalLocal);
                        errorUserInfo[@"error"] = [NSString stringWithFormat:@"<ObjectMapper> Exception raised with reason : %@", exception.reason];
                    }
                }
                @finally {
                    if (source) {
                        [sources addObject:source];
                    }
                }
            } else if (errorUserInfo) {
                errorUserInfo[@"code"] = @(kSSErrorInternalLocal);
                errorUserInfo[@"error"] = [NSString stringWithFormat:@"<ObjectMapper> An object class %@ is not a registered class.",
                                           [object class]];
            }
        }
        
        // If error occured fill error pointer
        if (errorUserInfo && errorUserInfo.count && error) {
            *error = [AGRestErrorUtilities errorFromResult:errorUserInfo];
        }
        
        return sources;
        
    } else if (!objects && error) {
        *error = [AGRestErrorUtilities errorWithCode:kSSErrorInternalLocal
                                             message:@"<ObjectMapper> The objects array is nil."];
    }
    return nil;
}

- (BOOL)registerSubclass:(nonnull Class __unsafe_unretained)newClass {
    if (![self isRegisteredClass:newClass]) {
        BOOL isClassConfigured = [self _registerClass:newClass];
        if (isClassConfigured) {
            NSString *classId = [(id<AGRestObjectMapping>)newClass classURI];
            [self.supportedClasses_ setObject:newClass forKey:classId];
        } else {
            AGRestLogWarn(@"<ObjectMapper> Class %@ is not supported, not conforming AGObjectMapping or not kind of NSObject.", newClass);
        }
        return isClassConfigured;
    }
    return NO;
}

- (nullable NSArray*)allRegisteredClasses {
    return [self.supportedClasses_ allValues];
}

- (nullable NSArray *)allRegisteredClassURIs {
    return [self.supportedClasses_ allKeys];
}

- (nullable Class __unsafe_unretained)classForClassURI:(nonnull NSString *)uri {
    if (uri && uri.length) {
        for (NSString *uriKey in [self.supportedClasses_ allKeys]) {
            if ([[uriKey lowercaseString] isEqualToString:[uri lowercaseString]]) {
                return [self.supportedClasses_ objectForKey:uriKey];
            }
        }
    }
    return nil;
}

- (BOOL)isRegisteredClass:(Class)aClass {
    if ([[self class] isSupportedClass:aClass]) {
        NSString *classId = [(id<AGRestObjectMapping>)aClass classURI];
        return ([self.supportedClasses_ objectForKey:classId] != nil);
    }
    return NO;
}

+ (BOOL)isSupportedClass:(nonnull Class __unsafe_unretained)aClass {
    return ([aClass isSubclassOfClass:[NSObject class]] &&
            [aClass conformsToProtocol:@protocol(AGRestObjectMapping)]);
}

#pragma mark - Private()
#pragma mark -

- (BOOL)_registerClass:(nonnull Class __unsafe_unretained)newClass {
    if (newClass && [[self class] isSupportedClass:newClass]) {
        BOOL ret = NO;
        @try {
            ret = [self _configureClass:newClass];
        }
        @catch (NSException *exception) {
            AGRestLogError(@"An exception occured while trying to register %@ :\n%@",
                       NSStringFromClass(newClass), exception.reason);
        }
        return ret;
    }
    return NO;
}

- (BOOL)_configureClass:(nonnull Class __unsafe_unretained)aClass {
    if (aClass)
    {
        // Instanciate the class for further use
        id<AGRestObjectMapping> anInstance = nil;
        if ([aClass respondsToSelector:@selector(newInstance)]) {
            anInstance = [aClass newInstance];
        } else {
            @try {
                anInstance = [[aClass alloc] init];
            }
            @catch (NSException *exception) {
                AGRestLogError(@"<AGRestObjectMapper> Failed to instanciate object of type : %@\nReason : %@", aClass, exception.reason);
                return NO;
            }
        }
        
        // Get the instance provider for class configuration
        InCodeMappingProvider *mappingProvider = self.mapper_.mappingProvider;
        
        // If instance implements some optional protocol methods then call them on each property
        if ([anInstance respondsToSelector:@selector(dictionaryKeyToPropertyKey:)] ||
            [anInstance respondsToSelector:@selector(dictionaryKeyFromPropertyKey:)] ||
            [anInstance respondsToSelector:@selector(dateFormatterForPropertyKey:)] ||
            [anInstance respondsToSelector:@selector(objcClassFromDictionaryKeyToPropertyKey:)] ||
            [anInstance respondsToSelector:@selector(transformerFromDictionaryKeyToPropertyKey:)])
        {
            // Get the property list for the class
            unsigned int pPropertyCount = 0;
            objc_property_t *pPropertyList = class_copyPropertyList(aClass, &pPropertyCount);
            
            @autoreleasepool {
                // Loop through the class properties and configure mappingProvider accordingly
                for (int i = 0; i < pPropertyCount; i++) {
                    
                    objc_property_t pProperty = pPropertyList[i];
                    const char      *pPropertyKey = property_getName(pProperty);
                    NSString        *propertyKey = [NSString stringWithUTF8String:pPropertyKey];
                    NSString        *propertyType = [self _getObjectTypeStringFromPropertyAttributes:pProperty];
                    Class           objectType = NSClassFromString(propertyType);
                    
                    // Get dictionary key for property key
                    if ([anInstance respondsToSelector:@selector(dictionaryKeyFromPropertyKey:)]) {
                        NSString *dicKey = [anInstance dictionaryKeyFromPropertyKey:propertyKey];
                        if (dicKey && dicKey.length) {
                            [mappingProvider mapFromPropertyKey:propertyKey toDictionaryKey:dicKey forClass:aClass];
                        }
                    }
                    
                    // Get property key for dictionary key
                    if ([anInstance respondsToSelector:@selector(dictionaryKeyToPropertyKey:)]) {
                        NSString *dicKey = [anInstance dictionaryKeyToPropertyKey:propertyKey];
                        if (dicKey && dicKey.length) {
                            if (objectType && [[self class] isSupportedClass:objectType]) {
                                [mappingProvider mapFromDictionaryKey:dicKey toPropertyKey:propertyKey withObjectType:objectType forClass:aClass];
                            } else {
                                [mappingProvider mapFromDictionaryKey:dicKey toPropertyKey:propertyKey forClass:aClass];
                            }
                        }
                    }
                                        
                    // Get transformer for property key
                    if ([anInstance respondsToSelector:@selector(transformerFromDictionaryKeyToPropertyKey:)]) {
                        NSDictionary *tuple = [anInstance transformerFromDictionaryKeyToPropertyKey:propertyKey];
                        NSString *dicKey = tuple[SSObjectMappingDictionaryKey];
                        id transformer = tuple[SSObjectMappingTransformerKey];
                        if (dicKey && dicKey.length && transformer)
                        {
                            [mappingProvider mapFromDictionaryKey:dicKey
                                                    toPropertyKey:propertyKey
                                                         forClass:aClass
                                                  withTransformer:transformer];
                        }
                    }
                    
                    // Get class for dictionary key to property key
                    if ([anInstance respondsToSelector:@selector(objcClassFromDictionaryKeyToPropertyKey:)]) {
                        NSDictionary *tuple = [anInstance objcClassFromDictionaryKeyToPropertyKey:propertyKey];
                        NSString *dicKey = tuple[SSObjectMappingDictionaryKey];
                        Class class = tuple[SSObjectmappingClassKey];
                        if (dicKey && dicKey.length && class) {
                            [mappingProvider mapFromDictionaryKey:dicKey
                                                    toPropertyKey:propertyKey
                                                   withObjectType:class
                                                         forClass:aClass];
                        }
                    }
                }
            }
            free(pPropertyList);
        }
        
        // Exclude dictionary keys
        NSMutableArray *keys = [NSMutableArray array];
        NSArray *systemDefined = @[@"hash",@"debugDescription",@"description",@"superclass"];
        [keys addObjectsFromArray:systemDefined];
        
        if ([anInstance respondsToSelector:@selector(excludedPropertyKeys)]) {
            NSArray *userDefined = [anInstance excludedPropertyKeys];
            [keys addObjectsFromArray:userDefined];
        }
        [mappingProvider excludeMappingForClass:aClass withKeys:keys];
        
        // Add setValue:forUndefinedKey: method with empty body, avoiding ObjectMapper failure
        class_addMethod(aClass, @selector(setValue:forUndefinedKey:), (IMP)_swizzle_setValueForUndefinedKey, "@v:@@");
        
        anInstance = nil;
        return YES;
    }
    return NO;
}

- (nullable NSString *)_getObjectTypeStringFromPropertyAttributes:(nonnull objc_property_t)pAttributes {
    NSString *objctype = nil;
    if (pAttributes) {
        const char *attributes = property_getAttributes(pAttributes);
        NSString *typeAttributes = [NSString stringWithCString:attributes encoding:NSUTF8StringEncoding];
        NSString *typeString = [[typeAttributes componentsSeparatedByString:@","] firstObject];
        if (typeString) {
            NSUInteger typeStringL = typeString.length;
            if (typeStringL > 3) {
                objctype = [typeString substringWithRange:NSMakeRange(3, typeStringL - 4)];
            }
        }
    }
    return objctype;
}

void _swizzle_setValueForUndefinedKey(id self, SEL _cmd, NSString *value, NSString *undefinedKey) {}

@end
