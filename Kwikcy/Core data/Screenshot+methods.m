//
//  Screenshot+methods.m
//  Kwikcy
//
//  Created by Hanny Aly on 8/5/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "Screenshot+methods.h"
#import "Constants.h"
#import "AmazonKeyChainWrapper.h"

@implementation Screenshot (methods)



#define SCREENSHOT_NOTIFICATION_TABLE @"Screenshot"

+(void)insertFailedDelivery:(NSDictionary *)info inManagedObjectContext:(NSManagedObjectContext *)context
{
    Screenshot *screenShot = [NSEntityDescription insertNewObjectForEntityForName:SCREENSHOT_NOTIFICATION_TABLE
                                                           inManagedObjectContext:context];
   
    screenShot.me       = info[USERNAME];
    screenShot.receiver = info[RECEIVER];
    screenShot.filepath = info[FILEPATH];
    
    
    NSError *error = nil;
    
    if (![context save:&error])
    {
        
        // Handle the error.
        NSLog(@"Error storing image in coredata: %@", error);
    }
}


+(NSArray *)getScreenshotsNotificationToDeliver:(NSString *)me inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SCREENSHOT_NOTIFICATION_TABLE];
    request.sortDescriptors =  nil;
    request.predicate = [NSPredicate predicateWithFormat:@"me = %@", me];
    
    
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (error)
    {
        return nil;
    }
    
    if (matches && [matches count])
        return matches;
    else
        return nil;
}


+(BOOL)deleteScreenshotNotification:(NSArray *)list inManagedObjectContext:(NSManagedObjectContext *)context
{
    
    for (Screenshot *screenshot in list)
    {
        [context deleteObject:screenshot];
    }
    
    NSError *error = nil;
    if (![context save:&error])
    {
        // Handle the error.
        return NO;
    }
    
    return YES;
}



@end
