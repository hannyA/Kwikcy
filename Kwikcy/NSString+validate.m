//
//  NSString+validate.m
//  Quickpeck
//
//  Created by Hanny Aly on 7/26/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "NSString+validate.h"

@implementation NSString (validate)



//TODO where every this function exist
// remove sanitize and add to server side instead

+(NSString *)sanitizeString:(NSString *)string
{
    /* replaces a " with a \"  within the string*/
    string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];

//    string = [string stringByReplacingOccurrencesOfString:@"," withString:@"\\,"];
//    string = [string stringByReplacingOccurrencesOfString:@":" withString:@"\\:"];
   
    return string;
}



/*  Validate All Fields */

+ (BOOL)validateRealName:(NSString *)name
{
    NSString *nameRegex = @"[A-Za-z]+";
    NSPredicate *nameTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", nameRegex];
    
    return [nameTest evaluateWithObject:name];
}

+(BOOL)validateUserName:(NSString *)name
{
    return [self validate:name];
}

+ (BOOL)validateUserPassword:(NSString *)password
{
    return [self validate:password];
}

+ (BOOL) validateEmail:(NSString *)candidate
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:candidate];
}

+ (BOOL)validateMobileNumber:(NSString *)candidate
{
    NSString *mobileRegex = @"[0-9]{9}";
    NSPredicate *mobileTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", mobileRegex];
    return [mobileTest evaluateWithObject:candidate];
}


+(NSString*)purifyMobileNumber:(NSString*)mobileNumber
{
    // Intermediate
    NSString *numberString;
    
    NSScanner *scanner = [NSScanner scannerWithString:mobileNumber];
    NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    
    // Throw away characters before the first number.
    [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
    
    // Collect numbers.
    [scanner scanCharactersFromSet:numbers intoString:&numberString];
    
    
    //    // Result.
    return numberString;
//    int number = [numberString integerValue];   
}


#pragma mark Helper Methods

+(BOOL)validate:(NSString *)word
{
    
    //Allowed by tokens from STS
    //  [\w    + = , . @ -   ]*
    
    
    // Allowed by s3
    //  !, -, _, ., *, ', (, and )
    
    
    //Approved: -  .
    
    NSString *nameRegex = @"[A-Za-z0-9-.]+";
    NSPredicate *nameTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", nameRegex];
    
    return [nameTest evaluateWithObject:word];
}







+(NSString *)isNameValid:(NSString *)name
{
    NSString *errorMessage;
    if (![self validateRealName:name]){
        errorMessage = @"Name must only contain letters";
    }
    return errorMessage;
}

+(NSString *)isUsernameValid:(NSString *)username
{
    NSString *errorMessage;
    if (username.length < 1) {
        errorMessage = @"Enter a username";
    }
    else if (username.length < 3) {
        errorMessage = @"Username must be 3 or more characters";
    }
    else if (username.length > 32 ){
       errorMessage = @"Username must be less than 32 characters";
    }
    else if (![self validateUserName:username]){
        errorMessage = @"Usernames may contain letters, numbers or these characters _." ;
    }
    return errorMessage;
}


+(NSString *)isEmailValid:(NSString *)email
{
    NSString *errorMessage;
    
    if (![self validateEmail:email]){
       errorMessage = @"Enter a valid email address";
    }
    return errorMessage;
}

+(NSString *)isMobileValid:(NSString *)mobileNumber
{
    NSString *errorMessage;
    if (![self validateMobileNumber:mobileNumber]){
        errorMessage = @"Please enter a nine digit number";
    }
    return errorMessage;
}

+(NSString *)isPasswordValid:(NSString *)password
{
    NSString *errorMessage;
    
    if (password.length < 6){
        errorMessage = @"Password must be 6 or more characters";
    }
    else if (password.length > 32){
         errorMessage = @"Password must be less than 32 characters";
    }
    else if (![self validateUserPassword:password]){
        errorMessage = @"Password must contain only alphanumeric characters and/or these characters  _.";
    }
    return errorMessage;
}














@end
