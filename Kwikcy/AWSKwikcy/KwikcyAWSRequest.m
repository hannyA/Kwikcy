//
//  KwikcyAWSRequest.m
//  Kwikcy
//
//  Created by Hanny Aly on 8/9/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KwikcyAWSRequest.h"
#import "Constants.h"
#import <AWSDynamoDB/AWSDynamoDB.h>
#import <AWSS3/AWSS3.h>
#import "KwikcyClientManager.h"


#import "QPNetworkActivity.h"
#import "Screenshot+methods.h"
#import "KCServerResponse.h"
#import "AmazonClientManager.h"

#import "User+methods.h"

#import "QPCoreDataManager.h"
#import "AmazonKeyChainWrapper.h"


#define PublicAccessKey                     @"AKIAIDXWVF7IGWOQM3KA"
#define PublictPassKey                      @"2dkTSbraErkZ1w1pOXTL2b1wiaE+Mmvwur6gUPc+"


@implementation KwikcyAWSRequest



/*
 *  Gets users realname and photo from kcUserSearch table
 */

+(NSMutableDictionary *)getDetailsForUser:(NSString *)user
{
    NSString *prefix = [Constants getPrefixForUsername:user];
    
    if (!prefix)
        return nil;
    
    DynamoDBAttributeValue *hashPrefixAttribute = [[DynamoDBAttributeValue alloc] initWithS:prefix];
    DynamoDBAttributeValue *rangeValueAttribute = [[DynamoDBAttributeValue alloc] initWithS:user];
    
    
    NSMutableDictionary *keys = [NSMutableDictionary new];
    keys[PREFIX]    = hashPrefixAttribute;
    keys[USERNAME]  = rangeValueAttribute;
    
    
    // OK to use public credentials
    AmazonCredentials * creds = [[AmazonCredentials alloc] initWithAccessKey:PublicAccessKey
                                                               withSecretKey:PublictPassKey];
    AmazonDynamoDBClient * ddbClient = [[AmazonDynamoDBClient alloc] initWithCredentials:creds];
    
    
    DynamoDBGetItemRequest *getItemRequest = [[DynamoDBGetItemRequest alloc] initWithTableName:QPUSERS_SEARCH_TABLE
                                                                                        andKey:keys];
    getItemRequest.consistentRead = NO;
    
    
    [[QPNetworkActivity sharedInstance] increaseActivity];
    DynamoDBGetItemResponse *getItemResponse = [ddbClient getItem:getItemRequest];
    [[QPNetworkActivity sharedInstance] decreaseActivity];
    
    
    if (!getItemResponse.error)
    {
        NSMutableDictionary *item = getItemResponse.item;
        
        if ([item count])
        {
            NSString *username  = ((DynamoDBAttributeValue *)item[USERNAME]).s;
            NSString *realname  = ((DynamoDBAttributeValue *)item[REALNAME]).s;
            NSString *mediaType = ((DynamoDBAttributeValue *)item[MEDIATYPE]).s;
            NSData   *data      = ((DynamoDBAttributeValue *)item[DATA]).b;
            
            NSMutableDictionary *info = [NSMutableDictionary new];
            
            if (username)
                info[USERNAME]  = username;
            if (realname)
                info[REALNAME]  = realname;
            if (mediaType)
                info[MEDIATYPE] = mediaType;
            if (data)
            {
                info[DATA]      = data;
                info[IMAGE]     = [UIImage imageWithData:data];
            }
            return info;
        }
    }
    return nil;
}








/*
 * This will send any screen shot notifications that were stroed in core data
 and not sent yet
 */
#define SEND_BACKUP_NOTIFICATON @"SendingBackupNotifications"

