//
//  KCServerResponse.m
//  Quickpeck
//
//  Created by Hanny Aly on 2/2/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCServerResponse.h"
#import "Constants.h"

@implementation KCServerResponse


//Designated initializer in Response.h
/* 
-(id)initWithCode:(int)theCode andMessage:(NSString *)theMessage
{
    self = [super init];
 
    if (self) {
        self.code = theCode;
        self.message = theMessage;
    }
 
    return self;
}
*/



/* 
 * ======================================
 * This is the Designated Initializer
 * ======================================
 */
-(id)initWithCode:(int)theCode andSuccess:(NSNumber *)success andMessage:(NSString *)message
{
    // Calls parent init
    self = [super initWithCode:theCode andMessage:message];
    if (self)
    {
        self.successful = [success boolValue];
    }
    return self;
}

-(id)init
{
    self = [self initWithCode:200 andSuccess:[NSNumber numberWithBool:YES] andMessage:nil];
    if (self)
    {
        self.successful = YES;
    }
    return self;
}


-(id)initWithInfo:(NSDictionary *)info
{
    self = [self init];
    if (self)
    {
        self.info = [info mutableCopy];
    }
    return self;
}


-(id)initWithContactsInfo:(NSDictionary *)info
{
    self = [self init];
    if (self)
    {
        _info = [info mutableCopy];
        
        NSArray *contacts = _info[CONTACTS];
        
        for (int i = 0; i < [contacts count]; i++)
        {
            NSMutableDictionary *contact = contacts[i];
            
            NSString* data = contact[DATA];

            if (data)
            {
                NSLog(@"data from server %@:", data);
                NSLog(@"data as data %@:", [data dataUsingEncoding:NSUTF8StringEncoding]);
              
                contact[DATA] = [data dataUsingEncoding:NSUTF8StringEncoding];
            }
        }
        
    }
    return self;
}




-(id)initWithSearchMobileInfo:(NSDictionary *)info
{
    self = [self init];
    if (self) {
        self.username           = info[USERNAME];
        self.realname           = info[REALNAME];
    }
    return self;
}


//-(id)initWithUsersInfo:(NSDictionary *)info
//{
//    self = [self init];
//    if (self)
//    {
//        self.info = info;
//    }
//    return self;
//}


/*
 *  info[ContactAllowed] will contain values ["Added", "Sent"]
 */

-(id)initWithAddContactInfo:(NSDictionary *)info;
{
    self = [self init];
    if (self)
    {
    
        self.info = [info mutableCopy];
        if (info[MESSAGE] && [((NSString *)info[MESSAGE]) length] > 0)
            self.message = info[MESSAGE];
        self.contactAllowed = info[ContactAllowed];
    }
    return self;
}



@end



