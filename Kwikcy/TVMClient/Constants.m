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
#import "Constants.h"
#import "AmazonClientManager.h"
#import "QPNetworkActivity.h"
#import "KwikcyClientManager.h"

#import "Screenshot+methods.h"

#import "KCServerResponse.h"


static NSString *inboxTable;
static NSString *kwikcy_url_base;

@implementation Constants




+(NSString *)current_month
{
    NSArray *months = @[@"JAN",@"FEB", @"MAR",
                        @"APR", @"MAY", @"JUN",
                        @"JUL", @"AUG", @"SEP",
                        @"OCT", @"NOV", @"DEC"];
    
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *components = [gregorian components:NSMonthCalendarUnit
                                                fromDate:[NSDate date]];
    return months[[components month]];
}



//Suppose to get main data, urls, queues in json format text
+(NSDictionary *)getKwikcyData
{
    NSString *filename = [NSString stringWithFormat:@"%@%@", KWIKCY_PUBLIC_URL_BASE, KWIKCY_PUBLIC_FILE];
        
    NSData *st = [NSData dataWithContentsOfURL:[NSURL URLWithString:filename]];    
    if (!st)
        return nil;
    
    NSError *error;
    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:st
                                                                        options:NSJSONReadingAllowFragments
                                                                          error:&error];
    return  responseDictionary;
    
    
    //
    //    NSLog(@"data:\n%@", responseDictionary);
    //
    //    NSLog(@"data:\n%@", responseDictionary[@"urls"]);
    //
    //     NSDictionary * a = responseDictionary[@"urls"];
    //
    //    NSString *b =    a[@"url"];
    //
    //    NSLog(@"%@", b);
    
    
    //    if (!error)
    //    {
    //
    //        NSLog(@"data:\n%@", responseDictionary);
    //
    //        NSDictionary *dic  = [NSDictionary dictionaryWithDictionary:responseDictionary];
    //        NSLog(@"%@", dic);
    //    }
    //    else {
    //        NSLog(@"error response dic");
    //        NSLog(@"a not ok, %@", error.description);
    //        NSLog(@"a not ok, %@", error.description);
    
    
    // OK to use public credentials
    //    AmazonCredentials * publicCredentials = [[AmazonCredentials alloc] initWithAccessKey:PublicAccessKey withSecretKey:PublictPassKey];
    //
    //    AmazonS3Client * s3Client = [[AmazonS3Client alloc] initWithCredentials:publicCredentials];
    //    s3Client.endpoint = [AmazonEndpoints s3Endpoint:US_EAST_1 secure:YES];
    //    s3Client.timeout = 45;
    //
    //
    //    NSString *filename = [NSString stringWithFormat:KWIKCY_PUBLIC_FILE, KWIKCY_VERSION];
    //
    //    S3GetObjectRequest *request = [[S3GetObjectRequest alloc] initWithKey:filename withBucket:PUBLIC_KWIKCY_BUCKET];
    //
    //    S3GetObjectResponse *response =  [s3Client getObject:request];
    //
    //    if (!response.error) {
    //        NSLog(@"no error");
    //
    //        NSError *error;
    //        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:response.body
    //                                                                   options:NSJSONReadingAllowFragments
    //                                                                     error:&error];
    //        if (!error)
    //        {
    //
    //            NSData *p = [NSJSONSerialization dataWithJSONObject:responseDictionary
    //                                                        options:NSJSONWritingPrettyPrinted
    //                                                          error:&error];
    //
    //            NSLog(@"p = \n%@", [[NSString alloc] initWithData:p encoding:NSUTF8StringEncoding] );
    //            
    //        
    //            return responseDictionary;
    //        }
    //        
    //    }
    //    NSLog(@"error");
    //
    //    return nil;
}




//Suppose to get main data, urls, queues from json format text
+(BOOL)setupKwikcyUrl
{
    NSDictionary *data = [self getKwikcyData];
    
    NSDictionary * urls = data[@"urls"];
        
    NSString *ourUrlVersion = [NSString stringWithFormat:@"url%@", KWIKCY_VERSION];
    
    NSString *url = urls[ourUrlVersion];
    
    if (url){
        kwikcy_url_base = url;
        return YES;
    }
    
    return NO;
}


// should be connect.kwikcy.com
+(NSString *)getKwikcyUrl;
{
    if (!kwikcy_url_base)
    {
        [self setupKwikcyUrl];
    }
    return kwikcy_url_base;
}






