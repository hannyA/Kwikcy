//
//  Received_message+methods.m
//  Quickpeck
//
//  Created by Hanny Aly on 7/12/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//
#import <AWSDynamoDB/AWSDynamoDB.h>
#import "Received_message+methods.h"
#import "Constants.h"
#import "AmazonKeyChainWrapper.h"

@implementation Received_message (methods)




+(BOOL)doesEmptyStringExistInManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:RECEIVED_MESSAGE_TABLE];
    request.predicate = [NSPredicate predicateWithFormat:@"view_status = %@", EMPTY];
    request.sortDescriptors = nil;
    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (matches && [matches count] ) {
        NSLog(@"doesEmptyStringExistInManagedObjectContext has one object");
        
        NSUInteger matchesCount = [matches count];
        if (matchesCount > 1){
            NSLog(@"doesEmptyStringExistInManagedObjectContext matchesCount > 1");

            while (matchesCount > 1){
                [context deleteObject:matches[matchesCount]];
                matchesCount--;
            }
            NSError *error = nil;
            if (![context save:&error]) {
                // Handle the error.
                NSLog(@"Error storing image in coredata: %@", error);
            }
        }
        
        return YES;
    }
    else
        return NO;
    
}

+(BOOL)addEmptyStringInManagedObjectContext:(NSManagedObjectContext *)context
{
    NSLog(@"addEmptyStringForMedia");
    
    BOOL emptyStringExists = [Received_message doesEmptyStringExistInManagedObjectContext:context];
    NSLog(@"emptyStringExists = %@", emptyStringExists? @"YES":@"NO");
    
    if (!emptyStringExists){
        Received_message *message = [NSEntityDescription insertNewObjectForEntityForName:RECEIVED_MESSAGE_TABLE inManagedObjectContext:context];
        
        message.view_status = @"empty";

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








/*
 * This function removes all messages from the Received Table  for debuggin purposes
 */
+(void)appCleanUpInManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:RECEIVED_MESSAGE_TABLE];
    request.sortDescriptors = nil;
    request.predicate =  nil;
    
    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (matches && [matches count]) {
        NSLog(@"Deleting current data in Received message");
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


/*
 * This function removes all messages WHERE delete_marker = "YES".
 *
 * It is not called by user, but sparingly.
 *
 * This function is called once every day or so
 */

+(void)removeDeletedData_Once_A_Day_ManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:RECEIVED_MESSAGE_TABLE];
    request.predicate = [NSPredicate predicateWithFormat:@"me = %@ AND delete_marker = %@",
                                                [AmazonKeyChainWrapper username], @"YES"];
    request.sortDescriptors = nil;
    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
   
    if (matches && [matches count]) {
        NSLog(@"Deleting current data in Received message");
        int count = 0;
        for (NSManagedObject *message in matches) {
            NSLog(@"Deleted %d", ++count);
            [context deleteObject:message];
        }
        // Commit the change.
        
//        NSError *error = nil;
//        
//        if (![context save:&error]) {
//            // Handle the error.
//            NSLog(@"Error: Received_message removeDeletedData_Once_A_Day_ManagedObjectContext failed to save the deletion");
//        }
    }
}




/*
 * ERROR with this function: Cannot remove objects while enumerating through list
 * 
 * Removes all messages for the given type of media (image, photo audio)
 *
 * This function is called once every day or so
 */

+(NSMutableArray *)removeAllMessagesFromCoreDataForMediaType:(NSUInteger)MediaTypeToUpload inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:RECEIVED_MESSAGE_TABLE];
    request.sortDescriptors = nil;
    
    if (MediaTypeToUpload == QPSegmentControlTypePhoto)
        request.predicate = [NSPredicate predicateWithFormat:@"me = %@ AND mediaType = %@",
                                                            [AmazonKeyChainWrapper username], IMAGE];
    else if (MediaTypeToUpload == QPSegmentControlTypeVideo)
        request.predicate = [NSPredicate predicateWithFormat:@"me = %@ AND mediaType = %@",
                                                            [AmazonKeyChainWrapper username], VIDEO];
    else if (MediaTypeToUpload == QPSegmentControlTypeAudio)
        request.predicate = [NSPredicate predicateWithFormat:@"me = %@ AND mediaType = %@",
                                                            [AmazonKeyChainWrapper username], AUDIO];
    else
        request.predicate = [NSPredicate predicateWithFormat:@"me = %@ AND ( (mediaType = %@) OR (mediaType = %@) OR (mediaType = %@) OR (mediaType = %@))",
                             [AmazonKeyChainWrapper username], IMAGE, VIDEO, AUDIO, TEXT];
    
    // Execute the fetch
     
    NSError *error = nil;
    NSMutableArray *matches = [[context executeFetchRequest:request error:&error] mutableCopy];
    
    if (matches && [matches count])
    {
        NSDate * today = [NSDate date];
        
        NSLog(@"Deleting current data in Received message");
        int count = 0;
        for (Received_message *message in matches) {
            NSLog(@"Deleted %d", ++count);
            
            NSTimeInterval time_difference = [today timeIntervalSinceDate:message.delete_date];

            if ([message.delete_marker isEqualToString:@"YES"] && fabs(time_difference) > 120)
                [context deleteObject:message];
            else
                [matches removeObject:message];
        }
        
        // Commit the change.
//        NSError *error = nil;
//        
//        if (![context save:&error]) {
//            // Handle the error.
//            NSLog(@"Error: Received_message insertS3ObjectwithName failed to save");
//        }
        return matches;

    }
    else
        return nil;

}


