//
//  KCServerResponse.h
//  Quickpeck
//
//  Created by Hanny Aly on 2/2/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "Response.h"

@interface KCServerResponse : Response

@property (nonatomic) BOOL successful;


//General info depends on what is sent from server
@property (nonatomic, strong) NSMutableDictionary *info;

/*  Search mobile users */
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *realname;
@property (nonatomic, strong) NSString *contactAllowed;

/* message will be an error message */
/* successful messages will be in info[MESSAGE] */

-(id)initWithCode:(int)theCode andSuccess:(NSNumber *)success andMessage:(NSString *)message;

-(id)initWithSearchMobileInfo:(NSDictionary *)dictionary;

-(id)initWithInfo:(NSDictionary *)info;


//returns array of all our contacts
-(id)initWithContactsInfo:(NSDictionary *)info;


//-(id)initWithUsersInfo:(NSDictionary *)info;


/* 
 *  User for command = REQUEST_TO_ADD_CONTACT
 */

-(id)initWithAddContactInfo:(NSDictionary *)info;

@end