+(NSString *)InboxTableForMonth
{
    if (!inboxTable)
    {
        NSString *lastMonth = [[NSUserDefaults standardUserDefaults]  stringForKey:LastInboxMonth];
        if (!lastMonth)
        {
            NSString * current_month = [Constants current_month];
            [[NSUserDefaults standardUserDefaults] setValue:current_month forKey:LastInboxMonth];
            [[NSUserDefaults standardUserDefaults] synchronize];
            inboxTable = [NSString stringWithFormat:@"%@%@", InboxTableConst, current_month];
        }
        else
            inboxTable = [NSString stringWithFormat:@"%@%@", InboxTableConst, lastMonth];
    }
    return inboxTable;
}


//+(NSString *)getInboxTable
//{
//    if (!inboxTable)
//    {
//        NSString *lastMonth = [[NSUserDefaults standardUserDefaults]  stringForKey:LastInboxMonth];
//        if (!lastMonth)
//        {
//            NSString * current_month = [Constants current_month];
//            inboxTable = [NSString stringWithFormat:@"%@%@", InboxTableConst, current_month];
//            [[NSUserDefaults standardUserDefaults] setValue:current_month forKey:LastInboxMonth];
//            [[NSUserDefaults standardUserDefaults] synchronize];
//        }
//        else
//            inboxTable = [NSString stringWithFormat:@"%@%@", InboxTableConst, lastMonth];
//    }
//    return inboxTable;
//}

//+(void)setInboxTableForMonth:(NSString *)month
//{
//    [[NSUserDefaults standardUserDefaults] setValue:month forKey:LastInboxMonth];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//
//    inboxTable = [NSString stringWithFormat:@"%@%@", InboxTableConst,  month];
//}





//Check to see if we have entered a new month
+(BOOL)InboxTableMonthMatchesCurrentMonth
{
    NSString *inboxMonth = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastInboxMonth"];
    NSString *current_month = [Constants current_month];
    
    if (![inboxMonth isEqualToString:current_month])
        return NO;
    return YES;
}







+(UIAlertView *)errorAlert:(NSString *)message
{
    return [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
}

+(UIAlertView *)expiredCredentialsAlert
{
    return [[UIAlertView alloc] initWithTitle:@"AWS Credentials" message:@"Credentials Expired, retry your request." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
}

+(UIAlertView *)alertWithTitle:(NSString *)title andMessage:(NSString *)message
{
    return [[UIAlertView alloc] initWithTitle:title
                                       message:message
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil];
}


+(UIColor *)getFadedStrawberryColor
{
    CGFloat green = 34.0/255;
    CGFloat blue = 89.0/255;
    CGFloat red = 1.0;
    CGFloat alpha = 0.8;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+(UIColor *)getStrawberryColor
{
    CGFloat green = 0.0/255;
    CGFloat blue = 128.0/255;
    CGFloat red = 1.0;
    CGFloat alpha = 1.0;


    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+(UIColor *)getSkyColor
{
    CGFloat green = 227.0/255;
    CGFloat blue = 1.0;
    CGFloat red = 25.0/225;
    CGFloat alpha = 1.0;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}













+(NSString *)getPrefixForUsername:(NSString *)username
{
    if (!username || [username length] < 3)
        return nil;
    
    return [[username substringToIndex:3] lowercaseString];
    
    
//    NSString *prefix;
//
//    //If prefix is less than 6 characteres
//    if ([username length] < 6)
//        prefix = [username substringToIndex:3];
//    else
//    {
//        NSString *shortenedName;
//        NSArray *strings = [username componentsSeparatedByCharactersInSet:[[NSCharacterSet letterCharacterSet] invertedSet]];
//        
//        //Check if we have character strings
//        if ([strings count] > 0){
//            shortenedName = strings[0];
//            if ([shortenedName length] < 3)
//                shortenedName = username;
//        }
//        else
//            shortenedName = username;
//
//        
//        if ([shortenedName length] < 6)
//            prefix = [shortenedName substringToIndex:3];
//        else
//            prefix = [shortenedName substringToIndex:([shortenedName length] - 2)];
//    }
//
//    return [prefix lowercaseString];
}












+(void)makeImageRound:(UIImageView *)imageView
{
    imageView.layer.cornerRadius = imageView.frame.size.width /2;
    imageView.clipsToBounds = YES;
//    imageView.layer.borderWidth = 3.0f;
//    imageView.layer.borderColor = [UIColor blackColor].CGColor;
}

@end
















