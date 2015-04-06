//
//  QPSentMessageCDTVM.m
//  Quickpeck
//
//  Created by Hanny Aly on 7/9/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import <AWSDynamoDB/AWSDynamoDB.h>

#import "AmazonClientManager.h"
#import "AmazonKeyChainWrapper.h"

#import "QPSentMessageCDTVM.h"
#import "Sent_message+methods.h"

#import "Constants.h"
#import "QPCoreDataManager.h"

#import "QPNetworkActivity.h"

#import "MBProgressHUD.h"

@interface QPSentMessageCDTVM ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *mediaSegmentedControl;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation QPSentMessageCDTVM


//-(void)viewDidLoad
//{
//    [super viewDidLoad];
//    
//
//    [self.refreshControl addTarget:self
//                            action:@selector(refresh)
//                  forControlEvents:UIControlEventValueChanged];
//    self.managedObjectContext = [QPCoreDataManager sharedInstance].managedObjectContext;
//
//    if(self.managedObjectContext)
//    {
////        [Sent_message appCleanUpInManagedObjectContext:self.managedObjectContext];
//        [self.managedObjectContext performBlockAndWait:^{
//            [Sent_message addEmptyStringForMedia:0 inManagedObjectContext:self.managedObjectContext];
//        }];
//
//    }
//    
//    [self refresh];
//    [self findSentMessagesFromDifferentMedia:self.mediaSegmentedControl];
//}



//-(void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:YES];
//    // If we have empty cell lets check if we sent a messages recently
//    if (self.noMessages)
//    {
//        [self findSentMessagesFromDifferentMedia:self.mediaSegmentedControl];
//    }
//}

//-(NSManagedObjectContext *)managedObjectContext
//{
//    if(!_managedObjectContext)
//        _managedObjectContext = [QPCoreDataManager sharedInstance].managedObjectContext;
//    return _managedObjectContext;
//}



//-(void)startProgressHUDWithText:(NSString *)label
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.hud = [MBProgressHUD getAndShowUniversalHUD:self.view withText:label animated:YES];
//    });
//}


//#pragma mark - Data Source for Sent table
//
//- (IBAction)findSentMessagesFromDifferentMedia:(UISegmentedControl *)sender
//{
//    if (self.managedObjectContext) {
//        NSLog(@"Change media");
//
//        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SENT_MESSAGE_TABLE];
//        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:DATE ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)]];
//    
//        if (sender.selectedSegmentIndex == QPSegmentControlTypePhoto)
//        {
//            request.predicate = [NSPredicate  predicateWithFormat:@"mediaType = %@", IMAGE];
//        }
//        else if (sender.selectedSegmentIndex == QPSegmentControlTypeVideo)
//        {
//            request.predicate = [NSPredicate predicateWithFormat:@"mediaType = %@", VIDEO];
//        }
//        else
//        {
//            request.predicate = [NSPredicate predicateWithFormat:@"mediaType = %@", AUDIO];
//        }
//    
//        
//        
//        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
//    
//        
//        NSArray * allMessages = self.fetchedResultsController.fetchedObjects;
//        
//        
//        NSLog(@"refreshMessageBoxForPhotos Messages count = %d", [allMessages count]);
//        
//        // If we have no messages
//        if (![allMessages count]){
//            
//            self.noMessages = YES;
//            NSLog(@" [allMessages count] = 0, so get empty string");
//            
//            
//            NSFetchRequest * newRequest = [NSFetchRequest fetchRequestWithEntityName:SENT_MESSAGE_TABLE];
//            newRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:DATE ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)]];
//            newRequest.predicate = [NSPredicate predicateWithFormat:@"status = %@", @"empty"];
//            
//            self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:newRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
////            [self.tableView reloadData];            
//        }
//        else
//            self.noMessages = NO;
//    }
//    else {
//        self.fetchedResultsController = nil;
//    }
//}


/*
 * Returns a dynamodb formated dictionary
 */

