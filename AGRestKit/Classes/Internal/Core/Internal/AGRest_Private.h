//
//  AGRest_Private.h
//  AGRestStack
//
//  Created by Adrien Greiner on 24/10/2015.
//  Copyright © 2015 The Social Superstore Ltd. All rights reserved.
//

#ifndef AGRest_Private_h
#define AGRest_Private_h

#include"AGRest.h"

@class AGRestManager;

@interface AGRest()

+ (AGRestManager *)_currentManager;
+ (void)_clearCurrentManager;

@end

#endif /* AGRest_Private_h */