+(void)sendScreenShotNotificationToServer:(NSString *)username inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSLog(@"sendScreenShotNotificationToServer");
    
    NSArray *screenshots = [Screenshot getScreenshotsNotificationToDeliver:username inManagedObjectContext:context];
    
    if (!screenshots)
        return;
    
    
    NSMutableArray *info = [NSMutableArray new];

    for (Screenshot *screenshotInfo in screenshots)
    {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        dictionary[USERNAME]  = screenshotInfo.me;
        dictionary[RECEIVER]  = screenshotInfo.receiver;
        dictionary[FILEPATH]  = screenshotInfo.filepath;
        
        [info addObject:dictionary];
    }
    
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    parameters[COMMAND] = SEND_BACKUP_NOTIFICATON;
    parameters[@"info"] = info;
    
    
    [KwikcyClientManager sendRequestWithParameters:parameters
                             withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
     {
         if (!error)
         {
             NSLog(@"screenShotTaken no error");
             KCServerResponse *serverResponse = (KCServerResponse *)response;
             
             if (received200Response)
             {
                 if (!serverResponse.successful)
                 {
                     //
                     //TODO: WIll we receive info about the successfuly delivered screenshot notifications???
                     
                 }
                 
                 // If successful delivered
                 else
                 {
                     //                     BOOL deletedSuccessfully = [Screenshot deleteScreenshotNotification:screenshots inManagedObjectContext:context];
                     
                 }
                 
                 BOOL deletedSuccessfully = [Screenshot deleteScreenshotNotification:screenshots inManagedObjectContext:context];
             }
         }
         else
         {
             //TODO: Add this for core data
             NSLog(@"screenShotTaken error");
             // Do nothing
         }
     }];
    
}





+(NSArray *)searchForUsernameSimilarToUsername:(NSString *)username
{
    username = [username lowercaseString];

    // OK to use public credentials
    AmazonCredentials * creds = [[AmazonCredentials alloc] initWithAccessKey:PublicAccessKey withSecretKey:PublictPassKey];
    
    AmazonDynamoDBClient * ddbClient = [[AmazonDynamoDBClient alloc] initWithCredentials:creds];
    ddbClient.timeout = 5;
    
    DynamoDBQueryRequest *queryRequest = [[DynamoDBQueryRequest alloc] initWithTableName:QPUSERS_SEARCH_TABLE];
    
    NSString *prefix = [Constants getPrefixForUsername:username];
    if (!prefix)
        return nil;
    
    // key and range
    DynamoDBAttributeValue *hashkeyAttribute = [[DynamoDBAttributeValue alloc] initWithS:prefix];
    DynamoDBAttributeValue *rangeAttribute   = [[DynamoDBAttributeValue alloc] initWithS:username];
    
    
    // Condition for pk (Select all bike with "M1" Name)
    DynamoDBCondition *primaryKeyCondition = [[DynamoDBCondition alloc] init];
    primaryKeyCondition.comparisonOperator = @"EQ";
    [primaryKeyCondition addAttributeValueList:hashkeyAttribute];
    
    
    // Condition for range (Select all bike Greater Then 2006 year)
    DynamoDBCondition *rangeCondition = [[DynamoDBCondition alloc] init];
    rangeCondition.comparisonOperator = @"BEGINS_WITH";
    [rangeCondition addAttributeValueList:rangeAttribute];
    
    
    // Setup all conditions
    NSMutableDictionary *conditions = [[NSMutableDictionary alloc] init];
    conditions[PREFIX]   = primaryKeyCondition;
    conditions[USERNAME] = rangeCondition;
    
    // Put in request
    queryRequest.keyConditions = conditions;
    queryRequest.limit = [NSNumber numberWithInt:20];
    queryRequest.consistentRead = NO;
    
    
    [[QPNetworkActivity sharedInstance] increaseActivity];
    DynamoDBQueryResponse *queryResponse = [ddbClient query:queryRequest];
    [[QPNetworkActivity sharedInstance] decreaseActivity];
    
    if (!queryResponse.error)
    {
        if ([queryResponse.count intValue])
        {
            NSMutableArray *users = [NSMutableArray new];
            for (NSDictionary *item in queryResponse.items)
            {
                //Only if a photo exists do we show user
                DynamoDBAttributeValue *data = item[DATA];
                if (data)
                {
                    NSMutableDictionary *dic = [NSMutableDictionary new];
                    dic[DATA] = data.b;
                    dic[USERNAME]  = ((DynamoDBAttributeValue*)item[USERNAME]).s;
                    
                    DynamoDBAttributeValue *realName = item[REALNAME];
                    if (realName)
                        dic[REALNAME] = realName.s;
                    
                    [users addObject:dic];
                }
            }
            return users;
        }
    }
    return nil;
}





