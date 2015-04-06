//
//  ViewController_State+methods.h
//  Quickpeck
//
//  Created by Hanny Aly on 4/5/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "ViewController_State.h"


#define CONTROLLER_STATE_TABLE  @"ViewController_State"
#define VIEWCONTROLLERNAME      @"viewControllerName"
#define TIME                    @"time"
#define VALID                   @"valid"
#define ACTION                  @"action"
#define OBJECTVIEW              @"objectView"
#define INFO                    @"info"

@interface ViewController_State (methods)


+(ViewController_State *)saveStateForViewController:(NSDictionary *)viewControllerState inManagedObjectContext:(NSManagedObjectContext *)context;
+(ViewController_State *)getStateForViewController:(NSString *)viewController inManagedObjectContext:(NSManagedObjectContext *)context;
+(void)deleteStateForViewController:(ViewController_State *)viewControllerState inManagedObjectContext:(NSManagedObjectContext *)context;
@end
