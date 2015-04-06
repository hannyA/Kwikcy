//
//  LogoutRequest.m
//  Quickpeck
//
//  Created by Hanny Aly on 8/21/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "LogoutRequest.h"
#import <AWSRuntime/AWSRuntime.h>
#import "Crypto.h"

@implementation LogoutRequest


/* Hash key is device is and Range key is userid */

@synthesize endpoint = _endpoint;
//@synthesize deviceID = _deviceID;
@synthesize username = _username;
@synthesize appName  = _appName;
@synthesize useSSL   = _useSSL;

-(id)initWithEndpoint:(NSString *)theEndpoint andUsername:(NSString *)theUsername andPassword:(NSString *)thePassword andAppName:(NSString *)theAppName usingSSL:(bool)usingSSL;
{
    self = [super init];
    if (self) {
        self.endpoint = theEndpoint;
        self.username = theUsername;
        self.appName  = theAppName;
        self.useSSL   = usingSSL;
        self.password = thePassword;
        self.decryptionKey = [self computeDecryptionKey];
    }
    
    return self;
}

-(NSString *)buildRequestUrl
{
    NSDate   *currentTime = [NSDate date];
    
    NSString *timestamp = [currentTime stringWithISO8601Format];
    NSData   *signature = [Crypto sha256HMac:[timestamp dataUsingEncoding:NSUTF8StringEncoding] withKey:self.decryptionKey];
    NSString *rawSig    = [[NSString alloc] initWithData:signature encoding:NSASCIIStringEncoding];
    NSString *hexSign   = [Crypto hexEncode:rawSig];
    
    return [NSString stringWithFormat:(self.useSSL ? SSL_LOGOUT_REQUEST:LOGOUT_REQUEST), self.endpoint, [self.username stringWithURLEncoding], [timestamp stringWithURLEncoding], [hexSign stringWithURLEncoding]];
}


-(NSString *)computeDecryptionKey
{
    NSString *salt       = [NSString stringWithFormat:@"%@%@%@", self.username, self.appName, self.endpoint];
    NSData   *hashedSalt = [Crypto sha256HMac:[salt dataUsingEncoding:NSUTF8StringEncoding] withKey:self.password];
    NSString *rawSaltStr = [[NSString alloc] initWithData:hashedSalt encoding:NSASCIIStringEncoding];
    
    return [Crypto hexEncode:rawSaltStr];
}

@end
