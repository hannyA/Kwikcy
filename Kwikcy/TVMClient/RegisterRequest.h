//
//  RegisterRequest.h
//  AWSiOSDemoTVMIdentity
//
//  Created by Hanny Aly on 6/12/13.
//
//
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


/* IMPORTANT */
/* The register request is called but returns with a login request, since we login in right from the registration */

#import "Request.h"


//To use for Post request
#define REGISTER_REQUEST_URL            @"http://%@/register"
#define SSL_REGISTER_REQUEST_URL        @"https://%@/register"
#define REGISTER_REQUEST_POST_STRING    @"U=%@&R=%@&email=%@&mobile=%@&pwd=%@&timestamp=%@&signature=%@"



@interface RegisterRequest:Request
@property (nonatomic, strong) NSString *endpoint;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *realname;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *mobile;

@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *appName;
@property (nonatomic) bool useSSL;
@property (nonatomic, strong) NSString *decryptionKey;
    
-(NSString *)getUrl;
-(NSString *)buildRequestUrl;


-(id)initWithEndpoint:(NSString *)theEndpoint andUsername:(NSString *)theUsername andPassword:(NSString *)thePassword andRealName:(NSString *)theRealName andEmail:(NSString *)theEmail andMobile:(NSString *)theMobile andAppName:(NSString *)theAppName usingSSL:(bool)usingSSL;
-(NSString *)computeDecryptionKey;

@end
