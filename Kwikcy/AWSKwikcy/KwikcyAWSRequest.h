//
//  KwikcyAWSRequest.h
//  Kwikcy
//
//  Created by Hanny Aly on 8/9/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KwikcyAWSRequest : NSObject


+(NSArray *)searchForUsernameSimilarToUsername:(NSString *)username;


//+(void)sendUserIsActiveToServer:(NSString *)username;
+(void)userIsActive:(NSString *)username;



+(void)sendScreenShotNotificationToServer:(NSString *)username inManagedObjectContext:(NSManagedObjectContext *)context;

+(UIImage *)getProfileImageForUser:(NSString *)user;
+(NSMutableDictionary *)getDetailsForUser:(NSString *)user;


+(void)synchronizeContacts;


+(NSMutableDictionary *)batchGetItemsWithKeys:(NSMutableArray *)keys
                   withAttributesToGet:(NSArray *)attributesToGet
                              forTable:(NSString *)table;

+(NSMutableArray *)getBatchRequestWithKeysAndAttributes:(NSMutableDictionary *)keysAndAttributes;


+(void)getContactsIfNeeded:(NSString *)username inManagedObjectContext:(NSManagedObjectContext *)context;



+(NSMutableArray *)getNotificationsForTable:(NSString *)table
                                withHashKey:(NSString *)hashKey
                              forAttributes:(NSMutableArray *)attributes;

@end