//-(NSMutableDictionary *)getDynamoDBBatchRequestWithArray:(NSArray *)pendingMessages
//{
//    // Create array to store keys
//    NSMutableArray *arrayOfKeys = [[NSMutableArray alloc] init];
//    
//    // Loop to insert all keys 
//    for (Sent_message *message in pendingMessages) {
//        
//        NSString *sender = message.sender;
//        NSString *filepath = message.filepath;
//        
//        NSDictionary *primaryKeysAndRanges  = [NSDictionary dictionaryWithObjectsAndKeys:
//                                               [[DynamoDBAttributeValue alloc] initWithS:[NSString stringWithFormat:@"%@", sender]], SENDING_HASH_KEY_SENDER,
//                                               [[DynamoDBAttributeValue alloc] initWithS:[NSString stringWithFormat:@"%@", filepath]], SENDING_RANGE_KEY_FILEPATH,
//                                               nil];
//        // Add keys to array
//        [arrayOfKeys addObject:primaryKeysAndRanges];
//    }
//    
//    DynamoDBKeysAndAttributes *keysAndAttr = [[DynamoDBKeysAndAttributes alloc] init];
//    
//    // Create array of attributes to get
//    NSMutableArray * arrayOfAttributes = [NSMutableArray arrayWithObjects:STATUS, SENDING_HASH_KEY_SENDER, SENDING_RANGE_KEY_FILEPATH, nil];
//    
//    
//    keysAndAttr.keys = arrayOfKeys;
//    keysAndAttr.attributesToGet = arrayOfAttributes;
//    keysAndAttr.consistentRead = NO;
//    
//    return [NSMutableDictionary dictionaryWithObject:keysAndAttr forKey:SENDING_TABLE];
//}





//- (IBAction)refresh
//{
//    NSLog(@"refresh Pulled");
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//
//        @try {
//            [[QPNetworkActivity sharedInstance] increaseActivity];
//            
//            NSLog(@"Get pending messages");
//            NSArray *pendingMessages = [Sent_message getMessagesWithPendingStatusinManagedObjectContext:self.managedObjectContext];
//            NSLog(@"Got pendingMessages");
//            
//            NSLog(@"[pendingMessages count] = %d", [pendingMessages count]);
//
//
//            if ([pendingMessages count]) {
//                
//                
//                DynamoDBBatchGetItemRequest *batchGetItemRequest = [[DynamoDBBatchGetItemRequest alloc] init];
//                
//                
//                // Send array to getDynamoDBBatchRequestWithArray method to get batch Request
//                batchGetItemRequest.requestItems = [self getDynamoDBBatchRequestWithArray:pendingMessages];
//                
//
////                AmazonCredentials *credentials = [AmazonKeyChainWrapper getCredentialsFromKeyChain];
////                AmazonDynamoDBClient *ddb = [[AmazonDynamoDBClient alloc] initWithCredentials:credentials];
////                ddb.timeout = 15;
//                
//                DynamoDBBatchGetItemResponse *batchGetItemResponse = [[AmazonClientManager ddb] batchGetItem:batchGetItemRequest];
//               
//
//                
//                if(batchGetItemResponse.error) {
//                    NSLog(@"Error: %@", batchGetItemResponse.error);
//                }
//                else {
//                    NSLog(@"Sent refresh 4");
//
//                    if (batchGetItemResponse.responses.count) {
//                        for (NSString *tableKey in [batchGetItemResponse.responses allKeys])
//                        {
//                            NSArray *arrayOfDictionaryResults = [batchGetItemResponse.responses valueForKey:tableKey];
//                            for (NSDictionary *dictionaryResult in arrayOfDictionaryResults)
//                            {
//                                DynamoDBAttributeValue *sender   = [dictionaryResult valueForKey:SENDER];
//                                DynamoDBAttributeValue *filepath = [dictionaryResult valueForKey:FILEPATH];
//                                DynamoDBAttributeValue *status   = [dictionaryResult valueForKey:STATUS];
//                                NSString *c_send = sender.s;
//                                NSString *c_file = filepath.s;
//                                NSString *c_stat = status.s;
//                                if (c_send && c_file && c_stat && ![c_stat isEqualToString:PENDING]){
//                                    NSDictionary * messageResults = [NSDictionary dictionaryWithObjectsAndKeys:c_send,SENDER, c_file, FILEPATH, c_stat, STATUS, nil];
//                                    NSLog(@"Sent refresh 5");
//
//                                    [self.managedObjectContext performBlock:^{
//                                        NSLog(@"Sent refresh 6");
//
//                                        [Sent_message updateMessageWithStatus:messageResults inManagedObjectContext:self.managedObjectContext];
//                                    }];
//                                    NSLog(@"Sent refresh 7");
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        @catch (AmazonServiceException *exception){
//            NSLog(@"%@", exception);
//        }
//        @catch (NSException *anyException) {
//            NSLog(@"Error: %@", anyException);
//        }
//        @finally {
//            NSLog(@"decrease activity");
//            [[QPNetworkActivity sharedInstance] decreaseActivity];
//
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.refreshControl endRefreshing];
//            });
//        }
//    });
//}














