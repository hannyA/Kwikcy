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

#import "LoginResponseHandler.h"
#import "LoginResponse.h"
#import "Crypto.h"
#import "JSONUtilities.h"
#import "Constants.h"

@implementation LoginResponseHandler

@synthesize decryptionKey = _decryptionKey;

-(id)initWithKey:(NSString *)theKey
{
    self = [super init];
    
    if (self) {
        self.decryptionKey = theKey;
    }

    return self;
}

-(Response *)handleResponse:(int)responseCode body:(NSData *)responseBody
{
    
    NSString *message = @"Try again later";
    
    if (responseCode == 200)
    {
        NSData   *body = [Crypto decrypt:[[NSString alloc] initWithData:responseBody
                                          encoding:NSUTF8StringEncoding]
                                     key:[self.decryptionKey substringToIndex:32]];
        NSError *error;
        NSDictionary *information = [NSJSONSerialization JSONObjectWithData:body
                                                                   options:NSJSONReadingAllowFragments
                                                                     error:&error];
        if (error)
        {
            return [[LoginResponse alloc] initWithCode:KC_ERROR
                                            andMessage:message];
        }
        else
        {
            
            NSString *key            = information[KEY];

            NSString *accessKey      = information[ACCESS_KEY];
            NSString *secretKey      = information[SECRET_KEY];
            NSString *securityToken  = information[SECURITY_TOKEN];
            NSString *expirationDate = information[EXPIRATION_DATE];
            
            BOOL hasProfilePhoto =     [information[HAS_PROFILE_PHOTO] boolValue];

//            NSLog(@"has profile = %@", information[HAS_PROFILE_PHOTO]);
//
//            if ([information[HAS_PROFILE_PHOTO] isEqual:[NSNull null]]
//            
//            NSLog(@"has profile = %@", hasProfilePhoto?@"YES":@"NO");
//            
//            NSLog(@"has profile = %hhd", hasProfilePhoto);
//            
            return [[LoginResponse alloc] initWithKey:key andAccessKey:accessKey andSecretKey:secretKey andSecurityToken:securityToken andExpirationDate:expirationDate hasProfilePhoto:hasProfilePhoto];
        }

        
//        NSString *json = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
//
//        //NSString *deviceID       = [JSONUtilities getJSONElement:json element:@"deviceID"];
//
//        NSString *key            = [JSONUtilities getJSONElement:json element:@"key"];
//        NSString *accessKey      = [JSONUtilities getJSONElement:json element:@"accessKey"];
//        NSString *secretKey      = [JSONUtilities getJSONElement:json element:@"secretKey"];
//        NSString *securityToken  = [JSONUtilities getJSONElement:json element:@"securityToken"];
//        NSString *expirationDate = [JSONUtilities getJSONElement:json element:@"expirationDate"];
//                
//        return [[LoginResponse alloc] initWithKey:key andAccessKey:accessKey andSecretKey:secretKey andSecurityToken:securityToken andExpirationDate:expirationDate];
    }
    else {
        NSLog(@"responseBody = %@",  [[NSString alloc] initWithData:responseBody encoding:NSUTF8StringEncoding]);
        
        
        NSError *error;
        NSDictionary *information = [NSJSONSerialization JSONObjectWithData:responseBody
                                                                options:NSJSONReadingAllowFragments
                                                                  error:&error];
        if (!error)
        {
            NSString *error            = information[@"error"];
            NSString *infoMessage      = information[@"message"];
            
            NSLog(@"mmessage %@", infoMessage);
            NSLog(@"mmessage %@", error);
            
            if ([infoMessage isEqual:[NSNull null]]){
                NSLog(@"null");
                
                infoMessage = message;
            }
            else if (infoMessage == nil)
                NSLog(@"nil");
            


            
                NSLog(@"mmessage %@", infoMessage);

            return [[LoginResponse alloc] initWithCode:responseCode
                                            andMessage:infoMessage];
        }

    }
    

            
    
        return [[LoginResponse alloc] initWithCode:responseCode
                                            andMessage: message];
    
//        
//        NSString *error  = [JSONUtilities getJSONElement:responseBody element:@"error"];
//        NSString *message  = [JSONUtilities getJSONElement:responseBody element:@"message"];
//        
//        NSLog(@"mmessage %@", message);
//        NSLog(@"mmessage %@", error);
        
//        return [[LoginResponse alloc] initWithCode:responseCode
//                                        andMessage: ([responseBody length] < 200)?message:@"Try again later"];
    
}


@end

