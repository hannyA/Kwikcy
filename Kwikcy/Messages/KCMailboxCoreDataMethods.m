//
//  KCMailboxCoreDataMethods.m
//  Kwikcy
//
//  Created by Hanny Aly on 8/27/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCMailboxCoreDataMethods.h"

#import "Constants.h"
#import "AmazonKeyChainWrapper.h"
#import "Screenshot+methods.h"
#import "QPCoreDataManager.h"


#define NOT_DELETED  @"NO"


@implementation KCMailboxCoreDataMethods


#pragma mark MailBox Core Data Functions



+(void)addScreenShotInfoToCoreData:(NSDictionary *)dic
{
    NSManagedObjectContext *context =  [QPCoreDataManager sharedInstance].managedObjectContext;
    
    [context performBlock:^{
        [Screenshot insertFailedDelivery:dic inManagedObjectContext:context];
    }];
}






#pragma mark MailBox Core Data Functions


+(NSArray *)getMessagesForSelectedSegment:(NSUInteger)selectedSegmentIndex withManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self requestWithSelectedSegment:selectedSegmentIndex];
    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (error)
    {
        NSLog(@"Error: getMessagesForSelectedSegment  failed to get");
    }
    
    NSLog(@" getMessagesForSelectedSegment count %lu", (unsigned long)[matches count]);
    if (!error && matches && [matches count])
    {
        return matches;
    }
    return nil;
}



+(NSFetchRequest *)requestWithSelectedSegment:(NSUInteger)selectedSegmentIndex
{
    if (selectedSegmentIndex == KCSegmentControlInbox)
        return [self inboxRequest];
    else
        return [self outBoxrequest];
}


+(NSFetchRequest *)inboxRequest
{
    NSFetchRequest *inboxRequest = [NSFetchRequest fetchRequestWithEntityName:RECEIVED_MESSAGE_TABLE];
    
    inboxRequest.predicate = [NSPredicate predicateWithFormat:@"me = %@ AND delete_marker = %@",
                              [AmazonKeyChainWrapper username],  NOT_DELETED];
    inboxRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:DATE
                                                                   ascending:NO
                                                                    selector:@selector(localizedCaseInsensitiveCompare:)]];
    return inboxRequest;
}


+(NSFetchRequest *)outBoxrequest
{
    NSFetchRequest *outBoxrequest = [NSFetchRequest fetchRequestWithEntityName:SENT_MESSAGE_TABLE];
    outBoxrequest.predicate = [NSPredicate predicateWithFormat:@"sender = %@ AND ( (mediaType = %@) OR (mediaType = %@) OR (mediaType = %@) OR (mediaType = %@) )",
                               [AmazonKeyChainWrapper username], IMAGE, VIDEO, AUDIO, TEXT];
    outBoxrequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:DATE
                                                                    ascending:NO
                                                                     selector:@selector(localizedCaseInsensitiveCompare:)]];
    return outBoxrequest;
}



@end