#pragma mark - UITableViewDataSource


//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (self.noMessages){
//        NSLog(@"Sent cellForRowAtIndexPath noMessages = YES");
//        
//        NSString *NoMessagesCellIdentifier = @"NoSentMessageCell";
//        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NoMessagesCellIdentifier];
//        if (cell == nil) {
//            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NoMessagesCellIdentifier];
//        }
//        cell.userInteractionEnabled = NO;
//        return cell;
//    }
//    else {        
//        NSLog(@"Sent cellForRowAtIndexPath noMessages = NO");
//        
//        Sent_message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
//        UITableViewCell *cell;
////        if (![message.status isEqualToString:@"Sent"] &&
////            ![message.status isEqualToString:@"Fail"] &&
////            ![message.status isEqualToString:PENDING])
//        if (!message.status)
//        {
//            cell = [tableView dequeueReusableCellWithIdentifier:@"SendProgressCell"];
//            UILabel *receiverLabel    = (UILabel *)[cell viewWithTag:5];
//            UIProgressView *progressView  = (UIProgressView *)[cell viewWithTag:6];
//            UILabel *messageLabel      = (UILabel *)[cell viewWithTag:7];
//            
//            receiverLabel.text = message.receivers;
//            progressView.progress = [message.status floatValue];
//            
//            messageLabel.text = @"";
//            if (message.message.length)
//                messageLabel.text  = message.message;
//            
//        }
//        else {
//            
//            cell = [tableView dequeueReusableCellWithIdentifier:@"SentMessageCell"];
//            UILabel *receiversLabel = (UILabel *)[cell viewWithTag:1];
//            UILabel *statusLabel    = (UILabel *)[cell viewWithTag:2];
//            UILabel *timestampLabel = (UILabel *)[cell viewWithTag:3];
//            
//            UILabel *msgLabel = (UILabel *)[cell viewWithTag:4];
//            
//            receiversLabel.text = message.receivers;
//            statusLabel.text    = message.status;
//            
//            
//            
//            
//            NSDictionary *timeDate = [Constants getDateAndTimeFromSeconds:message.date];
//            
//            NSString *time      = timeDate[QPTIME];
//            NSString *date      = timeDate[QPDATE];
//            
//            NSDictionary *todaysDate = [Constants getDictionaryFromTodaysDate];
//            
//            if ([Constants messageDate:timeDate isEqualToTodaysDate:todaysDate])
//                timestampLabel.text = time;
//            else
//                timestampLabel.text = date;
//            
//            msgLabel.text = @"";
//            if ([message.message length] > 0)
//                msgLabel.text  = message.message;
//        }
//        
//        return cell;
//    }
//}









//// Override to support conditional editing of the table view.
//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (self.noMessages)
//        return NO;
//    else
//        return YES;
//}

//-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return UITableViewCellEditingStyleDelete;
//}






/* 
 * Clear button pressed
 */
