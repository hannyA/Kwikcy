//
//  Sent_message+methods.m
//  Quickpeck
//
//  Created by Hanny Aly on 7/9/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "Sent_message+methods.h"
#import "Constants.h"
#import "AmazonKeyChainWrapper.h"

@implementation Sent_message (methods)

+(void)appCleanUpInManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SENT_MESSAGE_TABLE];
    request.sortDescriptors = nil;
    request.predicate =  nil;
    
    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (matches && [matches count]) {
        int count = 0;
        for (NSManagedObject *message in matches) {
            NSLog(@"Deleted %d", ++count);
            [context deleteObject:message];
        }
// Commit the change.

        NSError *error = nil;

        if (![context save:&error]) {
            // Handle the error.
            NSLog(@"Error: Received_message insertS3ObjectwithName failed to save");
        }
    }
    
}



+(BOOL)addEmptyStringInManagedObjectContext:(NSManagedObjectContext *)context
{
    BOOL emptyStringExists = [Sent_message doesEmptyStringExistInManagedObjectContext:context];
    
    if (!emptyStringExists)
    {
     
        Sent_message *message = [NSEntityDescription insertNewObjectForEntityForName:SENT_MESSAGE_TABLE inManagedObjectContext:context];
        message.status = EMPTY;
        
        
        NSError *error = nil;
        if (![context save:&error]) {
            // Handle the error.
            NSLog(@"Error storing image in coredata: %@", error);
            return NO;
        }
        return YES;
    }
    return YES;
}


+(BOOL)doesEmptyStringExistInManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SENT_MESSAGE_TABLE];
    request.sortDescriptors = nil;
    request.predicate = [NSPredicate predicateWithFormat:@"status = %@", EMPTY];
    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (error)
    {
        NSLog(@"doesEmptyStringExistInManagedObjectContext error executeFetchRequest");
    }
    
    if (matches && [matches count] )
    {
        NSLog(@"doesEmptyStringExistInManagedObjectContext has one object");
        
        NSUInteger matchesCount = [matches count];
        if (matchesCount > 1)
        {
            NSLog(@"doesEmptyStringExistInManagedObjectContext matchesCount > 1");
            
            while (matchesCount > 1){
                [context deleteObject:matches[--matchesCount]];
            }
            NSError *error = nil;
            if (![context save:&error])
            {
                // Handle the error.
                NSLog(@"Error storing image in coredata: %@", error);
            }
        }
        
        return YES;
    }
    else
        return NO;
}



+(void)removeEmptyStringInManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SENT_MESSAGE_TABLE];
    request.sortDescriptors = nil;
    request.predicate = [NSPredicate predicateWithFormat:@"status = %@", EMPTY];
    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (matches && [matches count] > 1 ) {
        NSLog(@"removeEmptyStringInManagedObjectContext has one object");
        
        [context deleteObject:[matches lastObject]];
        
        NSError *error = nil;
        
        if (![context save:&error]) {
            // Handle the error.
            NSLog(@"Error: Received_message insertS3ObjectwithName failed to save");
        }
    }
    else
        NSLog(@"Error: removeEmptyStringInManagedObjectContext had no string");
    
}

//+(void)removeEmptyStringForMedia:(NSString *)mediatype inManagedObjectContext:(NSManagedObjectContext *)context
//{
//    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SENT_MESSAGE_TABLE];
//    request.sortDescriptors = nil;
//    request.predicate = [NSPredicate predicateWithFormat:@"status = %@", EMPTY];
//    
//    // Execute the fetch
//    
//    NSError *error = nil;
//    NSArray *matches = [context executeFetchRequest:request error:&error];
//    
//    if (matches && [matches count] == 1 ) {
//        NSLog(@"removeEmptyStringInManagedObjectContext has one object");
//
//        [context deleteObject:[matches lastObject]];
//  
//        NSError *error = nil;
//        
//        if (![context save:&error]) {
//            // Handle the error.
//            NSLog(@"Error: Received_message insertS3ObjectwithName failed to save");
//        }
//    }
//    else
//        NSLog(@"Error: removeEmptyStringInManagedObjectContext had no string");
//}







