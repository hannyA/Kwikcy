//
//  KCServerResponseHandler.m
//  Quickpeck
//
//  Created by Hanny Aly on 2/2/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCServerResponseHandler.h"
#import "KCServerResponse.h"
#import "Crypto.h"

#import "JSONUtilities.h"

#import "Constants.h"

@implementation KCServerResponseHandler


-(id)initWithKey:(NSString *)theKey andComand:(NSString *)command
{
    self = [super init];
    
    if (self) {
        self.decryptionKey = theKey;
        self.command = command;
    }
    
    return self;
}


//if (self.response.message == nil)
//self.response.message = @"Try again later";

// Currently the response is not encrypted
-(Response *)handleResponse:(NSUInteger)responseCode body:(NSData *)responseBody
{
    NSLog(@"handleResponse for command: %@", self.command);
    
    
    NSError *formatError;
    NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseBody
                                                                       options:NSJSONReadingAllowFragments|NSJSONReadingMutableContainers
                                                                         error:&formatError];
    
    if (responseCode == 200)
    {
        
        //        NSData   *body = [Crypto decrypt:responseBody key:self.decryptionKey];
        //        NSLog(@"KCServerResponse body: %@", body);
        //        NSString *json = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
        //        jsonData = [responseBody dataUsingEncoding:NSUTF8StringEncoding];
        
//        NSError *formatError;
//        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseBody
//                                                                   options:NSJSONReadingAllowFragments
//                                                                     error:&formatError];
//        
//        NSData *p = [NSJSONSerialization dataWithJSONObject:responseDictionary
//                                                    options:NSJSONWritingPrettyPrinted
//                                                      error:&formatError];
//        
//        NSLog(@"\n%@", [[NSString alloc] initWithData:p encoding:NSUTF8StringEncoding] );
        
        // if no error, then the format is correct and data was not encrypted
        if (!formatError)
        {
            
            BOOL error = [(NSNumber *)responseDictionary[@"error"] boolValue];
            
            //error is true
            if (error)
            {
                NSLog(@"messageError exists, there is an error");
                NSLog(@"Error here : %@", responseDictionary[@"message"]);
                return [[KCServerResponse alloc] initWithCode:(int)responseCode
                                                   andSuccess:[NSNumber numberWithBool:NO]
                                                   andMessage:responseDictionary[@"message"]];
            }
            
            BOOL successful = [(NSNumber *)responseDictionary[@"success"] boolValue];
            NSDictionary *info;

            if (successful)
                info = responseDictionary[@"info"];
            else
            {
                NSLog(@"handleResponse not successful");
                
                return [[KCServerResponse alloc] initWithCode:(int)responseCode
                                                   andSuccess:[NSNumber numberWithBool:NO]
                                                   andMessage:(responseDictionary[@"message"] == [NSNull null]) ? nil:responseDictionary[@"message"]];
            }
            
            
            /*=========================================================================================*/
            /* Every thing is fine to this point. Find the command and return the appropriate response */
            /*=========================================================================================*/
            
            
            if ([self.command isEqualToString:SEARCH_MOBILE])
            {
                return [[KCServerResponse alloc] initWithInfo:info];
            }
            else if ([self.command isEqualToString:GET_ALL_CONTACTS])
            {
                return [[KCServerResponse alloc] initWithContactsInfo:info];
            }
            
            
            else if ([self.command isEqualToString:REQUEST_TO_FOLLOW])
            {
                NSLog(@"REQUEST_TO_FOLLOW INCOMPLETE");

            }
            else if ([self.command isEqualToString:RESPONSE_TO_FOLLOW])
            {
                // returned info is null
                NSLog(@"RESPONSE_TO_FOLLOW INCOMPLETE");
            }
            else if ([self.command isEqualToString:REQUEST_MOBILE_CONFIRMATION_CODE])
            {
                return [[KCServerResponse alloc] init];
            }
            else if ([self.command isEqualToString:VERIFY_MOBILE_CONFIRMATION_CODE])
            {
                return [[KCServerResponse alloc] initWithInfo:info];
            }
            else if ([self.command isEqualToString:UPDATE_PERSONAL_INFO])
            {
                // returned info is null
                
                return [[KCServerResponse alloc] init];
            }
            else if ([self.command isEqualToString:SEND_PHOTO])
            {
                // returned info is null
                
                return [[KCServerResponse alloc] initWithInfo:info];
            }
            else if ([self.command isEqualToString:SEND_NOTIFICATON])
            {
                return [[KCServerResponse alloc] init];
            }
            
            else if ([self.command isEqualToString:REQUEST_TO_ADD_CONTACT])
            {
                // returned info is null
                NSLog(@"REQUEST_TO_ADD_CONTACT INCOMPLETE");
                return [[KCServerResponse alloc] initWithAddContactInfo:info];
            }
            
            else if ([self.command isEqualToString:RESPONSE_TO_ADD_CONTACT])
            {
                // returned info is null
                NSLog(@"RESPONSE_TO_ADD_CONTACT INCOMPLETE");
                return [[KCServerResponse alloc] initWithInfo:info];
            }
            
            
            else if ([self.command isEqualToString:REQUEST_EMAIL_CONFIRMATION_CODE])
            {
                // returned info is null
                NSLog(@"REQUEST_EMAIL_CONFIRMATION_CODE INCOMPLETE");
            }
            else if ([self.command isEqualToString:VERIFY_EMAIL_CONFIRMATION_CODE])
            {
                // returned info is null
                NSLog(@"VERIFY_EMAIL_CONFIRMATION_CODE INCOMPLETE");
            }
            else if ([self.command isEqualToString:CHANGE_PASSWORD])
            {
                // returned info is null
                NSLog(@"CHANGE_PASSWORD INCOMPLETE");
            }
            
            else if ([self.command isEqualToString:CHANGE_PREFERENCES])
            {
                // returned info is null
                NSLog(@"CHANGE_PREFERENCES INCOMPLETE");
                
            }
            
            
            
            else if ([self.command isEqualToString:GET_MOBILE_SEARCH_OPTION])
            {
                // returned info is null
                NSLog(@"GET_MOBILE_SEARCH_OPTION INCOMPLETE");
                return [[KCServerResponse alloc] initWithInfo:info];

            }
            else if ([self.command isEqualToString:CHANGE_MOBILE_PRIVACY_SETTING])
            {
                // returned info is null
                NSLog(@"CHANGE_MOBILE_PRIVACY_SETTING INCOMPLETE");
                return [[KCServerResponse alloc] initWithInfo:info];

            }
            
            
            else if ([self.command isEqualToString:GET_CONTACTS_SEARCH_OPTION])
            {
                // returned info is null
                NSLog(@"GET_CONTACTS_SEARCH_OPTION INCOMPLETE");
                return [[KCServerResponse alloc] initWithInfo:info];
                
            }
            else if ([self.command isEqualToString:CHANGE_CONTACTS_PRIVACY_SETTING])
            {
                // returned info is null
                NSLog(@"CHANGE_CONTACTS_PRIVACY_SETTING INCOMPLETE");
                return [[KCServerResponse alloc] initWithInfo:info];
            }
            

            
            
            
            else if ([self.command isEqualToString:USER_IS_ACTIVE_TODAY])
            {
                return [[KCServerResponse alloc] init];
            }
            
            
            

            
            else if ([self.command isEqualToString:GET_USER_INFO])
            {
                // returned info is null
                NSLog(@"GET_USER_INFO INCOMPLETE");
                return [[KCServerResponse alloc] initWithInfo:info];

            }
            else if ([self.command isEqualToString:UPDATE_PROFILE_PHOTO])
            {
                return [[KCServerResponse alloc] init];
            }
            
            
            
            
            
            
            
            else if ([self.command isEqualToString:SCREENSHOT_RESPONSE])
            {
                return [[KCServerResponse alloc] initWithInfo:info];
            }
            else if ([self.command isEqualToString:GET_CAROUSEL_PHOTOS])
            {
                return [[KCServerResponse alloc] initWithInfo:info];
            }
            
            
            
            else if ([self.command isEqualToString:UNSEND_MESSAGE])
            {
                return [[KCServerResponse alloc] initWithInfo:info];
            }
            
            
            
            
            else
            {
                NSLog(@"TODO: KCSERVER handleResponse: INCOMPLETE handle of response for the commnad: %@", self.command);
                //TODO;
            }
        }
        //TODO: Try to decrypt data, if this fails, then return "Try again message"
        else //format error
        {
            NSLog(@"200 code Response from server was malformed");
            NSLog(@"%@", responseDictionary);
            return [[KCServerResponse alloc] initWithCode:(int)responseCode andMessage:@"Try again later"];
        }
    }
    
    // not 200 response code
    else
    {
        NSLog(@"Response code = %lu", (unsigned long)responseCode);

//        NSData *jsonData = [responseBody dataUsingEncoding:NSUTF8StringEncoding];
        
//        NSError *formatError;
//        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:responseBody
//                                                             options:0
//                                                               error:&formatError];
        if (!formatError)
        {
            NSString *error = responseDictionary[@"error"];
            return [[KCServerResponse alloc] initWithCode:(int)responseCode andMessage:error];
        }
        else
        {
            NSLog(@"Response from server was malformed");
            return [[KCServerResponse alloc] initWithCode:(int)responseCode andMessage:@"Try again later"];
        }
    }
    NSLog(@"Ended up here, need to fix");
    return [[KCServerResponse alloc] initWithCode:(int)responseCode andMessage:@"Try again later"];
    
}