+(UIImage *)getProfileImageForUser:(NSString *)user
{
    NSDictionary *item = [self getDetailsForUser:user];
    
    if (item)
        return item[IMAGE];
    
    return nil;
}






/*
 *  keys: array of @{KEY:[[DynamoDBAttributeValue alloc] initWithS:VALUE ]}
 *  arrayOfAttributes:  [NSMutableArray arrayWithObjects:ATTRIBUTE1, SENDER, FILEPATH, nil];
 *
 */

+(NSMutableDictionary *)batchGetItemsWithKeys:(NSMutableArray *)keys
         withAttributesToGet:(NSArray *)attributesToGet
                    forTable:(NSString *)table
{
    
    DynamoDBKeysAndAttributes *keysAndAttr = [[DynamoDBKeysAndAttributes alloc] init];
    
    // Create array of attributes to get
    
    keysAndAttr.keys = keys;
    keysAndAttr.attributesToGet = [attributesToGet mutableCopy];
    keysAndAttr.consistentRead = NO;
    
    NSMutableDictionary *d = [NSMutableDictionary new];
    d[table] = keysAndAttr;
    return d;
}


+(NSMutableArray *)getBatchRequestWithKeysAndAttributes:(NSMutableDictionary *)keysAndAttributes
{
    AmazonDynamoDBClient * ddbClient;
    
    if ([[[keysAndAttributes allKeys] firstObject] isEqualToString:QPUSERS_SEARCH_TABLE])
    {
        // OK to use public credentials
        AmazonCredentials * creds = [[AmazonCredentials alloc] initWithAccessKey:PublicAccessKey
                                                                   withSecretKey:PublictPassKey];
        ddbClient = [[AmazonDynamoDBClient alloc] initWithCredentials:creds];
    }
    else
        ddbClient = [AmazonClientManager ddb];
    
    
    
    
    
    DynamoDBBatchGetItemRequest *batchGetItemRequest = [[DynamoDBBatchGetItemRequest alloc] init];
    batchGetItemRequest.requestItems = keysAndAttributes;
    
    
    [[QPNetworkActivity sharedInstance] increaseActivity];
    DynamoDBBatchGetItemResponse *batchGetItemResponse = [ddbClient batchGetItem:batchGetItemRequest];
    [[QPNetworkActivity sharedInstance] decreaseActivity];
    
    NSMutableArray * batchResults = [NSMutableArray array];

    if(!batchGetItemResponse.error && batchGetItemResponse.responses.count)
    {
        NSArray *tableKeys = [batchGetItemResponse.responses allKeys];
        for (NSString *tableName in tableKeys)
        {
            NSArray *arrayOfDictionaryResults = batchGetItemResponse.responses[tableName];
            for (NSDictionary *dictionaryResult in arrayOfDictionaryResults)
            {
                
                NSMutableDictionary* results = [NSMutableDictionary dictionary];
                
                NSArray *allKeys = [dictionaryResult allKeys];
                
                for (NSString *key in allKeys)
                {
                    if (((DynamoDBAttributeValue*)dictionaryResult[key]).s)
                        results[key] = ((DynamoDBAttributeValue*)dictionaryResult[key]).s;
                    else if (((DynamoDBAttributeValue*)dictionaryResult[key]).n)
                        results[key] = ((DynamoDBAttributeValue*)dictionaryResult[key]).n;
                    else if (((DynamoDBAttributeValue*)dictionaryResult[key]).b)
                        results[key] = ((DynamoDBAttributeValue*)dictionaryResult[key]).b;
                }
                [batchResults addObject:results];
            }
        }
    }
    else if (batchGetItemResponse.error)
        NSLog(@"batchGetItemsWithKeys error %@", batchGetItemResponse.error);
    else
        NSLog(@"batchGetItemsWithKeys no results ");

    
    if ([batchResults count])
        return batchResults;
    else
        return nil;
}

