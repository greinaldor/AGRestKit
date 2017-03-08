//
//  AGRestKit.h
//  AGRestKit
//
//  Created by Adrien Greiner on 24/02/17.
//  Copyright © 2017 Adrien Greiner. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for AGRestKit.
FOUNDATION_EXPORT double AGRestKitVersionNumber;

//! Project version string for AGRestKit.
FOUNDATION_EXPORT const unsigned char AGRestKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <AGRestKit/PublicHeader.h>
#import "AGRestConstants.h"

#import "AGRest.h"

#import "AGRestCachable.h"
#import "AGRestLogging.h"
#import "AGRestObjectMapping.h"
#import "AGRestEventuallyQueue.h"
#import "AGRestRequest+Format.h"
#import "AGRestRequest.h"
#import "AGRestResponse.h"
#import "AGRestModule.h"
#import "AGRestKeyValueCache.h"

