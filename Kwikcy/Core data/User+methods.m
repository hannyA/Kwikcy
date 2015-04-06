//
//  User+methods.m
//  Quickpeck
//
//  Created by Hanny Aly on 8/20/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "User+methods.h"
#import "Constants.h"
#import "AmazonKeyChainWrapper.h"

@implementation User (methods)


+(void)insertAllUsers:(NSArray *)users inManagedObjectContext:(NSManagedObjectContext *)context;
{
    for (NSDictionary *user in users)
    {
        [User insertUser:user inManagedObjectContext:context];
    }
    
    NSError *error = nil;
    
    if (![context save:&error]) {
        
        // Handle the error.
    }
}


/*
 *  User dictionary contains values for keys: USERNAME, REALNAME, MEDIATYPE, DATA
 *
 */
+(void)insertUser:(NSDictionary *)userInfo inManagedObjectContext:(NSManagedObjectContext *)context;
{
    NSLog(@"insert userInfo thank you");
    NSString *username  = [userInfo[USERNAME] lowercaseString];
    
    User *person = [User getUserForUsername:username inManagedContext:context];
    
    // If person not in our contactList then add them
    if (!person)
    {
        NSLog(@"person not in our contactList");
        [User insertSingleUser:userInfo inManagedObjectContext:context];
    }
    else
    {
        NSLog(@"person in our contactList, lets update them");

        [User updateSingleUser:person withInfo:userInfo inManagedObjectContext:context];
    }
}



+(User *)insertSingleUser:(NSDictionary *)user inManagedObjectContext:(NSManagedObjectContext *)context;
{
    NSString *username  = [user[USERNAME] lowercaseString];
    NSString *realname  = [user[REALNAME] lowercaseString];
    NSString *dataValue = user[MEDIATYPE];
    NSData   *data      = user[DATA];
    NSString *status    = user[STATUS];
    
    NSLog(@"inserting person");
    User *person = [NSEntityDescription insertNewObjectForEntityForName:CONTACT_USER_TABLE inManagedObjectContext:context];

    person.me = [AmazonKeyChainWrapper username];
    
    person.username = username;
    
    if (realname)
        person.realname = realname;
    if (data)
    {
        person.data = data;
        person.dataType = dataValue;
    }

    if (status)
        person.status = status;
    
    NSError *error = nil;
    
    if (![context save:&error])
    {
        
        // Handle the error.
        return nil;
    }
    
    return person;
}


+(void)updateSingleUser:(User *)person withInfo:(NSDictionary *)userInfo inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSString *realname  = [userInfo[REALNAME] lowercaseString];
    NSString *dataValue = userInfo[MEDIATYPE];
    NSData   *data      = userInfo[DATA];
    NSString *status    = userInfo[STATUS];

    
    if (realname)
        person.realname = realname;
    if (data)
    {
        person.data = data;
        person.dataType = dataValue;
    }

    
    if (status)
        person.status = status;
    
    NSError *error = nil;
    
    if (![context save:&error]) {
        
        // Handle the error.
    }

}










// updates users image
/*
 * action = insert( insert user image), delete (delete user image), 
 */



/*
 *  userInfo contains parameters: USERNAME, ACTION, and data to upate
 *
 *      ACTOIN =   InsertImage, RemoveImage, InsertName, InsertMobile
 *      parameters:
 */

+(BOOL)updateUserinfo:(NSDictionary *)userInfo inManagedObjectContext:(NSManagedObjectContext *)context
{
    User *user = [User getUserForUsername:userInfo[USERNAME] inManagedContext:context];

    if (!user)
    {
        user = [User insertSingleUser:userInfo inManagedObjectContext:context];
    }
    
    NSString *action = userInfo[ACTION];
    
    
    if ([action isEqualToString:InsertImage])
    {
        NSData *data  = userInfo[DATA];
        user.data = data;
    }
    else if ([action isEqualToString:RemoveImage])
    {
        NSLog(@"Removing image");
        user.dataType = nil;
        user.data = nil;
    }
    else if ([action isEqualToString:InsertName])
    {
        NSLog(@"Insert name");
        if (userInfo[REALNAME])
            user.realname = userInfo[REALNAME];
    }
    else if ([action isEqualToString:InsertMobile])
    {
        NSLog(@"Insert mobile");
        NSString *mobile  = userInfo[MOBILE];
        user.mobile = mobile;
    }
    

    NSError *error = nil;

    if (![context save:&error])
    {
        
        // Handle the error
    }
    else
        return YES;
    
    return NO;
}



+(void)deleteUser:(User *)user inManagedObjectContext:(NSManagedObjectContext *)context
{
    [context deleteObject:user];
    NSError *error = nil;
    
    if (![context save:&error]) {
        
        // Handle the error.
         
    }
}


+(User *)getUserForUsername:(NSString *)username inManagedContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:CONTACT_USER_TABLE];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:USERNAME_LONG ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)]];
    request.predicate = [NSPredicate predicateWithFormat:@"(me = %@) AND (username = %@)",
                                [AmazonKeyChainWrapper username], username];
    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (matches && [matches count] == 1)
    {
        User *user = [matches firstObject];
        return user;
    }
    return nil;
}




+(UIImage *)getImageForContact:(NSString *)user inManagedObjectContext:(NSManagedObjectContext *)context
{
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:CONTACT_USER_TABLE];
    request.sortDescriptors = nil;
    request.predicate = [NSPredicate predicateWithFormat:@"(me = %@) AND (username = %@)",
                         [AmazonKeyChainWrapper username], user];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (matches && [matches count] == 1)
    {
        User *user = [matches lastObject];
        
        return [UIImage imageWithData:user.data];
    }
    NSLog(@"getImageForContact failed to get image");

    return nil;
}


+(NSArray *)getAllOKContactsInManagedObjectContext:(NSManagedObjectContext *)context;
{
    NSString *me = [AmazonKeyChainWrapper username];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:CONTACT_USER_TABLE];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:USERNAME_LONG ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)]];
    request.predicate = [NSPredicate predicateWithFormat:@"(me = %@) AND (username != %@) AND ((status == %@) OR (status == %@) OR (status == %@))",me, me, STATUS_FRIEND, FRIEND_ASYM_KNOWKINGLY, FRIEND_ASYM_UNKNOWINGLY_KNOWINGLY ];
    
    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (error)
        return [NSArray array];
    else if (matches)
        return matches;
    else
        return [NSArray array];

}


+(NSArray *)getAllContactsInManagedObjectContext:(NSManagedObjectContext *)context
{
    NSString *me = [AmazonKeyChainWrapper username];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:CONTACT_USER_TABLE];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:USERNAME_LONG ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)]];
    
    request.predicate = [NSPredicate predicateWithFormat:@"(me = %@) AND (username != %@) AND (status != %@) AND (status != %@)",me, me, STATUS_BLOCKED, STATUS_DENIED];


    // Execute the fetch

    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];

    if (error)
        return nil;
    else if (matches && [matches count])
        return matches;
    else
        return nil;
}


@end
