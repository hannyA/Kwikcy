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

#import "LoginResponse.h"

@implementation LoginResponse

//@synthesize key = _key;
//@synthesize uid = _uid;
//
//@synthesize accessKey;
//@synthesize secretKey;
//@synthesize securityToken;
//@synthesize expirationDate;

//Designated initializer 
-(id)initWithKey:(NSString *)theKey
{
    self = [super initWithCode:200 andMessage:nil];
    if (self) {
        self.key = theKey;
    }

    return self;
}

-(id)initWithKey:(NSString *)theKey andDeviceID:(NSString *)theDeviceID
{
    self = [self initWithKey:theKey];
    if (self) {
//        self.uid = theDeviceID;
    }
    
    return self;
}

 



-(id)initWithKey:(NSString *)theKey  andAccessKey:(NSString *)theAccessKey andSecretKey:(NSString *)theSecurityKey andSecurityToken:(NSString *)theSecurityToken andExpirationDate:(NSString *)theExpirationDate;
{
    self = [self initWithKey:theKey];
    if (self) {
//        self.uid            = theDeviceID;
        self.accessKey      = theAccessKey;
        self.secretKey      = theSecurityKey;
        self.securityToken  = theSecurityToken;
        self.expirationDate = theExpirationDate;
    }
    return self;
}



-(id)initWithKey:(NSString *)theKey  andAccessKey:(NSString *)theAccessKey andSecretKey:(NSString *)theSecurityKey andSecurityToken:(NSString *)theSecurityToken andExpirationDate:(NSString *)theExpirationDate hasProfilePhoto:(BOOL)hasPhoto
{
    self = [self initWithKey:theKey];
    if (self) {
        //        self.uid            = theDeviceID;
        self.accessKey      = theAccessKey;
        self.secretKey      = theSecurityKey;
        self.securityToken  = theSecurityToken;
        self.expirationDate = theExpirationDate;
        
        self.hasProfilePhoto = hasPhoto;
    }
    return self;
}






//
//-(void)dealloc
//{
//    [self.key release];
//    [super dealloc];
//}


@end

