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

#import "GetTokenRequest.h"
#import <AWSRuntime/AWSRuntime.h>
#import "Crypto.h"

@implementation GetTokenRequest

//-(id)initWithEndpoint:(NSString *)theEndpoint andUsername:(NSString *)theUsername andUid:(NSString *)theUid andKey:(NSString *)theKey usingSSL:(bool)usingSSL
-(id)initWithEndpoint:(NSString *)theEndpoint andUsername:(NSString *)theUsername andKey:(NSString *)theKey usingSSL:(bool)usingSSL

{
    NSLog(@"GetTokenRequest.m ");
    if ((self = [super init])) {
        username = [theUsername retain];
        endpoint = [theEndpoint retain];
        key      = [theKey retain];
        useSSL   = usingSSL;
    }

    return self;
}


-(NSString *)buildRequestPostString
{
    NSDate   *currentTime = [NSDate date];
    
    NSString *timestamp = [currentTime stringWithISO8601Format];
    NSData   *signature = [Crypto sha256HMac:[timestamp dataUsingEncoding:NSUTF8StringEncoding] withKey:key];
    NSString *rawSig    = [[[NSString alloc] initWithData:signature encoding:NSASCIIStringEncoding] autorelease];
    NSString *hexSign   = [Crypto hexEncode:rawSig];
    
    
//    return [NSString stringWithFormat:(useSSL ? SSL_GET_TOKEN_REQUEST_POST_STRING:GET_TOKEN_REQUEST_POST_STRING),[username stringWithURLEncoding],[uid stringWithURLEncoding], [timestamp stringWithURLEncoding], [hexSign stringWithURLEncoding]];
    return [NSString stringWithFormat:(useSSL ? SSL_GET_TOKEN_REQUEST_POST_STRING:GET_TOKEN_REQUEST_POST_STRING),[username stringWithURLEncoding], [timestamp stringWithURLEncoding], [hexSign stringWithURLEncoding]];

}

-(NSString *)getUrl
{
    return [NSString stringWithFormat:(useSSL ? SSL_GET_TOKEN_REQUEST_URL:GET_TOKEN_REQUEST_URL), endpoint];
}



-(NSString *)buildRequestUrl
{
    NSDate   *currentTime = [NSDate date];

    NSString *timestamp = [currentTime stringWithISO8601Format];
    NSData   *signature = [Crypto sha256HMac:[timestamp dataUsingEncoding:NSUTF8StringEncoding] withKey:key];
    NSString *rawSig    = [[[NSString alloc] initWithData:signature encoding:NSASCIIStringEncoding] autorelease];
    NSString *hexSign   = [Crypto hexEncode:rawSig];

//    return [NSString stringWithFormat:(useSSL ? SSL_GET_TOKEN_REQUEST:GET_TOKEN_REQUEST), endpoint, [username stringWithURLEncoding],[uid stringWithURLEncoding], [timestamp stringWithURLEncoding], [hexSign stringWithURLEncoding]];

    return [NSString stringWithFormat:(useSSL ? SSL_GET_TOKEN_REQUEST:GET_TOKEN_REQUEST), endpoint, [username stringWithURLEncoding], [timestamp stringWithURLEncoding], [hexSign stringWithURLEncoding]];
}

-(void)dealloc
{
    [username release];
    [endpoint release];
    [key release];
    [super dealloc];
}

@end

