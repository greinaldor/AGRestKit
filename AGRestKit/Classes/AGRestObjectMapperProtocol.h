//
//  AGRestObjectMapperProtocol.h
//  AGRestStack
//
//  Created by Adrien Greiner on 25/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

@protocol AGRestObjectMapping;

/*!
 @protocol AGRestObjectMapperProtocol
 */
@protocol AGRestObjectMapperProtocol <NSObject>

@required

/*!
    @abstract Map a source dictionary to an instance of a registered class.
    @param source        The source object.
    @param targetClass   The target class to instantiate.
    @param error         The error, if any, which occured during the mapping.
    @return              The mapped object/array instance(s) of the targetClass.
 */
- (nullable id<AGRestObjectMapping>)objectFromSource:(nonnull id)source
                                   toInstanceOfClass:(nonnull Class __unsafe_unretained)targetClass
                                               error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
    @abstract Unmap an instance of a registered class to a source dictionary.
    @param object    The object to unmap.
    @param error     The error, if any, which occured during the unmapping.
    @return          The source dictionary from the given object.
 */
- (nullable NSDictionary *)sourceFromObject:(nonnull id<AGRestObjectMapping>)object
                                      error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
    @abstract Unmap an array of registered class to a source dictionary.
    @param objects   The array of instances of registered class.
    @param error     The error, if any, which occured during the unmapping.
    @return          The source dictionary from the given array.
 */
- (nullable NSArray *)sourcesFromArray:(nonnull NSArray< id<AGRestObjectMapping> > *)objects
                                 error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
    @abstract Register a class that conforms to AGObjectMappingProtocol as a valid mappable/unmapple class.
    Registering a class will make this class ready for mapping/unmapping operations. Under the hood, registering a class will try
    to instanciate an object of this class and call AGObjectMapping configuration methods.
    @param       newClass The class to register.
    @return      YES if a class has been registered. NO otherwise.
 */
- (BOOL)registerSubclass:(nonnull Class __unsafe_unretained)newClass;

/*!
    @return      YES if the class is already registred. No otherwise.
 */
- (BOOL)isRegisteredClass:(nonnull Class __unsafe_unretained)aClass;

/*!
    @return      YES if the class can be registered to the object mapper. No otherwise.
 */
+ (BOOL)isSupportedClass:(nonnull Class __unsafe_unretained)aClass;

/*!
    @return      All registered subclasses of AGObject or NSManagedObject
 */
- (nullable NSArray *)allRegisteredClasses;

/*!
    @return      All registered class URIs, a class URI is returned by any class that conforms to AGObjectMapping.
 */
- (nullable NSArray *)allRegisteredClassURIs;

/*!
    @abstract Returns a Class for a given class uri.
 
    @param uri   The class uri.
    @return      Return a class for his class URI. Returns nil if uri is not registered.
 */
- (nullable Class)classForClassURI:(nonnull NSString *)uri;

@end