// Insert message the user sent with photo/vid
+ (void) insertSentMessageWithInfo:(NSDictionary *)messageDictionary inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSLog(@"insertSentMessageWithInfo");
    
    
    Sent_message *message = [NSEntityDescription insertNewObjectForEntityForName:SENT_MESSAGE_TABLE
                                                          inManagedObjectContext:context];
    
    message.sender = messageDictionary[SENDER];
    message.status = @"0.1";
    if ( messageDictionary[MESSAGE] != [NSNull null])
        message.message = messageDictionary[MESSAGE];
    
    message.receivers   = messageDictionary[RECEIVERS];
    message.mediaType   = messageDictionary[MEDIATYPE];
    message.filepath    = messageDictionary[FILEPATH];
    message.date        = messageDictionary[DATE];
   
    
    NSError *error = nil;
    
    if (![context save:&error]) {
        
        // Handle the error.
        NSLog(@"Error storing image in coredata: %@", error);
    }
}



/* Used for sending View Controller */

+(void)updateSentFile:theFilepath withProgress:(NSNumber *)percentComplete inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SENT_MESSAGE_TABLE];
    request.sortDescriptors = nil;
    request.predicate = [NSPredicate predicateWithFormat:@"(sender = %@) AND (filepath = %@)",[AmazonKeyChainWrapper username], theFilepath];
    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (error)
    {
        NSLog(@"Error getting updateSentFile Sent_Method.h: %@", error);
        return;
    }
    
    if (matches && [matches count] == 1 )
    {
        Sent_message *message = [matches lastObject];
        
        if ([percentComplete floatValue] == 1)
            message.status = PENDING;
        else
            message.status = [percentComplete stringValue];
       
        if (![context save:&error]) {
            // Handle the error.
            NSLog(@"Error in Sent_message_methods updateMessageWithStatus");
        }
    }
}





/* 
 * Message called from QPSentMessageCDTVM by refreshByButton
 * Updates the statuses if any from DynamoDB 
 */

+ (void)updateMessageWithStatus:(NSDictionary *)messageDictionary inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SENT_MESSAGE_TABLE];
    request.sortDescriptors = nil;
    request.predicate = [NSPredicate predicateWithFormat:@"(sender = %@) AND (filepath = %@)", messageDictionary[SENDER], messageDictionary[FILEPATH]];
    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (matches && [matches count] == 1 )
    {
        Sent_message *message = [matches lastObject];
        
        if (messageDictionary[STATUS])
            message.status = messageDictionary[STATUS];
        else if (messageDictionary[UNSEND_KEY])
            message.unsend_key = messageDictionary[UNSEND_KEY];
        
        if (![context save:&error])
        {
            // Handle the error.
            NSLog(@"Error in Sent_message_methods updateMessageWithStatus");
        }
    }
} 


/*
 * Returns all pending messages regardless of media type
 * The array is used in a DynamoDB Batch Request
 */
+ (NSArray *)getMessagesWithPendingStatusinManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SENT_MESSAGE_TABLE];
    request.sortDescriptors =     @[[NSSortDescriptor sortDescriptorWithKey:DATE ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)]];
    request.predicate = [NSPredicate predicateWithFormat:@"(sender = %@) AND (status = %@)", [AmazonKeyChainWrapper username], PENDING];
    
    

    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];

    if (error)
    {
        return [NSArray array];
    }
    
    if (matches && [matches count]) {
        //There are still pending messages. Get the primary hash and range keys and pass them back in array to go search DynamoDB

        return matches;
    }
    else
    {
        // Don't send a request message to database. End refresh
        return matches;
    }
}



// Returns array of messagse that will be deleted by clear button

