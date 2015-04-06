//
//  Sent_message+methods.h
//  Quickpeck
//
//  Created by Hanny Aly on 7/9/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "Sent_message.h"

@interface Sent_message (methods)

/* 
 * Used for debugging
 */
+(void)appCleanUpInManagedObjectContext:(NSManagedObjectContext *)context;


/* Insert new message */
+(void)insertSentMessageWithInfo:(NSDictionary *)messageDictionary inManagedObjectContext:(NSManagedObjectContext *)context;


/* Updates sending message for progress bar */
+(void)updateSentFile:theFilepath withProgress:(NSNumber *)percentComplete inManagedObjectContext:(NSManagedObjectContext *)context;

/* Get and Update sent messages */
+ (NSArray *)getMessagesWithPendingStatusinManagedObjectContext:(NSManagedObjectContext *)context;
+ (void)updateMessageWithStatus:(NSDictionary *)messageDictionary inManagedObjectContext:(NSManagedObjectContext *)context;

/* 
 * Used for clear button. Gets objects to delete from dynamodb and then removes from core data
 */
+ (NSArray *)getMessagesToDelete:(NSUInteger)QPSegmentControlMedia withManagedObjectContext:(NSManagedObjectContext *)context;
+ (BOOL)removeMessages:(NSArray *)array withManagedObjectContext:(NSManagedObjectContext *)context;


/*
 * Remove and add empty strings 
 */
//+(void)removeEmptyStringForMedia:(NSString *)mediatype inManagedObjectContext:(NSManagedObjectContext *)context;
+(BOOL)addEmptyStringInManagedObjectContext:(NSManagedObjectContext *)context;
+(BOOL)doesEmptyStringExistInManagedObjectContext:(NSManagedObjectContext *)context;


+ (NSString *)getStatusOfMessage:(Sent_message *)message inManagedObjectContext:(NSManagedObjectContext *)context;

@end
