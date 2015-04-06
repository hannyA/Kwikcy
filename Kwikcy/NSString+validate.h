//
//  NSString+validate.h
//  Quickpeck
//
//  Created by Hanny Aly on 7/26/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (validate)

/* Replaces charcter ':' with '\:' and '\' with '\\'  */

/* replaces a " with a \"  within the string*/
+(NSString *)sanitizeString:(NSString *)string;

+ (BOOL)validateRealName:(NSString *)name;

+ (BOOL)validateUserName:(NSString *)name;

+ (BOOL)validateUserPassword:(NSString *)name;

+ (BOOL)validateEmail:(NSString *)candidate;

+ (BOOL)validateMobileNumber:(NSString *)candidate;



+(NSString *)isNameValid:(NSString *)name;

+(NSString *)isUsernameValid:(NSString *)username;

+(NSString *)isEmailValid:(NSString *)email;

+(NSString*)purifyMobileNumber:(NSString*)mobileNumber;
+(NSString *)isMobileValid:(NSString *)mobileNumber;

+(NSString *)isPasswordValid:(NSString *)password;


@end