+ (NSArray *)getMessagesToDelete:(NSUInteger)QPSegmentControlMedia withManagedObjectContext:(NSManagedObjectContext *)context
{    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SENT_MESSAGE_TABLE];
    request.sortDescriptors = nil;
    
    if (QPSegmentControlMedia == QPSegmentControlTypePhoto)
        request.predicate = [NSPredicate predicateWithFormat:@"(sender = %@) AND (mediaType = %@)",[AmazonKeyChainWrapper username], IMAGE];
    else if (QPSegmentControlMedia == QPSegmentControlTypeVideo)
        request.predicate = [NSPredicate predicateWithFormat:@"(sender = %@) AND (mediaType = %@)",[AmazonKeyChainWrapper username],  VIDEO];
    else if (QPSegmentControlMedia == QPSegmentControlTypeAudio)
        request.predicate = [NSPredicate predicateWithFormat:@"(sender = %@) AND (mediaType = %@)",[AmazonKeyChainWrapper username],  AUDIO];
    else
        request.predicate = [NSPredicate predicateWithFormat:@"(sender = %@) AND ((mediaType = %@) OR (mediaType = %@) OR (mediaType = %@) OR (mediaType = %@) )", [AmazonKeyChainWrapper username], IMAGE, VIDEO, AUDIO, TEXT];
    
    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    //error returns nil
    if (error)
        return [NSArray array];
    
    //no error will return at minimum an empty array
    return matches;
}




// Deletes array of messages

+ (BOOL)removeMessages:(NSArray *)array withManagedObjectContext:(NSManagedObjectContext *)context
{
    
    //Delete array of messages
    if (array && [array count]) {
        
        int count = 0;
        for (Sent_message *message in array) {
            ++count;
            NSLog(@"Deleted sent message %d", count);
            [context deleteObject:message];
        }
        // Commit the change.
        
        NSError *error = nil;
        if (![context save:&error]) {
            // Handle the error.
            NSLog(@"Error: Received_message insertS3ObjectwithName failed to save");
        }
        
        if (count)
            return YES;
    }
    return NO;
}










+ (NSString *)getStatusOfMessage:(Sent_message *)message inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SENT_MESSAGE_TABLE];
    request.sortDescriptors = nil;
    request.predicate = [NSPredicate predicateWithFormat:@"(sender = %@) AND (filepath = %@)", message.sender, message.filepath];
    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (matches && [matches count] == 1 )
    {
        Sent_message *sendMessage = [matches lastObject];
        NSLog(@"getStatusOfMessage %@", sendMessage.status);
        return sendMessage.status;
    }
    return nil;
}










/*
 * Removes messages from core data
 * There are no delete_marker for sent messages
 */
//+ (NSArray *)clearMessagesFromMedia:(NSUInteger)QPSegmentControlMedia withManagedObjectContext:(NSManagedObjectContext *)context
//{
//    NSLog(@"Should clear data from sending %d", QPSegmentControlMedia);
//    
//    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SENT_MESSAGE_TABLE];
//    request.sortDescriptors = nil;
//    
//    if (QPSegmentControlMedia == QPSegmentControlTypePhoto)
//        request.predicate = [NSPredicate predicateWithFormat:@"mediaType = %@", IMAGE];
//    else if (QPSegmentControlMedia == QPSegmentControlTypeVideo)
//        request.predicate = [NSPredicate predicateWithFormat:@"mediaType = %@", VIDEO];
//    else if (QPSegmentControlMedia == QPSegmentControlTypeAudio)
//        request.predicate = [NSPredicate predicateWithFormat:@"mediaType = %@", AUDIO];
//    else
//        request.predicate = nil;
//    
//    // Execute the fetch
//    
//    NSError *error = nil;
//    NSArray *matches = [context executeFetchRequest:request error:&error];
//    
//    if (matches && [matches count]) {        
//        int count = 0;
//        for (Sent_message *message in matches) {
//            NSLog(@"Deleted sent message %d", ++count);
//            [context deleteObject:message];
//        }
//        // Commit the change.
//        
//        NSError *error = nil;
//        
//        if (![context save:&error]) {
//            // Handle the error.
//            NSLog(@"Error: Received_message insertS3ObjectwithName failed to save");
//        }
//    }
//    else {
//        if (matches)
//            NSLog(@"Fetching worked but no matches %d", [matches count]);
//        else
//            NSLog(@"Error could not fetch");
//    }
//    return matches;
//
//}



@end