+(void )updateStatusToYesForMessage:(Received_message *)message inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSLog(@"Received_message message update to yes");
    
    message.view_status = @"YES";
    
    NSError *error = nil;
    
    if (![context save:&error]) {
        // Handle the error.
        NSLog(@"commitEditingStyle managedObjectContext error");
    } 
}

// Updates message with date and delete_marker

/*
        delete_marker with value of NO is visible to user 
        They have delete manually or clear it
        delete_marker with value of YES is not visible to user
 */
+(void)markMessageForDeletion:(NSArray *)messages inManagedObjectContext:(NSManagedObjectContext *)context
{
    for (Received_message *message in messages)
    {
        [message setDelete_marker:@"YES"];
        [message setDelete_date:[NSDate date]];
    }
    
    NSError *error = nil;
    
    if (![context save:&error]) {
        // Handle the error.
        NSLog(@"commitEditingStyle managedObjectContext error");
    }
}










+(NSUInteger)insertFromKwikcyServerDynamoDBMessages:(NSArray *)messages inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSUInteger count = 0;
    
    NSArray *messagesInCoreData = [Received_message getAllReceivedMessagesThat_Already_Got_From_DynamoDB_ForMediaType:QPSegmentControlTypeNone inManagedContext:context];
    
    
    if (!messagesInCoreData)
    {
        NSLog(@"messagesInCoreData failed to get caused by error");
        return count;
    }
    
    
    
    //    BOOL newMessageInsertedIntoDatabase;
    for (NSDictionary *newMessage in messages)
    {
        
        BOOL messageAlreadyInCoreData = NO;
        
        NSString *from     = newMessage[SENDER];
        NSString *filepath = newMessage[FILEPATH];
        
        for (Received_message *message in messagesInCoreData)
        {
            if ([from isEqualToString:message.from] && [filepath isEqualToString:message.filepath])
            {
                messageAlreadyInCoreData = YES;
                break;
            }
        }
        
        if (messageAlreadyInCoreData)
            continue;
        
        Received_message *message = [NSEntityDescription insertNewObjectForEntityForName:RECEIVED_MESSAGE_TABLE inManagedObjectContext:context];
        
        message.me          = [AmazonKeyChainWrapper username];
        message.from        = from;
        message.filepath    = filepath;
        
        message.date_sender = newMessage[DATE_SENDER];
        message.date        = newMessage[DATE];
        message.screenshot_safe = [NSNumber numberWithBool:[newMessage[SCREENSHOT_SAFE] isEqualToString:@"y" ]? YES:NO];
        
        if (newMessage[MESSAGE])
        {
            NSString * msg = newMessage[MESSAGE];
            
            if ([msg length] > 0)
                message.message = msg;
        }
        
        message.mediaType     = newMessage[MEDIATYPE];
        
        message.view_status   = @"NO";
        message.delete_marker = @"NO";
        
        count++;
    }
    
    NSLog(@"Received_message ook");
    
    
    //    NSError *error = nil;
    //
    //    if (![context save:&error]) {
    //
    //        NSLog(@"Received_message insertDynamoDBMessages context error");
    //    }
    //    else
    //        NSLog(@"Received_message insertDynamoDBMessages contex");
    
    return count;
}








/* 
 * delete_marker is for knowing if we can delete the message from core data safely knowing that 
 * the message is already deleted from dynamoDB
 */



/*
 *
 *  May want to change this so it returns all new messasges and then we can do an update rows with animation
 *
 */

+(NSUInteger)insertDynamoDBMessages:(NSArray *)messages inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSUInteger count = 0;
    
    NSArray *messagesInCoreData = [Received_message getAllReceivedMessagesThat_Already_Got_From_DynamoDB_ForMediaType:QPSegmentControlTypeNone inManagedContext:context];
    
    
    if (!messagesInCoreData)
    {
        NSLog(@"messagesInCoreData failed to get caused by error");
        return count;
    }
    
    NSLog(@"messagesInCoreData count %lu", (unsigned long)[messagesInCoreData count]);
    
    
