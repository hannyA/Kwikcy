//
//  Received_message+methods.h
//  Quickpeck
//
//  Created by Hanny Aly on 7/12/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "Received_message.h"

@interface Received_message (methods)

/*
 * Purpose of delete_marker: dynamodb is not atomic. So we need to delete things from dynamodb without the user
 * being able to quickly query and get the same data again.
 *
 * So we cache the data on the users side so that queried data that we've already seen can be ignored.
 *
 * We then delete the data later in the day. Though this can be done within a few seconds, to be safe we do it 30 seonds later
 *
 */


/* Called in AppDelegate.m on first launch of app, to insert an empty row for database*/
+(BOOL)addEmptyStringInManagedObjectContext:(NSManagedObjectContext *)context;
//+(void)removeEmptyStringInManagedObjectContext:(NSManagedObjectContext *)context;

/* This is used for development purposes only to remove all data from core data */
+(void)appCleanUpInManagedObjectContext:(NSManagedObjectContext *)context;

/* This should be called once a day or so, to remove all rows with delete_marker = "YES" */
+(void)removeDeletedData_Once_A_Day_ManagedObjectContext:(NSManagedObjectContext *)context;


/* Here is where we actually delete messages from core data */
+(NSArray *)removeAllMessagesFromCoreDataForMediaType:(NSUInteger)MediaTypeToUpload inManagedObjectContext:(NSManagedObjectContext *)context;


/* Updates message with date and sets delete_marker = YES */
+(void)markMessageForDeletion:(NSArray *)messages inManagedObjectContext:(NSManagedObjectContext *)context;



+(NSUInteger)insertFromKwikcyServerDynamoDBMessages:(NSArray *)messages inManagedObjectContext:(NSManagedObjectContext *)context;


/* Insert all messages from dynamodb in core data */
+(NSUInteger)insertDynamoDBMessages:(NSArray *)messages inManagedObjectContext:(NSManagedObjectContext *)context;



/* Returns all data we want to delete,  but we don't actually delete it here */
+(NSArray *)getAllReceivedMessagesToDeleteforMediaType:(NSUInteger)MediaTypeToUpload inManagedContext:(NSManagedObjectContext *)context;

/* update the status for message */
+(void )updateStatusToYesForMessage:(Received_message *)message inManagedObjectContext:(NSManagedObjectContext *)context;

@end
