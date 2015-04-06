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

#import "Request.h"


#define LOGIN_REQUEST_URL                 @"http://%@/login"
#define SSL_LOGIN_REQUEST_URL            @"https://%@/login"

#define LOGIN_REQUEST_POST_STRING        @"U=%@&timestamp=%@&signature=%@"


@interface LoginRequest:Request

@property (nonatomic, strong) NSString *endpoint;
//@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *appName;
@property (nonatomic)         bool      useSSL;
@property (nonatomic, strong) NSString *decryptionKey;

-(NSString *)buildRequestUrl;
-(NSString *)getUrl;

-(id)initWithEndpoint:(NSString *)theEndpoint andUsername:(NSString *)theUsername andPassword:(NSString *)thePassword andAppName:(NSString *)theAppName usingSSL:(bool)usingSSL;

@end