//    BOOL newMessageInsertedIntoDatabase;
    for (NSDictionary *newMessage in messages)
    {
        
        BOOL messageAlreadyInCoreData = NO;
        
        NSString *from     = ((DynamoDBAttributeValue *)newMessage[SENDER]).s;
        NSString *filepath = ((DynamoDBAttributeValue *)newMessage[FILEPATH]).s;

        NSLog(@"messagesInCoreData from %@", from);
        NSLog(@"messagesInCoreData filepath %@",filepath );

        for (Received_message *message in messagesInCoreData)
        {
            if ([from isEqualToString:message.from] && [filepath isEqualToString:message.filepath])
            {
                messageAlreadyInCoreData = YES;
                break;
            }
        }
        if (messageAlreadyInCoreData)
            continue; // continue on with next message
    
        Received_message *message = [NSEntityDescription insertNewObjectForEntityForName:RECEIVED_MESSAGE_TABLE inManagedObjectContext:context];
        
        message.me          = [AmazonKeyChainWrapper username];
        message.from        = from;
        message.filepath    = filepath;
        
        message.date_sender = ((DynamoDBAttributeValue *)newMessage[DATE_SENDER]).s;
        message.date        = ((DynamoDBAttributeValue *)newMessage[DATE]).s;
   
        NSString *safe = ((DynamoDBAttributeValue *)newMessage[SCREENSHOT_SAFE]).s;
     
        message.screenshot_safe = [NSNumber numberWithBool:[safe isEqualToString:@"y" ]? YES:NO];
        
        if (newMessage[MESSAGE])
        {
            NSString * msg = ((DynamoDBAttributeValue *)newMessage[MESSAGE]).s;
          
            if ([msg length] > 0)
                message.message = msg;
        }
           
        message.mediaType     = ((DynamoDBAttributeValue *)newMessage[MEDIATYPE]).s;

        message.view_status   = @"NO";
        message.delete_marker = @"NO";
        
        count++;
    }
    
    NSLog(@"Received_message ook");

    
//    NSError *error = nil;
//    
//    if (![context save:&error]) {
//        
//        NSLog(@"Received_message insertDynamoDBMessages context error");
//    }
//    else
//        NSLog(@"Received_message insertDynamoDBMessages contex");
    
    return count;
}


 





/*
 * Returns an array of all the messages for the given media type (image, photo audio)
 * We call this to return the list and then removeAllMessagesFromCoreDataForMediaType() will be called later
 * 
 * Used in QPMailboxCDTVM clearmessages()
 *
 * delete_marker is equal to YES only if its been viewed,
 * so if a user presses clear button, we only need to delete 
 * from dynamodb and s3 where the markers that are equal to NO
 */

+(NSArray *)getAllReceivedMessagesToDeleteforMediaType:(NSUInteger)MediaTypeToUpload inManagedContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:RECEIVED_MESSAGE_TABLE];
    request.sortDescriptors = nil;
    
    if (MediaTypeToUpload == QPSegmentControlTypePhoto)
        request.predicate = [NSPredicate predicateWithFormat:@"me = %@ AND mediaType = %@ AND delete_marker = %@",
                             [AmazonKeyChainWrapper username], IMAGE, @"NO"];
    else if (MediaTypeToUpload == QPSegmentControlTypeVideo)
        request.predicate = [NSPredicate predicateWithFormat:@"me = %@ AND mediaType = %@ AND delete_marker = %@",
                             [AmazonKeyChainWrapper username], VIDEO, @"NO"];
    else if (MediaTypeToUpload == QPSegmentControlTypeAudio)
        request.predicate = [NSPredicate predicateWithFormat:@"me = %@ AND mediaType = %@ AND delete_marker = %@",
                             [AmazonKeyChainWrapper username], AUDIO, @"NO"];
    else
        request.predicate = [NSPredicate predicateWithFormat:@"me = %@ AND delete_marker = %@",
                                                    [AmazonKeyChainWrapper username], @"NO"];

    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (error)
    {
        NSLog(@"getAllReceivedMessagesToDeleteforMediaType error");
        return [NSArray array];
    
    }
    if (matches && [matches count])
    {
        [Received_message markMessageForDeletion:matches inManagedObjectContext:context];
        return matches;
    }
    else
        return matches;
}




+(NSArray *)getAllReceivedMessagesThat_Already_Got_From_DynamoDB_ForMediaType:(NSUInteger)MediaTypeToUpload inManagedContext:(NSManagedObjectContext *)context
{
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:RECEIVED_MESSAGE_TABLE];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:DATE
                                      ascending:NO
                                       selector:@selector(localizedCaseInsensitiveCompare:)]];
    
    if (MediaTypeToUpload == QPSegmentControlTypePhoto)
        request.predicate = [NSPredicate predicateWithFormat:@"me = %@ AND mediaType = %@",
                             [AmazonKeyChainWrapper username], IMAGE];
    else if (MediaTypeToUpload == QPSegmentControlTypeVideo)
        request.predicate = [NSPredicate predicateWithFormat:@"me = %@ AND mediaType = %@",
                             [AmazonKeyChainWrapper username],  VIDEO];
    else if (MediaTypeToUpload == QPSegmentControlTypeAudio)
        request.predicate = [NSPredicate predicateWithFormat:@"me = %@ AND mediaType = %@",
                             [AmazonKeyChainWrapper username], AUDIO];
    else
        request.predicate = [NSPredicate predicateWithFormat:@"me = %@ AND ((mediaType = %@) OR (mediaType = %@) OR (mediaType = %@) OR (mediaType = %@))",
                             [AmazonKeyChainWrapper username], IMAGE, VIDEO, AUDIO, TEXT];

    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (error)
        return nil;
    
    if (matches && [matches count])
        return matches;
    else
        return [NSArray array];
}




@end
