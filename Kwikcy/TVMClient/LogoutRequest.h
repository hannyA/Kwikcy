//
//  LogoutRequest.h
//  Quickpeck
//
//  Created by Hanny Aly on 8/21/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "Request.h"

#define LOGOUT_REQUEST        @"http://%@/logout?U=%@&timestamp=%@&signature=%@"
#define SSL_LOGOUT_REQUEST    @"https://%@/logout?U=%@&timestamp=%@&signature=%@"



@interface LogoutRequest : Request

@property (nonatomic, strong) NSString *endpoint;
//@property (nonatomic, strong) NSString *deviceID;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *appName;
@property (nonatomic)         bool      useSSL;
@property (nonatomic, strong) NSString *decryptionKey;



-(id)initWithEndpoint:(NSString *)theEndpoint andUsername:(NSString *)theUsername andPassword:(NSString *)thePassword andAppName:(NSString *)theAppName usingSSL:(bool)usingSSL;

@end
