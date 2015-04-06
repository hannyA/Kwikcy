/*
 * Copyright 2010-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "LoginRequest.h"
#import <AWSRuntime/AWSRuntime.h>
#import "Crypto.h"


@interface LoginRequest()
@end

@implementation LoginRequest

@synthesize endpoint = _endpoint;
@synthesize username = _username;
@synthesize password = _password;
@synthesize appName = _appName;
@synthesize useSSL = _useSSL;
@synthesize decryptionKey = _decryptionKey;

-(id)initWithEndpoint:(NSString *)theEndpoint andUsername:(NSString *)theUsername andPassword:(NSString *)thePassword andAppName:(NSString *)theAppName usingSSL:(bool)usingSSL
{
    if ((self = [super init])) {
        self.endpoint = theEndpoint;
        self.username = theUsername ;
        self.password = thePassword;
        self.appName  = theAppName;
        self.useSSL   = usingSSL;

        self.decryptionKey = [self computeDecryptionKey];
    }

    return self;
}



// symmetric key = decryptionKey
// HMAC = hexSign  from -> made signature 

-(NSString *)buildRequestUrl
{
    NSDate   *currentTime = [NSDate date];
    
    NSString *timestamp = [currentTime stringWithISO8601Format];
    NSData   *signature = [Crypto sha256HMac:[timestamp dataUsingEncoding:NSUTF8StringEncoding] withKey:self.decryptionKey];
    NSString *rawSig    = [[NSString alloc] initWithData:signature encoding:NSASCIIStringEncoding];
    NSString *hexSign   = [Crypto hexEncode:rawSig];
    
    
    /*
     Send HMAC  = H(Ks(m))      Server side
     body       = Ks(m)
     */
    
    return [NSString stringWithFormat:LOGIN_REQUEST_POST_STRING,
            [self.username stringWithURLEncoding],
            [timestamp stringWithURLEncoding],
            [hexSign stringWithURLEncoding]];
}

-(NSString *)getUrl
{
    return [NSString stringWithFormat:(self.useSSL ? SSL_LOGIN_REQUEST_URL:LOGIN_REQUEST_URL), self.endpoint];
}





-(NSString *)computeDecryptionKey
{
    NSString *salt       = [NSString stringWithFormat:@"%@%@%@", self.username, self.appName, self.endpoint];
    NSData   *hashedSalt = [Crypto sha256HMac:[salt dataUsingEncoding:NSUTF8StringEncoding] withKey:self.password];
    NSString *rawSaltStr = [[NSString alloc] initWithData:hashedSalt encoding:NSASCIIStringEncoding];

    return [Crypto hexEncode:rawSaltStr];
}

@end

