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
#import "Response.h"
#import "ResponseHandler.h"


@interface AmazonTVMClient:NSObject<NSURLConnectionDelegate>

@property (nonatomic, strong) NSString *endpoint;
@property (nonatomic, strong) NSString *appName;
@property (nonatomic) BOOL             useSSL;

-(id)initWithEndpoint:(NSString *)endpoint andAppName:(NSString *)appName useSSL:(bool)useSSL;
-(Response *)getToken;


-(Response *)logoutDevice:(NSString *)deviceID withUserName:(NSString *)username andPassword:(NSString *)thePassword;
-(Response *)login:(NSString *)username password:(NSString *)password;
-(Response *)registerWithUsername:(NSString *)username password:(NSString *)password realName:(NSString *)realName email:(NSString *)email mobile:(NSString *)mobile;




-(Response *)processRequest:(Request *)request responseHandler:(ResponseHandler *)handler;
-(NSString *)getEndpointDomain:(NSString *)originalEndpoint;

@end