+(void)getContactsIfNeeded:(NSString *)username inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSLog(@"getContactsIfNeeded called");
    // app never launched for user
    // This is the first launch ever for this user on this iPhone
    
    NSString *launchedForUser = [NSString stringWithFormat:@"%@%@", @"HasLaunchedOnceForUser", username];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:launchedForUser])
    {
    
        NSLog(@"launchedForUser only once ");
        NSMutableDictionary *parameters = [NSMutableDictionary new];
        parameters[COMMAND] = GET_ALL_CONTACTS;
        
        
        
        [KwikcyClientManager sendRequestWithParameters:parameters
                                 withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
         {
             if (error)
             {
                 //TODO: DELETE THIS AND FOR EVER OTHER
                 [[Constants alertWithTitle:@"Connection Error"
                                 andMessage:@"Could not send request due to a connection error"] show];
             }
             else
             {
                 KCServerResponse *serverResponse = (KCServerResponse *)response;
                 
                 // Still can be error
                 if (received200Response)
                 {
                     if (serverResponse.successful)
                     {
                         // Add all contacts to core data base and relaod Contacts
                         
                         NSLog(@"getContactsIfNeeded: launchedForUser only once %@", serverResponse.info);

                         NSArray *users = serverResponse.info[CONTACTS];
                         
                         if ([users count])
                         {
                             NSMutableArray *arrayOfKeys = [[NSMutableArray alloc] init];
                             
                             for (NSDictionary *user in users)
                             {

                                 [arrayOfKeys addObject:@{PREFIX:[[DynamoDBAttributeValue alloc] initWithS:[Constants getPrefixForUsername:user[USERNAME]]],
                                                          USERNAME:[[DynamoDBAttributeValue alloc] initWithS:user[USERNAME]]
                                                          }
                                  ];
                             }
                             
                             
                             NSMutableDictionary *requestItems = [KwikcyAWSRequest batchGetItemsWithKeys:arrayOfKeys
                                                                              withAttributesToGet:nil
                                                                                         forTable:QPUSERS_SEARCH_TABLE];
                             
                             NSMutableArray* contactsInfo = [KwikcyAWSRequest getBatchRequestWithKeysAndAttributes:requestItems];
                             
                             for (NSMutableDictionary *contact in contactsInfo)
                             {
                                 for (NSDictionary *user in users)
                                 {
                                     if ([user[USERNAME] isEqualToString:contact[USERNAME]])
                                         contact[STATUS] = user[STATUS];
                                 }
                             }
                             
                             if (contactsInfo && context)
                             {
                                 [context performBlock:^{
                                     [User insertAllUsers:contactsInfo inManagedObjectContext:context];
                                 }];
                             }
                         }
                         
                         //  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:launchedForUser];
                         //  [[NSUserDefaults standardUserDefaults] synchronize];
                     }
                     // Could be unsuccessful or Error
                     else
                     {
                         NSLog(@"Response unsuccessful contacts");
                         
                         //Update core data with message
                         //                         [[Constants alertWithTitle:@"Error" andMessage:serverResponse.message] show];
                     }
                 }
             }
         }];
    }
}










+(void)sendUserIsActiveToServer:(NSString *)username
{
    NSLog(@"sendUserIsActiveToServer called");
    username = [username lowercaseString];
    
    if (username)
    {
        //Send kwikcyServer user is active command
        
        NSMutableDictionary *parameters = [NSMutableDictionary new];
        parameters[COMMAND]  = USER_IS_ACTIVE_TODAY;
        
        [KwikcyClientManager sendRequestWithParameters:parameters
                                                withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
         {
             if (!error)
             {
                 NSLog(@"USER_IS_ACTIVE_TODAY no error");
                 
                 
                 NSManagedObjectContext *moc =  [QPCoreDataManager sharedInstance].managedObjectContext;
                 if (moc)
                 {
                         [KwikcyAWSRequest getContactsIfNeeded:username
                                        inManagedObjectContext:moc] ;
                 }
             }
             else
                 NSLog(@"USER_IS_ACTIVE_TODAY error");
         }];
    }
}



