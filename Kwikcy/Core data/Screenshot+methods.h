//
//  Screenshot+methods.h
//  Kwikcy
//
//  Created by Hanny Aly on 8/5/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "Screenshot.h"

@interface Screenshot (methods)

+(void)insertFailedDelivery:(NSDictionary *)info inManagedObjectContext:(NSManagedObjectContext *)context;


+(NSArray *)getScreenshotsNotificationToDeliver:(NSString *)me inManagedObjectContext:(NSManagedObjectContext *)context;


+(BOOL)deleteScreenshotNotification:(NSArray *)list inManagedObjectContext:(NSManagedObjectContext *)context;




@end