//- (IBAction)clearMessages:(UIBarButtonItem *)sender
//{
//    NSArray *objects = [Sent_message getMessagesToDelete:self.mediaSegmentedControl.selectedSegmentIndex withManagedObjectContext:self.managedObjectContext];
//
//    if ([objects count]){
//        NSLog(@"We have objecs to delete from dynamodb");
//        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//
//            @try {
//                [[QPNetworkActivity sharedInstance] increaseActivity];
//                [self startProgressHUDWithText:@"Clearing messages"];
//             
//                [QPSentMessageCDTVM deleteMessages:objects fromDynamoDBForSelectedIndex:10];
//                
//                [self.managedObjectContext performBlock:^{
//                   
//                     BOOL allmessagesCleared = [Sent_message removeMessages:objects forSegmentControl:self.mediaSegmentedControl.selectedSegmentIndex withManagedObjectContext:self.managedObjectContext];
//               
//                    if (allmessagesCleared && !self.noMessages){
//                        
//                        NSLog(@"newMessagesInserted");
//                        [self findSentMessagesFromDifferentMedia:self.mediaSegmentedControl];
//                    }
//                }];
//                
//            }
//            @catch (NSException *exception) {
//                NSLog(@"Sent message exception thrown:%@", exception);
//            }
//            @finally {
//                [[QPNetworkActivity sharedInstance] decreaseActivity];
//                [self.hud hideProgressHUD];
//            }
//        });
//    }
//}

#pragma mark - UITableViewDataSource Editable



//// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    NSLog(@"commitEditingStyle called");
//    
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        
//        // Delete the row from the core data
//        
//        Sent_message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
//        
//        NSArray *objects = @[message];
//        
//        if ([objects count]){
//            
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//                
//                @try {
//                    [[QPNetworkActivity sharedInstance] increaseActivity];
//                    [self startProgressHUDWithText:@"Deleting"];
//                    
//                    [QPSentMessageCDTVM deleteMessages:objects fromDynamoDBForSelectedIndex:10];
//                  
//                    // [fetchedResultsController.fetchedObjects count]
//                    [self.managedObjectContext performBlockAndWait:^{
//                        [Sent_message removeMessages:objects forSegmentControl:self.mediaSegmentedControl.selectedSegmentIndex withManagedObjectContext:self.managedObjectContext];
//
//                    }];
//                    
////                    if([self.fetchedResultsController.fetchedObjects count])
////                    {
////                     self.tableView.
////                    }
//
//                }
//                @catch (NSException *exception) {
//                    NSLog(@"Sent message exception thrown:%@", exception);
//                }
//                @finally {
//                    [[QPNetworkActivity sharedInstance] decreaseActivity];
//                    [self.hud hideProgressHUD];
//                }
//            });
//        }
//    }
//}
//
//
//+(void)deleteDynamoDBMessages:(NSArray *)objects
//{
//    NSError * error = nil;
//    
//    NSLog(@"deleteDynamoDBMessages");
//    
//    @try
//    {
//        DynamoDBBatchWriteItemRequest *batchWriteRequest = [DynamoDBBatchWriteItemRequest new];
//        NSMutableArray *writes = [NSMutableArray arrayWithCapacity:5];
//        
//        [batchWriteRequest setRequestItemsValue:writes forKey:RECEIVING_TABLE];
//        
//        int counter = 1;
//        
//        NSString * hashKey = [AmazonKeyChainWrapper username];
//        
//        for (Sent_message *message in objects)
//        {
//            NSString *filepath = message.filepath;
//            if (!filepath)
//                return;
//            
//            NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
//            
//            [attributeDictionary setObject:[[DynamoDBAttributeValue alloc] initWithS:hashKey] forKey:RECEIVING_HASH_KEY_RECEIVER];
//            [attributeDictionary setObject:[[DynamoDBAttributeValue alloc] initWithS:filepath] forKey:RECEIVING_RANGE_KEY_FILEPATH];
//            
//            DynamoDBDeleteRequest *deleteRequest = [DynamoDBDeleteRequest new];
//            deleteRequest.key = attributeDictionary;
//            
//            DynamoDBWriteRequest *writeRequest = [DynamoDBWriteRequest new];
//            writeRequest.deleteRequest = deleteRequest;
//            
//            
//            [writes addObject:writeRequest];
//            
//            if(counter % 25 == 0 || [objects count] == counter)
//            {
//                DynamoDBBatchWriteItemResponse * batchWriteResponse = nil;
//                
//                NSUInteger retry = 3;
//                for(int i = 0; i < retry + 1; i++)
//                {
//                    batchWriteResponse = [[AmazonClientManager ddb] batchWriteItem:batchWriteRequest];
//                    
//                    if(!batchWriteResponse.error)
//                    {
//                        if(batchWriteResponse.unprocessedItems == nil
//                           || [batchWriteResponse.unprocessedItems count] == 0
//                           || i == retry)
//                        {
//                            break;
//                        }
//                        else
//                        {
//                            [NSThread sleepForTimeInterval:pow(2, i) * 2];
//                            batchWriteRequest = [DynamoDBBatchWriteItemRequest new];
//                            
//                            for(NSString *key in batchWriteResponse.unprocessedItems)
//                            {
//                                [batchWriteRequest setRequestItemsValue:[batchWriteResponse.unprocessedItems objectForKey:key] forKey:key];
//                            }
//                        }
//                    }
//                    else
//                    {
//                        error = batchWriteResponse.error;
//                    }
//                }
//                
//                if(batchWriteResponse.unprocessedItems != nil
//                   && [batchWriteResponse.unprocessedItems count] > 0)
//                {
//                    NSLog(@"BatchWrite failed. Some items were not processed.");
//                }
//                
//                if([objects count] != counter)
//                {
//                    batchWriteRequest = [DynamoDBBatchWriteItemRequest new];
//                }
//            }
//            
//            counter++;
//        }
//    }
//    @catch (NSException *exception)
//    {
//        NSLog(@"Error:%@", exception);
//    }
//}
//
//
//
//
//
///*
// * Delete rows from dynamodb
// * Does this delete messages from the tmp file ? 
// */
//+(void)deleteMessages:(NSArray *)objects fromDynamoDBForSelectedIndex:(NSUInteger)selectedSegmentIndex
//{
//    ///   For every message that we have not viewed delete from s3.
//    
//    if ([objects count]){
//        
//        /* Delete objects from Dynamodb first */
//        
//        [QPSentMessageCDTVM deleteDynamoDBMessages:objects];
//        
//        /* Delete objects from S3 first */
//        S3DeleteObjectsRequest *deleteObjectsRequest = [[S3DeleteObjectsRequest alloc] init];
//        deleteObjectsRequest.bucket = BUCKET_NAME;
//        deleteObjectsRequest.quiet = YES;
//        
//        
//        
//        for (Sent_message *message in objects)
//        {
//            S3KeyVersion * key = [[S3KeyVersion alloc] initWithKey:message.filepath];
//            [deleteObjectsRequest.objects addObject:key];
//        }
//        [S3DeleteObjectsResponse class];
//        S3DeleteObjectsResponse *response = [[AmazonClientManager s3] deleteObjects:deleteObjectsRequest];
//        
//        
//        
//        if (response.error || response.exception)
//        {
//            NSLog(@"Error deleteing objects");
//        }
//        
//        if ([response.deleteErrors count])
//        {
//            for (id obj in response.deleteErrors)
//                NSLog(@"QPMailboxCDTVM response.deleteErrors : /n %@", response.deleteErrors);
//        }
//        
//        
//        // If Quiet is set I won't get this back
//        if ([response.deletedObjects count])
//        {
//            NSLog(@"QPMailboxCDTVM response.deleteErrors :");
//            
//            for (id obj in response.deletedObjects) {
//                NSLog(@"QPMailboxCDTVM response.deleteErrors : /n %@", response.deletedObjects);
//                
//            }
//        }
//    }
//}




@end