//
//
//NSString *responseBody  = @" { \"error\":null, \"success\":true, \"message\":\"Hello there\" }";
//
//NSData *jsonData = [responseBody dataUsingEncoding:NSUTF8StringEncoding];
//
//
//NSError *formatError;
//
//NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:jsonData
//                                                                   options:0
//                                                                     error:&formatError];
//
//formatError = nil;
//NSData *pretty = [NSJSONSerialization dataWithJSONObject:responseDictionary
//                                                 options:NSJSONWritingPrettyPrinted
//                                                   error:&formatError];
//
//NSLog(@"\n%@", [[NSString alloc] initWithData:pretty encoding:NSUTF8StringEncoding] );
//
//
//
//NSDictionary *s = [NSJSONSerialization JSONObjectWithData:jsonData
//                                                  options:NSJSONReadingAllowFragments
//                                                    error:&formatError];
//
//NSData *p = [NSJSONSerialization dataWithJSONObject:s
//                                            options:NSJSONWritingPrettyPrinted
//                                              error:&formatError];
//
//NSLog(@"\n%@", [[NSString alloc] initWithData:p encoding:NSUTF8StringEncoding] );
//
//
//


//if (!formatError) // if no error, then the format is correct and data was not encrypted
//{
//    id messageError = responseDictionary[@"error"];
//    
//    if ([messageError isKindOfClass:[NSNull class]])
//        NSLog(@"messageError is NSNull class,  = %@", messageError);
//    
//    
//    id success = responseDictionary[@"success"];
//    
//    if ([success isKindOfClass:[NSNull class]])
//        NSLog(@"success is NSNull class");
//    
//    if ([success isKindOfClass:[NSNumber class]])
//        NSLog(@"success is NSNumber class");
//    
//    
//    
//    
//    
//    NSString *message = responseDictionary[@"message"];
//    
//    NSLog(@"messageError = %@, success = %@, message = %@", messageError, success, message);
//    
//    
//    if (messageError)
//        NSLog(@"messageError is not null,  = %@", messageError);
//    if (success)
//        NSLog(@"success is not null,  = %@", success);
//    if (message)
//        NSLog(@"message is not null,  = %@", message);
//    
//}
//
//formatError = nil;
//responseDictionary = [NSJSONSerialization JSONObjectWithData:jsonData
//                                                     options:NSJSONReadingAllowFragments
//                                                       error:&formatError];
//
//if (!formatError) // if no error, then the format is correct and data was not encrypted
//{
//    NSString *messageError = responseDictionary[@"error"];
//    NSString *success = responseDictionary[@"success"];
//    NSString *message = responseDictionary[@"message"];
//    
//    NSLog(@"messageError = %@, success = %@, message = %@", messageError, success, message);
//    
//    
//    if (messageError)
//        NSLog(@"messageError is not null,  = %@", messageError);
//    if (success)
//        NSLog(@"success is not null,  = %@", success);
//    if (message)
//        NSLog(@"message is not null,  = %@", message);
//    
//}










@end