+(void)userIsActive:(NSString *)username
{
    NSLog(@"userIsActive called");
    if (!username)
        return;
    
    //TODO DELTE THIS, DONE ON LOG IN????
    NSDate *todaysDate = [NSDate date];
    
    NSString *key = [NSString stringWithFormat:@"%@-%@", DATE, username];
    
    
    
    NSDate *lastDate = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
    
    
    if (!lastDate)
    {
        //Send kwikcyServer user is active command
        [KwikcyAWSRequest sendUserIsActiveToServer:username];
        
        [[NSUserDefaults standardUserDefaults] setObject:todaysDate forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else
    {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSInteger   comps    = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
        
        NSDateComponents *todaysDateComponents  = [calendar components:comps
                                                              fromDate: todaysDate];
        NSDateComponents *lastDateComponents    = [calendar components:comps
                                                              fromDate: lastDate];
        
        todaysDate = [calendar dateFromComponents:todaysDateComponents];
        lastDate   = [calendar dateFromComponents:lastDateComponents];
        
        NSComparisonResult result = [todaysDate compare:lastDate];
        
        if (result != NSOrderedSame)
        {
            //Send kwikcyServer user is active command
            [KwikcyAWSRequest sendUserIsActiveToServer:username];
            
            [[NSUserDefaults standardUserDefaults] setObject:todaysDate forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}


/*
 *  table = NOTIFICATION_TABLE,     hashKey = NOTIFICATION_HASH_KEY
 *  table = REVENGE_POINTS_TABLE,   hashKey = REVENGE_HASH_KEY
 */


/*
 *  TODO: make this a doWhile loop and use  queryResponse.lastEvaluatedKey
 */

+(NSMutableArray *)getNotificationsForTable:(NSString *)table
                                withHashKey:(NSString *)hashKey
                              forAttributes:(NSMutableArray *)attributes
{
    NSMutableArray *newNotifications = [NSMutableArray array];
    
    
    NSString *username = [AmazonKeyChainWrapper username];
    
    DynamoDBQueryRequest *queryRequest = [[DynamoDBQueryRequest alloc] initWithTableName:table];
    
    
    DynamoDBAttributeValue *hashKeyAttribute = [[DynamoDBAttributeValue alloc] initWithS:username];
    
    DynamoDBCondition *primaryKeyCondition = [[DynamoDBCondition alloc] init];
    primaryKeyCondition.comparisonOperator = @"EQ";
    [primaryKeyCondition addAttributeValueList:hashKeyAttribute];
    
    
    // Setup all conditions
    NSMutableDictionary *conditions = [[NSMutableDictionary alloc] init];
    conditions[hashKey] = primaryKeyCondition;
    
    // Put in request
    queryRequest.keyConditions = conditions;
    queryRequest.consistentRead = NO;
    queryRequest.attributesToGet = attributes;
    
    
    [[QPNetworkActivity sharedInstance] increaseActivity];
    DynamoDBQueryResponse *queryResponse = [[AmazonClientManager ddb] query:queryRequest];
    [[QPNetworkActivity sharedInstance] decreaseActivity];
    
    
    if (!queryResponse.error)
    {
        if ([queryResponse.count integerValue])
        {
            NSMutableArray *notifications = queryResponse.items;
            
            if ([table isEqualToString:NOTIFICATION_TABLE])
            {
                for (NSDictionary *dic  in notifications)
                {
                    
                    NSString *us          = ((DynamoDBAttributeValue *)dic[USERNAME]).s;
                    //                    NSString *dateSender        = ((DynamoDBAttributeValue *)dic[DATE_SENDER]).s;
                    NSString *filepath          = ((DynamoDBAttributeValue *)dic[FILEPATH]).s;
                    NSString *notificationType  = ((DynamoDBAttributeValue *)dic[NOTIFICATION]).s;
                    NSString *date              = ((DynamoDBAttributeValue *)dic[DATE]).s;
                 
                    NSString *clickable         = ((DynamoDBAttributeValue *)dic[CLICKABLE]).s;

                    NSLog(@"MESSAGE notificationType %@", notificationType);

                    
                    if([notificationType isEqualToString:SCREENSHOT_NOTIFICATION])
                    {
                        NSString *screenshotTaker   = ((DynamoDBAttributeValue *)dic[SENDER]).s;
                        
                        
                        
                        [newNotifications addObject:[NSMutableDictionary dictionaryWithDictionary:
                                                      @{USERNAME     : us,
                                                        FILEPATH     : filepath,
                                                        SENDER       : screenshotTaker,
                                                        DATE         : date,
                                                        NOTIFICATION : notificationType,
                                                        CLICKABLE    : ([clickable isEqualToString:@"y"] ? @(YES) : @(NO))
                                                      }]
                         ];
                        
                    }
                    else if([notificationType isEqualToString:REQUEST_TO_ADD_CONTACT] ||
                            [notificationType isEqualToString:RESPONSE_TO_ADD_CONTACT] )
                    {
                        NSString *requester     = ((DynamoDBAttributeValue *)dic[SENDER]).s;
                        
                        NSString *message       = ((DynamoDBAttributeValue *)dic[MESSAGE]).s;
                        
                        [newNotifications addObject:[NSMutableDictionary dictionaryWithDictionary:
                                                      @{USERNAME     : us,
                                                        FILEPATH     : filepath,
                                                        SENDER       : requester,
                                                        DATE         : date,
                                                        NOTIFICATION : notificationType,
                                                        MESSAGE      : message,
                                                        CLICKABLE    : ([clickable isEqualToString:@"y"] ? @(YES) : @(NO))
                                                        }]
                         ];
                    }
                    else if([notificationType isEqualToString:NOTICE])
                    {
                        NSString *from     = ((DynamoDBAttributeValue *)dic[SENDER]).s;
                        
                        NSString *message       = ((DynamoDBAttributeValue *)dic[MESSAGE]).s;
                        
                        NSLog(@"MESSAGE %@", message);
                        
                        [newNotifications addObject:[NSMutableDictionary dictionaryWithDictionary:
                                                     @{USERNAME     : us,
                                                       FILEPATH     : filepath,
                                                       SENDER       : from,
                                                       DATE         : date,
                                                       NOTIFICATION : notificationType,
                                                       MESSAGE      : message,
                                                       CLICKABLE    : ([clickable isEqualToString:@"y"] ? @(YES) : @(NO))
                                                       }]
                         ];
                    }
                    
                    //                    else if([notificationType isEqualToString:DENIED_RESPONSE])
                    //                    {
                    //
                    //                    }
                    //                    else if([notificationType isEqualToString:BLOCKED_RESPONSE])
                    //                    {
                    //
                    //                    }
                    
                }
            }
            
            
            
            //anthing that requires selectedSegmentIndex should be replaced like below use table names as condition and return
            
            else if ([table isEqualToString:REVENGE_POINTS_TABLE])
            {
                NSLog(@"notifications getItem no error, REVENGE_POINTS_SEGMENT_CONTROL");
                
                for (NSDictionary *dic in notifications)
                {
                    NSString *revengeAgainst    = ((DynamoDBAttributeValue *)dic[REVENGE_RANGE_KEY_AGAINST]).s;
                    NSString *points            = ((DynamoDBAttributeValue *)dic[REVENGE_POINTS]).n;
                    
                    NSLog(@"notifications REVENGE_POINTS_SEGMENT_CONTROL points = %d", points);

                    if (!points)
                        points = @"0";
                    
                    [newNotifications addObject:[NSMutableDictionary dictionaryWithDictionary:
                                                 @{REVENGE_RANGE_KEY_AGAINST: revengeAgainst,
                                                   REVENGE_POINTS           : points,
                                                   CLICKABLE                : [points isEqualToString:@"0"] ? @(NO) : @(YES)
                                                   }]];
                }
            }
        }
    }
    return newNotifications;
}





@end
