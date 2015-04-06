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

#import <Foundation/Foundation.h>
#import "Response.h"

@interface LoginResponse:Response

//@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSString *key;

@property (nonatomic, strong) NSString *accessKey;
@property (nonatomic, strong) NSString *secretKey;
@property (nonatomic, strong) NSString *securityToken;
@property (nonatomic, strong) NSString *expirationDate;

@property (nonatomic)         BOOL      hasProfilePhoto;


-(id)initWithKey:(NSString *)theKey;
//-(id)initWithKey:(NSString *)theKey andDeviceID:(NSString *)theDeviceID;

-(id)initWithKey:(NSString *)theKey andAccessKey:(NSString *)theAccessKey andSecretKey:(NSString *)theSecurityKey andSecurityToken:(NSString *)theSecurityToken andExpirationDate:(NSString *)theExpirationDate;

-(id)initWithKey:(NSString *)theKey  andAccessKey:(NSString *)theAccessKey andSecretKey:(NSString *)theSecurityKey andSecurityToken:(NSString *)theSecurityToken andExpirationDate:(NSString *)theExpirationDate hasProfilePhoto:(BOOL)hasPhoto;
@end
