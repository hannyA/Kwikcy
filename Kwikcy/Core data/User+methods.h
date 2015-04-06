//
//  User+methods.h
//  Quickpeck
//
//  Created by Hanny Aly on 8/20/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "User.h"


#define ACTION        @"action"
#define InsertImage   @"InsertImage"
#define RemoveImage   @"RemoveImage"
#define InsertName    @"InsertName"
#define InsertMobile  @"InsertMobile"

@interface User (methods)


+(void)insertAllUsers:(NSArray *)users inManagedObjectContext:(NSManagedObjectContext *)context;

+(void)insertUser:(NSDictionary *)user inManagedObjectContext:(NSManagedObjectContext *)context;
+(BOOL)updateUserinfo:(NSDictionary *)userInfo inManagedObjectContext:(NSManagedObjectContext *)context;
+(void)deleteUser:(User *)user inManagedObjectContext:(NSManagedObjectContext *)context;


+(NSArray *)getAllOKContactsInManagedObjectContext:(NSManagedObjectContext *)context;
+(NSArray *)getAllContactsInManagedObjectContext:(NSManagedObjectContext *)context;

+(UIImage *)getImageForContact:(NSString *)user inManagedObjectContext:(NSManagedObjectContext *)context;

//+(User *)getMyDataInManagedContext:(NSManagedObjectContext *)context;

+(User *)getUserForUsername:(NSString *)username inManagedContext:(NSManagedObjectContext *)context;

@end
