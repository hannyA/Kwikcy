//
//  QPMailboxCDTVM.m
//  Quickpeck
//
//  Created by Hanny Aly on 7/12/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//
 
#import "QPMailboxCDTVM.h"
#import "KCMessageBox.h"
#import "KCdate.h"

#import <AWSDynamoDB/AWSDynamoDB.h>
#import <MediaPlayer/MediaPlayer.h>

#import "AmazonClientManager.h"
#import "AmazonKeyChainWrapper.h"

#import "ReceivedMessageImage.h"
#import "ReceivedMessageVideo.h"

#import "Sent_message+methods.h"
#import "User+methods.h"


#import "Constants.h"
#import "MBProgressHUD.h"
#import "QPNetworkActivity.h"


#import "QPAsyncImageDownloader.h"
#import "QPAsyncVideoDownloader.h"

#import "QPCoreDataManager.h"

#import "KwikcyClientManager.h"

#import "KCServerResponse.h"

#import "QPTabViewController.h"

#import "Screenshot+methods.h"
#import "KwikcyAWSRequest.h"


#import "KCImageVC.h"
#import "KCMailboxCoreDataMethods.h"



#define LOADING @"Loading"
#define FINISHED_LOADING @"Finished loading"

#define NOT_DELETED  @"NO"


@interface QPMailboxCDTVM ()<AsyncImageControllerProtocolDelegate, AsyncVideoControllerProtocolDelegate,AmazonServiceRequestDelegate>
//, QPTableViewProtocolDelegate>

//@property (nonatomic, readonly) AmazonServiceResponse *response;
//@property (nonatomic, readonly) NSError               *error;
//@property (nonatomic, readonly) NSException           *exception;

@property (weak, nonatomic) IBOutlet UISegmentedControl *mailboxSegmentControl;


@property (nonatomic , strong) NSString *path;

@property (nonatomic)                   NSUInteger           typeOfMedia;
@property (nonatomic, strong)           NSOperationQueue    *operationQueue;
@property (nonatomic, strong)           MBProgressHUD       *hud;
@property (nonatomic, strong)           NSTimer             *HUDalarm;

@property (nonatomic, weak) IBOutlet    UIProgressView      *downloaderProgressView;


@property (nonatomic, strong)           KCMessageBox        *myMessageBox;


@property (strong, nonatomic)           MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong)           NSManagedObjectContext  *managedObjectContext;


@property (nonatomic, strong)           UIImageView *imgView;
@property (nonatomic, strong)           UILabel *label;

@property (atomic,  strong)             NSIndexPath         *currentlyselectedTableViewIndexPath;
@property (atomic,  strong)             ReceivedMessage     *currentlyselectedReceivedMessage;

@property (atomic,  strong)             SentMessage         *sentMessageToUnsend;


@property (nonatomic, strong) UIActivityIndicatorView *spinningWheel;


@property (nonatomic, strong) KCImageVC *currentImageVC;


@property (nonatomic, getter = isAddingForTheFirstTime) BOOL addingForTheFirstTime;


@property (nonatomic, getter = isDeletingRows) BOOL deletingRows;
@property (nonatomic, getter = isAddingRows)   BOOL addingRows;


@property (nonatomic, getter = isAddingEmptyRow)     BOOL addingEmptyRow;
@property (nonatomic, getter = isDeletingEmptyRow)   BOOL deletingEmptyRow;

@property (nonatomic, getter = isAddingAllRow)     BOOL addingAllRow;
@property (nonatomic, getter = isDeletingAllRow)   BOOL deletingAllRow;



@property (nonatomic) NSUInteger addingCount;

@property (nonatomic) BOOL firstTimeViewWillAppear;



@end



@implementation QPMailboxCDTVM

#pragma mark Life cycle


-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = 100;
    self.tabBarController.tabBar.hidden = NO;

    
    self.spinningWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.spinningWheel.color = [UIColor redColor];
    self.spinningWheel.hidesWhenStopped = YES;

    self.firstTimeViewWillAppear = YES;
}





-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploadFilepath:)
                                                 name:KwikcyFileUpload
                                               object:nil];
    if(self.firstTimeViewWillAppear)
    {
        self.firstTimeViewWillAppear = NO;

        
        
        self.addingForTheFirstTime = YES;
        self.addingRows = YES;
        
        [self fillUpMailbox:self.mailboxSegmentControl.selectedSegmentIndex
              withAnimation:UITableViewRowAnimationNone];
        
        self.addingRows = NO;
        self.addingForTheFirstTime = NO;
        
        
        if (!self.isMailBoxOutboxShowing)
        {
            NSLog(@"firstTimeViewWillAppear: !self.isMailBoxOutboxShowing");

            [self pulldownRefresh:nil];
        }
    }
    
    
    if (self.isMailBoxOutboxShowing)
    {
        NSLog(@"isMailBoxOutboxShowing");

        if (self.mailboxSegmentControl.selectedSegmentIndex == KCSegmentControlOutbox)
        {

            if ([self.myMessageBox hasMessages])
            {
                NSLog(@"isMailBoxOutboxShowing: KCSegmentControlOutbox: hasMessages");

                
                NSArray *resultsFromCoreDataTable = [KCMailboxCoreDataMethods getMessagesForSelectedSegment:KCSegmentControlOutbox
                                                                                   withManagedObjectContext:self.managedObjectContext];
                
                // This fills up myMessageBox with messages
                [self.myMessageBox insertAllMessagesFromFetchedController:resultsFromCoreDataTable];
                
            
                [self insertIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ]
                      withRowAnimation:UITableViewRowAnimationTop];
            }
            else
            {
                NSLog(@"isMailBoxOutboxShowing: KCSegmentControlOutbox: has no Messages");

                [self clearAllIndexPathsWithAnimation:UITableViewRowAnimationNone];
                
                [self fillUpMailbox:KCSegmentControlOutbox
                      withAnimation:UITableViewRowAnimationNone];
            }
        }
        else
        {
            NSLog(@"isMailBoxOutboxShowing: KCSegmentControlinbox");
            self.mailboxSegmentControl.selectedSegmentIndex = KCSegmentControlOutbox;

            [self clearAllIndexPathsWithAnimation:UITableViewRowAnimationTop];
            
            [self fillUpMailbox:KCSegmentControlOutbox
                  withAnimation:UITableViewRowAnimationTop];
        }
        
        
        self.mailBoxOutBoxShowing = NO;
    
    }
}



-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:KwikcyFileUpload
                                                  object:nil];
    [super viewWillDisappear:animated];
}



#pragma mark HUDProgress Methods

-(void)startProgressHUDWithText:(NSString *)label
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hud = [MBProgressHUD getAndShowUniversalHUD:self.view withText:label animated:YES];
    });
}

-(void)hideProgressHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.hud hideProgressHUD];
    });
}

-(void)startProgressHUDWithTextSynchronously:(NSString *)label
{
    self.hud = [MBProgressHUD getAndShowUniversalHUD:self.view withText:label animated:YES];
}

-(void)hideProgressHUDSynchronously
{
    [self.hud hideProgressHUD];
}






#pragma mark Init objects



-(NSManagedObjectContext *)managedObjectContext
{
    if(!_managedObjectContext)
        _managedObjectContext = [QPCoreDataManager sharedInstance].managedObjectContext;
    return _managedObjectContext;
}



-(NSOperationQueue *)operationQueue
{
    if (!_operationQueue){
        _operationQueue = [NSOperationQueue new];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    return _operationQueue;
}

-(KCMessageBox *)myMessageBox
{
    if (!_myMessageBox)
        _myMessageBox = [[KCMessageBox alloc] init];
    return _myMessageBox;
}




#pragma mark Refresh message box










/*
 * Sets typeOfMedia and request.predicate
 * And refreshes the messagebox
 */
- (IBAction)userDidChangeMailbox:(UISegmentedControl *)sender
{
    NSLog(@"userDidChangeMailbox: called");
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.spinningWheel];
    [self.spinningWheel startAnimating];

    
    [self clearAllIndexPathsWithAnimation:UITableViewRowAnimationTop];

    [self fillUpMailbox:sender.selectedSegmentIndex
          withAnimation:UITableViewRowAnimationTop];
 
    [self pulldownRefresh:nil]; // returns right away
}





/*
        Create @Property NSUInteger leftOverCount
 */
-(void)clearAllIndexPathsWithAnimation:(NSInteger)animation
{
    NSLog(@"clearAllIndexPaths: called");
    
    if ([self.myMessageBox hasMessages])
    {
        NSUInteger numberOfItemsInMessageBox = [self.myMessageBox numberOfMessages];
        
        NSMutableArray * indexPaths = [NSMutableArray new];

        for (int i = 0; i < numberOfItemsInMessageBox; i++)
        {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        [self.myMessageBox removeAllMessagesFromBox];
 
        [self deleteAllIndexPaths:indexPaths
                 withRowAnimation:animation];
    }
    else
    {
        [self deleteEmptyRowWithRowAnimation:animation];
    }
}







-(void)fillUpMailbox:(NSUInteger)selectedSegmentIndex withAnimation:(NSInteger)animation
{
    NSLog(@"fillUpMailbox: called");

    NSMutableArray * indexPaths = [NSMutableArray new];

    
    NSArray *resultsFromCoreDataTable = [KCMailboxCoreDataMethods getMessagesForSelectedSegment:selectedSegmentIndex
                                                                withManagedObjectContext:self.managedObjectContext];

    // This fills up myMessageBox with messages
    [self.myMessageBox insertAllMessagesFromFetchedController:resultsFromCoreDataTable];
    

    
    if ([self.myMessageBox hasMessages])
    {
        
        NSLog(@"fillUpMailbox: hasMessages");

        NSUInteger numberOfItemsInMessageBox = [self.myMessageBox numberOfMessages];

        for (int i = 0; i < numberOfItemsInMessageBox; i++)
        {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        
        [self addAllIndexPaths:indexPaths
              withRowAnimation:animation];

        
        NSLog(@"fillUpMailbox: inserting rows done");

    }
    else
    {
        NSLog(@"fillUpMailbox: insertEmptyRowForEmptyMessageBoxWithRowAnimation");

        [self addEmptyRowWithRowAnimation:animation];
       
        NSLog(@"fillUpMailbox: insertEmptyRowForEmptyMessageBoxWithRowAnimation done");

    }
    NSLog(@"fillUpMailbox: called done");
}











//Insert new items only
-(void)refreshMailbox:(NSUInteger)selectedSegmentIndex
{
    NSLog(@"refreshMailbox called");
    
    NSArray *resultsFromCoreDataTable = [KCMailboxCoreDataMethods getMessagesForSelectedSegment:selectedSegmentIndex
                                                                withManagedObjectContext:self.managedObjectContext];
    
    NSLog(@"refreshMailbox: resultsFromCoreDataTable = %d", [resultsFromCoreDataTable count]);

    NSUInteger numberOfItemsBeforeInsertion = [self.myMessageBox numberOfMessages];

    NSLog(@"refreshMailbox: numberOfItemsBeforeInsertion = %d", numberOfItemsBeforeInsertion);

    //IF empty row exists
    if (![self.myMessageBox hasMessages])
    {
        NSLog(@"refreshMailbox: no hasMessages");

        [self.myMessageBox insertAllMessagesFromFetchedController:resultsFromCoreDataTable];
        
        NSUInteger numberOfItemsInMessageBox = [self.myMessageBox numberOfMessages];
        
        NSLog(@"refreshMailbox: numberOfItemsInMessageBox = %d", numberOfItemsInMessageBox);

        if (numberOfItemsInMessageBox)
        {
            [self deleteEmptyRowWithRowAnimation:UITableViewRowAnimationMiddle];
            
            NSMutableArray * indexPaths = [NSMutableArray new];
            
            NSUInteger newCount  = numberOfItemsInMessageBox - numberOfItemsBeforeInsertion;
            
            if (newCount)
            {
                for (int i = 0; i < newCount; i++)
                {
                    [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                }
                
                [self addAllIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                
            }
        }
    }
    // There are items in myMessagesBox
    else
    {
        // This fills up myMessageBox with messages
        [self.myMessageBox insertAllMessagesFromFetchedController:resultsFromCoreDataTable];
        
        NSUInteger numberOfItemsInMessageBox = [self.myMessageBox numberOfMessages];
        
        
        NSMutableArray * indexPaths = [NSMutableArray new];
        
        
        NSUInteger newCount  = numberOfItemsInMessageBox - numberOfItemsBeforeInsertion;
        
        NSLog(@"    newCount = %d", newCount);
        
        if (newCount)
        {
            for (int i = 0; i < newCount; i++)
            {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            
            NSLog(@"    new indexPaths = %d", [indexPaths count]);
            
            //        [self insertIndexPaths:indexPaths withOriginalCount:numberOfItemsBeforeInsertion];
           
            [self insertIndexPaths:indexPaths
                  withRowAnimation:UITableViewRowAnimationMiddle];
//            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationMiddle];
            
        }
    }
}





         
         
#pragma mark Adding and Deleting rows
         
         
-(void)insertIndexPaths:(NSArray *)indexpaths withOriginalCount:(NSUInteger)countBeforeInsertingIntoMyMessageBox
{
    if (!countBeforeInsertingIntoMyMessageBox)
    {

        NSLog(@"insertIndexPaths: myMessageBox has no Messages");
 
        [self deleteIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ]
              withRowAnimation:UITableViewRowAnimationMiddle];
        
    }
    NSLog(@"insertIndexPaths: inserting %d rows", [indexpaths count]);

    [self.tableView insertRowsAtIndexPaths:indexpaths
                          withRowAnimation:UITableViewRowAnimationMiddle];
    
}




-(void)deleteIndexPaths:(NSArray *)indexPaths withRowAnimation:(NSInteger)animation
{
    self.deletingRows = YES;
    
    [self.tableView deleteRowsAtIndexPaths:indexPaths
                          withRowAnimation:animation ];
    
    self.deletingRows = NO;
}

 
         
 -(void)insertIndexPaths:(NSArray *)indexpaths withRowAnimation:(NSInteger)animation
{
    self.addingRows = YES;
    [self.tableView insertRowsAtIndexPaths:indexpaths
                          withRowAnimation:animation];
    self.addingRows = NO;
}
         

         

-(void)deleteEmptyRowWithRowAnimation:(NSInteger)animation
{
    self.deletingEmptyRow = YES;
    [self.tableView deleteRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ]
                          withRowAnimation:animation ];
    self.deletingEmptyRow = NO;
}


-(void)addEmptyRowWithRowAnimation:(NSInteger)animation
{
    self.addingEmptyRow = YES;
    [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ]
                          withRowAnimation:animation];
    self.addingEmptyRow = NO;
}




-(void)addAllIndexPaths:(NSArray *)indexPaths withRowAnimation:(NSInteger)animation
{
    self.addingAllRow = YES;
    [self.tableView insertRowsAtIndexPaths:indexPaths
                          withRowAnimation:animation];
    self.addingAllRow = NO;
}

-(void)deleteAllIndexPaths:(NSArray *)indexPaths withRowAnimation:(NSInteger)animation
{
    self.deletingAllRow = YES;
    [self.tableView deleteRowsAtIndexPaths:indexPaths
                          withRowAnimation:animation ];
    self.deletingAllRow = NO;
}









- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"numberOfRowsInSection count = %lu", (unsigned long)[self.myMessageBox numberOfMessages]);
    
    self.addingCount++;
    
    if (self.isAddingForTheFirstTime)
    {
        if (self.addingCount == 1)
        {
            return 0;
        }
        else
        {
            self.addingCount = 0;

            if (self.isAddingEmptyRow)
            {
                return 1;

            }
            else
            {
                return [self.myMessageBox numberOfMessages];
            }
        }
    }
    
    
    

    if (self.isDeletingAllRow || self.isDeletingEmptyRow)
    {
        NSLog(@"self.isDeletingAllRow");

        return 0;
    }
    if (self.isDeletingRows)
    {
        NSLog(@"self.isDeletingRows");
        
        return [self.myMessageBox hasMessages] ? [self.myMessageBox numberOfMessages] : 0;
    }
    
    else if (self.isAddingEmptyRow)
    {
        NSLog(@"self.isAddingEmptyRow");

        return 1;
    }
    else if (self.isAddingAllRow)
    {
        NSLog(@"self.isAddingAllRow");

        return [self.myMessageBox numberOfMessages];
    }

    else if (self.isAddingRows)
    {
        NSLog(@"numberOfRowsInSection is adding row");
        NSLog(@"numberOfRowsInSection is adding row %d", [self.myMessageBox numberOfMessages]);

        return [self.myMessageBox numberOfMessages];
    }
    
    NSLog(@"numberOfRowsInSection normal");

    return [self.myMessageBox hasMessages] ? [self.myMessageBox numberOfMessages]: 1;
}












//-(void)refreshMessageBoxForVideos
//{
//    [self.messageBox.messages removeAllObjects];
//    
//    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
//    
//    
//    NSLog(@"refreshMessageBoxForVideos self.request.predicate predicateFormat]: %@", [self.request.predicate predicateFormat]);
//    
//    NSArray * allMessages = self.fetchedResultsController.fetchedObjects;
//
//    
//    NSLog(@"refreshMessageBoxForVideos MEssages count = %lu", (unsigned long)[allMessages count]);
//
//    
//    for (Received_message *message in allMessages) {
//        ReceivedMessageVideo *messageWithTimer = [[ReceivedMessageVideo alloc] initWithReceived_message:message];
//        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:message];
//        messageWithTimer.row = [NSNumber numberWithInteger:indexPath.row];
//        messageWithTimer.indexPath = indexPath;
//        [self.messageBox.messages addObject:messageWithTimer];
//    }    
//}












#pragma mark - UITableViewDataSource






//TODO:get the date of the last message received, then query filepath range key for greated than current filepath, which will be sorted by date


- (IBAction)pulldownRefresh:(UIRefreshControl *)sender
{
    NSLog(@"pulldownRefresh called");
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.spinningWheel];
    
    [self.spinningWheel startAnimating];
    
    
    NSUInteger selectedSegmentIndex = self.mailboxSegmentControl.selectedSegmentIndex;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        if (selectedSegmentIndex == KCSegmentControlInbox)
        {
            NSLog(@"Pulldown KCSegmentControlInbox");

            NSArray *messages = [KCMessageBox getNewInboxMessagesFromServer];

            NSLog(@"Pulldown KCSegmentControlInbox count %lu", (unsigned long)[messages count]);

            dispatch_async(dispatch_get_main_queue(), ^{

                if ([messages count])
                {
                    [self.managedObjectContext performBlockAndWait:^{

                        NSUInteger newMessagesInserted = [Received_message insertDynamoDBMessages:messages
                                                                inManagedObjectContext:self.managedObjectContext];
                        
                        NSLog(@"Pulldown KCSegmentControlInbox newMessagesInserted %lu", (unsigned long)newMessagesInserted);

                        //If there were no mesages and we just added one, update the table
                        
                        [self refreshMailbox:selectedSegmentIndex];

                    }];
                }
                [self stopRefreshControl];

            });
        }
        
        else //KCSegmentControlOutbox
        {
            NSLog(@"Pulldown KCSegmentControlOutbox");
           
            NSDictionary *info = [self.myMessageBox getPendingMessagesinManagedObjectContext:self.managedObjectContext];
            
            if(info)
            {
                NSArray *pendingMessages = info[MESSAGE];
                NSArray *indexpaths = info[@"indexpaths"];
            
                NSArray *results = [KCMessageBox getOutboxMessagesForPendingMessages:pendingMessages];
                
                NSLog(@"Pulldown KCSegmentControlOutbox pendingMessages new results count %d", [results count]);
                
                dispatch_sync(dispatch_get_main_queue(), ^{

                    if ([results count])
                    {
                        [self.managedObjectContext performBlock:^{
                            
                            for (NSDictionary *messageResults in results)
                            {
                                [Sent_message updateMessageWithStatus:messageResults
                                               inManagedObjectContext:self.managedObjectContext];
                            }

                            [self updateRows:indexpaths withAnimation:UITableViewRowAnimationFade];
                        }];
                    }
                    [self stopRefreshControl];

                });
                
            }
            else
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self stopRefreshControl];
                });
            
            
            
            
//                                  
//            __block NSArray *pendingMessages;
//            
//            dispatch_sync(dispatch_get_main_queue(), ^{
//                [self.managedObjectContext performBlockAndWait:^{
//                    
//                    pendingMessages = [Sent_message getMessagesWithPendingStatusinManagedObjectContext:self.managedObjectContext];
//                }];
//            });
//            
//            NSLog(@"Pulldown KCSegmentControlOutbox pendingMessages count %d", [pendingMessages count]);
//
//            
//            NSArray *results = [KCMessageBox getOutboxMessagesForPendingMessages:pendingMessages];
//            
//            NSLog(@"Pulldown KCSegmentControlOutbox pendingMessages new results count %d", [results count]);
//
//            if ([results count])
//            {
//                dispatch_sync(dispatch_get_main_queue(), ^{
//                    [self.managedObjectContext performBlock:^{
//                       
//                        NSMutableArray *indexPaths = [NSMutableArray new];
//                        
//                        for (NSDictionary *messageResults in results)
//                        {
//                            [Sent_message updateMessageWithStatus:messageResults
//                                           inManagedObjectContext:self.managedObjectContext];
//                            
//                            
//                            
//                            NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
//                            
//                            [indexPaths addObject:path];
//                            
//                        }
//                        
//                        [self updateRows:indexPaths];
//                        
//                    }];
//                    
//                    
//                    
//                              
//                    [self refreshMailbox:selectedSegmentIndex];
//                });
//            }
        }
        
//        [self stopRefreshControl];
    });
}



-(void)updateRows:(NSArray *)indexPaths withAnimation:(NSInteger)animation
{
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}



-(void)stopRefreshControl
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
        [self.spinningWheel stopAnimating];
    });
    [self hideProgressHUD];
}











#define MAX_GROUP 3

/*
 * get persons profile image from our contacts list, if we don't have it, async get profile image from dynamodb, and reload it
 *
 */

/* Load cell data and decide if cell is selectable */

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSUInteger selectedSegmentIndex = self.mailboxSegmentControl.selectedSegmentIndex;
        
    static NSString *NoMessagesCellIdentifier      = @"No New Messages";
    static NSString *NoSentMessageCellIdentifier   = @"No Sent Message Cell";

    //If no messages and have "empty cell" in array, return it
    if (![self.myMessageBox hasMessages])
    {
        UITableViewCell *cell;
        if ( selectedSegmentIndex == KCSegmentControlInbox)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:NoMessagesCellIdentifier];
            if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NoMessagesCellIdentifier];
        }
        else
        {
            cell = [tableView dequeueReusableCellWithIdentifier:NoSentMessageCellIdentifier];
            if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NoSentMessageCellIdentifier];
        }
        cell.userInteractionEnabled = NO;
        return cell;
    }
    
    
    
    
    //we have messages in array
    
    
    
    static NSString *ReceivedMessageCellIdentifier = @"Received Message Cell";
    
    NSString *username;
    NSString *mediaType;
    UITableViewCell *cell;
    
    if (selectedSegmentIndex == KCSegmentControlInbox)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:ReceivedMessageCellIdentifier];
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReceivedMessageCellIdentifier];

        
        ReceivedMessage *receivedMessage = [self.myMessageBox getMessageAtIndex:indexPath.row];
        
        username  = [receivedMessage getPersonFrom];
        mediaType = [receivedMessage getMediaType];
        
        
        if ([mediaType isEqualToString:IMAGE])
        {
            
            ReceivedMessageImage *timerMessage = (ReceivedMessageImage *)receivedMessage;
            
            UILabel *timeLeftLabel  = (UILabel *)[cell viewWithTag:5];

            
            UIImageView *mediaTypeImage  = (UIImageView *)[cell viewWithTag:1];
            mediaTypeImage.contentMode = UIViewContentModeScaleAspectFit;
            
            UIImage *mediaImage;
            
            if ([timerMessage hasBeenViewed] && [timerMessage.timeLeft integerValue] )
            {
                timeLeftLabel.hidden = NO;
                timeLeftLabel.text = [timerMessage.timeLeft stringValue];
                
                mediaImage = [UIImage imageNamed:@"camera-buttonA"];
            }
            else if ( [timerMessage hasBeenViewed] )  // and no timeleft
            {
                timeLeftLabel.hidden = YES;
                mediaImage = [UIImage imageNamed:@"Check-mark-hollow-pink"];
            }
            else // timerMessage has not BeenViewed
            {
                timeLeftLabel.hidden = YES;
                mediaImage = [UIImage imageNamed:@"camera-buttonA"];

            }
            mediaTypeImage.image = mediaImage;

        }
        
        //Set up cell if it's for a video
        else if ([mediaType isEqualToString:VIDEO])
        {
            NSLog(@"mediaType is %@, ", VIDEO);
            //ReceivedMessageVideo *videoMessage = [[ReceivedMessageVideo alloc] initWithReceived_message:receivedMessage.message];
            
            //if ([receivedMessage.view_status isEqualToString:@"YES"])
            //{
            //    cell.selectionStyle = UITableViewCellSelectionStyleNone;
            //    cell.accessoryType = UITableViewCellAccessoryNone;
            //}
        }
        
        
        
        UILabel *senderLabel = (UILabel *)[cell viewWithTag:3];
        senderLabel.text = username;
    

        // Set timeStampLabel
        UILabel *timeStampLabel  = (UILabel *)[cell viewWithTag:4];

        //message.date is in seconds so convert
        NSDictionary *timeDate   = [KCDate getDateAndTime:[receivedMessage getDate]];
        
        NSDictionary *todaysDate = [KCDate getDictionaryFromTodaysDate];
        timeStampLabel.text      = [KCDate howLongAgoWasMessageDate:timeDate sentFrom:todaysDate];
        
        
        
        // messageLabel.text = @"";
        // if ([message.message length] > 0){
        // messageLabel.text = message.message;
    
        // if ([message.message isEqualToString:SCREENSHOT_NOTIFICATION])
        // messageLabel.text = @"Screenshot taken! You get a vengence point. Enjoy";
        // }
    }
    
    
    
    /*************    KCSegmentControlOutbox   ********************/
    
    else
    {
        static NSString *SendProgressCellCellIdentifier = @"Sending Progress Cell";
        static NSString *GroupSendingCellIdentifier     = @"Group Sending Cell";

        
        
        SentMessage *message = [self.myMessageBox getMessageAtIndex:indexPath.row];
                
        username  = [message getReceivers];
        mediaType = [message getMediaType];
     
        
        // Single
        if ([[username componentsSeparatedByString:@" " ] count] == 1)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:SendProgressCellCellIdentifier];
            if (cell == nil)
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SendProgressCellCellIdentifier];
            
            // Still uploading using Progress Bar,  so value is a number
            if (![self hasStringValueStatus:[message getStatus]])
            {
                UIProgressView *progressView  = (UIProgressView *)[cell viewWithTag:4];
                progressView.hidden = NO;
           
                [progressView setProgress:[[message getStatus] floatValue] animated:YES];
                
                
                UILabel *timeStampLabel = (UILabel *)[cell viewWithTag:5];
                UILabel *statusLabel    = (UILabel *)[cell viewWithTag:6];
                timeStampLabel.hidden   = YES;
                statusLabel.hidden      = YES;
            }
            else
            {
                // Set timeStampLabel
                UILabel *timeStampLabel  = (UILabel *)[cell viewWithTag:5];
                timeStampLabel.hidden   = NO;

                NSDictionary *timeDate   = [KCDate getDateAndTimeFromSeconds:[message getDate]];
                NSDictionary *todaysDate = [KCDate getDictionaryFromTodaysDate];
                timeStampLabel.text      = [KCDate howLongAgoWasMessageDate:timeDate sentFrom:todaysDate];
                
                UILabel *statusLabel = (UILabel *)[cell viewWithTag:6];
                statusLabel.text     = [[message getStatus] capitalizedString];
                statusLabel.hidden      = NO;

                UIProgressView *progressView  = (UIProgressView *)[cell viewWithTag:4];
                progressView.hidden           = YES;
            }

            UILabel *receiversLabel = (UILabel *)[cell viewWithTag:3];
            receiversLabel.text = username;
            
        }
        
        
        // Sending to Group
        else
        {
            NSLog(@"cellforrow outbox Sending to Group");

            cell = [tableView dequeueReusableCellWithIdentifier:GroupSendingCellIdentifier];
            if (cell == nil)
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:GroupSendingCellIdentifier];
            
            
            
            // Still uploading using Progress Bar,  so value is a number
            if (![self hasStringValueStatus:[message getStatus]])
            {
                
                
                UIProgressView *progressView  = (UIProgressView *)[cell viewWithTag:4];
                progressView.hidden           = NO;
                
                
                UILabel *timeStampLabel = (UILabel *)[cell viewWithTag:5];
                UILabel *statusLabel    = (UILabel *)[cell viewWithTag:6];
                timeStampLabel.hidden   = YES;
                statusLabel.hidden      = YES;
                
            }
            else
            {
                // Set timeStampLabel
                UILabel *timeStampLabel  = (UILabel *)[cell viewWithTag:5];
                NSDictionary *timeDate   = [KCDate getDateAndTimeFromSeconds:[message getDate]];
                NSDictionary *todaysDate = [KCDate getDictionaryFromTodaysDate];
                timeStampLabel.text      = [KCDate howLongAgoWasMessageDate:timeDate sentFrom:todaysDate];
                
                UILabel *statusLabel = (UILabel *)[cell viewWithTag:6];
                statusLabel.text     = [[message getStatus] capitalizedString];
                
                UIProgressView *progressView  = (UIProgressView *)[cell viewWithTag:4];
                progressView.hidden           = YES;
                
            }
        }
        //    Check-mark-hollow-pink
        if ([mediaType isEqualToString:IMAGE])
        {
            
            UIImageView *mediaTypeImage  = (UIImageView *)[cell viewWithTag:1];
            mediaTypeImage.contentMode = UIViewContentModeScaleAspectFit;
            
            UIImage *mediaImage = [UIImage imageNamed:@"camera-buttonA"];
            mediaTypeImage.image = mediaImage;
        }
    }
    
    
    
//    
//    check is username is broken into more than one name if so iterate and set each image for person name and
//        also is more than 3 people show 3 people plus and label stating the number of additional people
//        

    NSArray *allUsers = [username componentsSeparatedByString:@" "];
    
    NSUInteger count = [allUsers count];
    if (count > 1)
    {
        for (int i = 0; i < count && i < MAX_GROUP ; i++)
        {
            NSString *usersName = allUsers[i];
            
            UIImageView *usersFaceImage  = (UIImageView *)[cell viewWithTag:8 +i];
            [Constants makeImageRound:usersFaceImage];
            
            usersFaceImage.contentMode = UIViewContentModeScaleAspectFit;
            
            __block UIImage *userImage ;
            [self.managedObjectContext performBlockAndWait:^{
                userImage = [User getImageForContact:usersName inManagedObjectContext:self.managedObjectContext];
            }];
            
            if (userImage)
                usersFaceImage.image = userImage;
            else {
                //async call dynamodb for this person's image that awe don't have
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    NSDictionary *userDatails = [KwikcyAWSRequest getDetailsForUser:usersName];
                    if (userDatails)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (userDatails[IMAGE])
                                usersFaceImage.image = userDatails[IMAGE];
                            
                            [self.managedObjectContext performBlock:^{
                                [User insertUser:userDatails inManagedObjectContext:self.managedObjectContext];
                            }];
                        });
                    }
                });
            }
            
            
            
        }
        UILabel *extra  = (UILabel *)[cell viewWithTag:7];

        if (count > MAX_GROUP)
        {
            NSUInteger othersCount = count - MAX_GROUP;
            extra.text      = [NSString stringWithFormat:(othersCount == 1)?@"+%lu other":@"%lu others", (unsigned long)othersCount];
        }
        else
            extra.hidden = YES;
            
    }
    else
    {
        UIImageView *usersFaceImage  = (UIImageView *)[cell viewWithTag:2];
        [Constants makeImageRound:usersFaceImage];
        
        usersFaceImage.contentMode = UIViewContentModeScaleAspectFit;
        
        __block UIImage *userImage ;
        [self.managedObjectContext performBlockAndWait:^{
            userImage = [User getImageForContact:username inManagedObjectContext:self.managedObjectContext];
        }];
        
        if (userImage)
            usersFaceImage.image = userImage;
        else {
            //async call dynamodb for this person's image that awe don't have
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSDictionary *userDatails = [KwikcyAWSRequest getDetailsForUser:username];
                if (userDatails)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (userDatails[IMAGE])
                            usersFaceImage.image = userDatails[IMAGE];
                        
                        [self.managedObjectContext performBlock:^{
                            [User insertUser:userDatails inManagedObjectContext:self.managedObjectContext];
                        }];
                    });
                }
            });
        }

    }

    return cell;
}





-(void)uploadFilepath:(NSNotification *)info
{
    if (self.mailboxSegmentControl.selectedSegmentIndex == KCSegmentControlOutbox)
    {
        NSDictionary * dictionary = [info userInfo];
        
        NSNumber *percentageComplete = dictionary[PERCENTAGE_COMPLETE];
        NSString *filepath           = dictionary[FILEPATH];

        NSIndexPath *indexpath = [self.myMessageBox getIndexPathOfMessageWithFilePath:filepath];

        UITableViewCell *tableCell = [self.tableView cellForRowAtIndexPath:indexpath];
        
        UIProgressView *progressView  = (UIProgressView *)[tableCell viewWithTag:4];
        
        [progressView setProgress:[percentageComplete floatValue] animated:YES];
        NSLog(@"uploadFilepath: Current UIProgressView  : %f", progressView.progress);
        
        if (progressView.progress == 1)
        {
            NSLog(@"uploadFilepath: Current UIProgressView  = 1");

            UILabel *statusLabel = (UILabel *)[tableCell viewWithTag:6];

            
            
//            [progressView performSelector:@selector(setHidden:)
//                               withObject:[NSNumber numberWithBool:YES]
//                               afterDelay:1];
//            
//            [statusLabel performSelector:@selector(setText:)
//                               withObject:dictionary[STATUS]
//                               afterDelay:2];
//            
//            [statusLabel performSelector:@selector(setHidden:)
//                               withObject:[NSNumber numberWithBool:NO]
//                               afterDelay:2];
            
            
            
            
            
            NSDictionary *obj = @{STATUS: dictionary[STATUS],
                                  @"label":statusLabel,
                                  @"progressView": progressView};
            
            [self performSelector:@selector(updateDone:) withObject:obj afterDelay:0.6];
           
            
//            [self.tableView reloadRowsAtIndexPaths:@[indexpath] withRowAnimation:UITableViewRowAnimationNone];
            /// or reload table cell
        }

    }
}


-(void)updateDone:(NSDictionary *)obj
{
    UIProgressView *progressView  = obj[@"progressView"];
    UILabel        *statusLabel   = obj[@"label"];
    NSString       *status        = obj[STATUS];

    
    progressView.hidden = YES;
    statusLabel.text = status;
    statusLabel.hidden = NO;
}


-(BOOL)hasStringValueStatus:(NSString*)status
{
    if ([status isEqualToString:PENDING]            || [status isEqualToString:SENT]   ||
        [status isEqualToString:SENT_L]             || [status isEqualToString:FAILED] ||
        [status isEqualToString:SomeFriendsGotIt]   || [status isEqualToString:FailedToSendDoubleTap] )
    
        return YES;
    
    return NO;
}




-(void)deleteDynamoDBMessageAndImageWithDateSender:(NSString *)dateSender
                                   andWithFilepath:(NSString *)filepath
                                      fromS3Bucket:(NSString *)bucket
{
    NSLog(@"deleteDynamoDBMessageAndImageFromS3Bucket");
    
    NSString *hashKey = [AmazonKeyChainWrapper username];
    NSString *rangeKey = dateSender;
//    NSString *rangeKey = [self.recvMessage getDateSender];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
        attributeDictionary[INBOX_HASH_KEY_RECEIVER]  = [[DynamoDBAttributeValue alloc] initWithS:hashKey];
        attributeDictionary[INBOX_RANGE_KEY_FILEPATH] = [[DynamoDBAttributeValue alloc] initWithS:rangeKey];
        
        DynamoDBDeleteItemRequest * dynamoDBDeleteRequest = [[DynamoDBDeleteItemRequest alloc] initWithTableName:INBOX_TABLE
                                                                                                          andKey:attributeDictionary];
        
        [[QPNetworkActivity sharedInstance] increaseActivity];
        DynamoDBDeleteItemResponse * dynamoDBDeleteResponse = [[AmazonClientManager ddb] deleteItem:dynamoDBDeleteRequest];
        [[QPNetworkActivity sharedInstance] decreaseActivity];
        
        if (dynamoDBDeleteResponse.error)
        {
            NSLog(@"KCAsyncMediaDownloader.m deleteDynamoDBMessageAndImageFromS3Bucket Error: %@", dynamoDBDeleteResponse.error);
        }
    });
    
    
    /* Delete objects from S3 next */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
       
        [[QPNetworkActivity sharedInstance] increaseActivity];
        S3DeleteObjectResponse *s3DeleteResponse = [[AmazonClientManager s3] deleteObjectWithKey:filepath withBucket:BUCKET_NAME];
        [[QPNetworkActivity sharedInstance] decreaseActivity];
        
        if (s3DeleteResponse.error)
        {
            NSLog(@"Error deleteDynamoDBMessageAndImageFromS3Bucket deleteing objects");
        }
        
    });
}





#define Cancel 0
#define UnsendMessage 1

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath");
    
    if (self.mailboxSegmentControl.selectedSegmentIndex == KCSegmentControlInbox)
    {
        ReceivedMessage *receivedMessage = [self.myMessageBox getMessageAtIndex:indexPath.row];
        
        self.currentlyselectedReceivedMessage = receivedMessage;
        

        if ([[receivedMessage getMediaType] isEqualToString:IMAGE])
        {
            NSLog(@"Name of filepath: %@", [receivedMessage getFilePath]);
            
            
            ReceivedMessageImage *imageMsg = (ReceivedMessageImage *)receivedMessage;
            
            // View image if we stil have pointer to it
            if ([imageMsg hasBeenViewed] && [imageMsg.timeLeft integerValue] )
            {
                NSLog(@"handleTap TIMELEFT");
                
                [self performSegueWithIdentifier:@"Go To Image" sender:imageMsg];
            }
            
            // If we have no image because we viewed it, do nothing
            else if ([imageMsg hasBeenViewed]) // !imageMsg.image  or timeleft == 0
            {
                NSLog(@"handleTap VIEWED");
                return;
            }
            else
            {
                NSLog(@"handleTap UNVIEWED");

                
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                UILabel * timerCount = (UILabel *)[cell viewWithTag:5];
                timerCount.hidden = NO;
                timerCount.text = @"-";
                
                [self performSegueWithIdentifier:@"Go To Image" sender:imageMsg];
            
            }
        }
        else if ([[receivedMessage getMediaType] isEqualToString:VIDEO])
        {
            NSLog(@"receivedMessage is of video type");
        }
    }
    else
    {
        SentMessage *sentMessage = [self.myMessageBox getMessageAtIndex:indexPath.row];
        if ([[sentMessage getStatus] isEqualToString:@"Sent"])
        {
            self.sentMessageToUnsend = sentMessage;
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Options"
                                                              message:@"You can try to unsend if the user hasn't viewed the photo"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                                    otherButtonTitles:@"Unsend message", nil];
            
                                                // @"Select users to unsend"
            
            alertView.tag = UnsendMessage;
            [alertView show];
        }
    }
}




-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == Cancel)
        return;
    
    else
    {
        SentMessage *sentMsg = self.sentMessageToUnsend;

        NSString *sender = [sentMsg getSender];
        NSMutableDictionary *variables = [NSMutableDictionary new];
        
        variables[COMMAND]    = UNSEND_MESSAGE;
        
        NSString *filepath  = [sentMsg getFilePath];
        NSString *unsendKey = [sentMsg getUnsendKey];
        NSString *mediaType  = [sentMsg getMediaType];

        
        
        variables[FILEPATH]   = filepath;
        variables[UNSEND_KEY] = unsendKey;
        variables[MEDIATYPE]  = mediaType;
        
        [KwikcyClientManager sendRequestWithParameters:variables
                                 withCompletionHandler:^(BOOL receieved200Response, Response *response, NSError *error)
        {
            if ( !error )
            {
                if (receieved200Response)
                {
                    KCServerResponse *serverResponse = (KCServerResponse *)response;
                    if (serverResponse.successful)
                    
                    {
                        [[Constants alertWithTitle:@"Rejoice!" andMessage:serverResponse.info[MESSAGE]] show];

                        [self.managedObjectContext performBlock:^{
                            [Sent_message updateMessageWithStatus:@{SENDER   : sender,
                                                                    FILEPATH : filepath,
                                                                    STATUS   : @"Unsent"
                                                                    }
                                           inManagedObjectContext:self.managedObjectContext];
                        }];
                    }
                    else
                        [[Constants alertWithTitle:nil andMessage:serverResponse.message] show];
                }
                else
                    [[Constants alertWithTitle:nil
                                   andMessage:[NSString stringWithFormat:@"Could not unsend %@",mediaType]] show];
            }
            else
            {
                [[Constants alertWithTitle:@"Connection Error"
                                andMessage:@"Could not send request due to an internet connection error"] show];
            }
        }];
    }
}



-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Go To Image"])
    {
        
        ReceivedMessageImage *receivedMessage = (ReceivedMessageImage *)sender;

        
        
        self.currentImageVC = (KCImageVC*)segue.destinationViewController;
        
        if ([receivedMessage hasBeenViewed] && [receivedMessage.timeLeft integerValue])
        {
            NSLog(@"prepareForSegue: Go To Image: receivedMessage hasBeenViewed");

            if (receivedMessage.image)
                NSLog(@"prepareForSegue: Go To Image image exists");
            
            [segue.destinationViewController performSelector:@selector(setReceivedMessage:) withObject:receivedMessage];
        }
        else
        {
             [segue.destinationViewController performSelector:@selector(animateSpinningWheelForFirstTime) withObject:nil];
            
            NSLog(@"prepareForSegue: Go To Image: receivedMessage has NOT Been Viewed");

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                
                S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc]
                                                        initWithKey:[receivedMessage getFilePath] withBucket:BUCKET_NAME];
                
                
                NSLog(@"prepareForSegue: Go To Image: getting Object");

                [[QPNetworkActivity sharedInstance] increaseActivity];
                S3GetObjectResponse *response = [[AmazonClientManager s3] getObject:getObjectRequest];
                [[QPNetworkActivity sharedInstance] decreaseActivity];
                
                NSLog(@"prepareForSegue: Go To Image: got Object");

                dispatch_async(dispatch_get_main_queue(), ^{

                    if (!response.error)
                    {
                        
                        if  ( ![[receivedMessage getViewStatus] isEqualToString:@"YES"])
                        {
                            [self.managedObjectContext performBlock:^{
                                [Received_message updateStatusToYesForMessage:[receivedMessage getMessage] inManagedObjectContext:self.managedObjectContext];
                            }];
                        }
                        
                        NSData *data = response.body;
                        
                        if (data)
                        {
                            UIImage *image = [UIImage imageWithData:data];
                            
                            
                            [self deleteDynamoDBMessageAndImageWithDateSender:[receivedMessage getDateSender]
                                                              andWithFilepath:[receivedMessage getFilePath]
                                                                 fromS3Bucket:BUCKET_NAME];
                            
                            receivedMessage.image = image;
                            
                            
                            /*Start timer anyway*/
                            if (!receivedMessage.timerStarted)
                            {
                                receivedMessage.timerStarted = YES;
                                
                                // Add timer to runloop
                                NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
                                [runLoop addTimer:receivedMessage.timer forMode:NSRunLoopCommonModes];
                                
                                [[NSNotificationCenter defaultCenter] addObserver:self
                                                                         selector:@selector(countDownNotification2:)
                                                                             name:@"countDown"
                                                                           object:receivedMessage];
                            }
                        }
                    }
                    
                    [segue.destinationViewController performSelector:@selector(setReceivedMessage:) withObject:receivedMessage];
                });
            });
        }
        
    }
}




-(void)countDownNotification2:(NSNotification *)notification
{
    NSDictionary * dictionary = [notification userInfo];
    
    NSNumber *timeLeft = dictionary[@"count"];
    NSLog(@"countDownNotification timeleft:%@",timeLeft);
    
    ReceivedMessageImage *receivedMsg = dictionary[@"receivedMessage"];
    
    
    NSIndexPath *indexpath = [self.myMessageBox getIndexPathOfMessage:receivedMsg ];

    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexpath];
  

  
    ((UILabel *)[cell viewWithTag:5]).text = [receivedMsg.timeLeft stringValue];
//    ((UILabel *)[cell viewWithTag:5]).hidden = NO;
    
    
    if ([self.currentlyselectedReceivedMessage isEqual:receivedMsg])
    {
        [self.currentImageVC setCount:[receivedMsg.timeLeft stringValue]];
    }
    
    if ([timeLeft integerValue] < 1)
    {
        UIImageView *mediaTypeImage  = (UIImageView *)[cell viewWithTag:1];
        mediaTypeImage.contentMode = UIViewContentModeScaleAspectFit;
        mediaTypeImage.image =  [UIImage imageNamed:@"Check-mark-hollow-pink"];


        ((UILabel *)[cell viewWithTag:5]).hidden = YES;

//        if ([self.currentlyselectedReceivedMessage isEqual:receivedMsg])
//        {
//            ((UILabel *)[cell viewWithTag:5]).hidden = YES;
//        }

        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"countDown" object:receivedMsg];
    }
}






//-(void)segueToImage:(ReceivedMessageImage *)receivedMessage
//{
//    NSLog(@"segueToImage");
//    
//    
//    if  ( ![[receivedMessage getViewStatus] isEqualToString:@"YES"])
//    {
//        //dispatch_sync(dispatch_get_main_queue(), ^{
//        [self.managedObjectContext performBlock:^{
//            [Received_message updateStatusToYesForMessage:[receivedMessage getMessage] inManagedObjectContext:self.managedObjectContext];
//        }];
//        
//        /*Start timer anyway*/
//        if (!receivedMessage.timerStarted)
//        {
//            receivedMessage.timerStarted = YES;
//            
//            // Add timer to runloop
//            NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
//            [runLoop addTimer:receivedMessage.timer forMode:NSRunLoopCommonModes];
//            
//            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(countDownNotification:) name:@"countDown" object:receivedMessage];
//        }
//        
//    }
//    
//    [self performSegueWithIdentifier:@"Go To Image" sender:receivedMessage];
//}























































#pragma mark Clear and Delete functions




/*
 * This method will delete all messages from dynamoDB (regardless is they've been viewed or not)
 * And will delete all media from S3 is they haven't already been deleted
 * If viewed = NO, then change delte_marker to YES and viewed to YES and set a NSDATE
 */

- (IBAction)clearMessage:(UIBarButtonItem *)sender
{
 ///   For every message that we have not viewed delete from s3.
    
    NSUInteger selectedSegmentIndex = self.mailboxSegmentControl.selectedSegmentIndex;
    
    if (selectedSegmentIndex == KCSegmentControlInbox)
    {
        //Gets and deletes from core date

        NSArray * objects = [Received_message getAllReceivedMessagesToDeleteforMediaType:QPSegmentControlTypeNone
                                                                        inManagedContext:self.managedObjectContext];
        if ([objects count])
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
                [self startProgressHUDWithText:@"Clearing messages"];
              
                /* Delete objects from Dynamodb first */
                
                BOOL deletedAllMessages = [QPMailboxCDTVM deleteMessagesFromS3AndDynamoDB:objects];
                
                dispatch_async(dispatch_get_main_queue(), ^{

                    if (deletedAllMessages)
                    {
                        for (NSManagedObject *msg in [self.myMessageBox getMessages])
                        {
                            if ([msg isKindOfClass:[ReceivedMessageImage class]])
                            {
                                NSLog(@"ReceivedMessageImage clear properties");
                                [((ReceivedMessageImage*)msg) clearProperties];
                            }
                            // else if ([msg isKindOfClass:[ReceivedMessageVideo class]])
                            //{
                            //    NSLog(@"Do something else");
                            //}
                        }
                    }
                    else
                    {
                        NSLog(@"Error deleteing objects");
                    }
                

                    [self clearAllIndexPathsWithAnimation:UITableViewRowAnimationMiddle];
                    
                    [self fillUpMailbox:selectedSegmentIndex withAnimation:UITableViewRowAnimationMiddle];
               
                });
                

                [self hideProgressHUDSynchronously];
             
            });
        }
        else
        {
            NSLog(@"No objects to delete");
        }
    }
    
    else if (selectedSegmentIndex == KCSegmentControlOutbox)
    {
        //TODO: finish method
        NSLog(@"clearMessage ailboxSegmentControl");
        
        NSArray *objects = [Sent_message getMessagesToDelete:QPSegmentControlTypeNone
                                    withManagedObjectContext:self.managedObjectContext];
        
        if ([objects count])
        {
            NSLog(@"We have %lu objecs to delete from dynamodb", (unsigned long)[objects count]);
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

                [self startProgressHUDWithText:@"Clearing messages"];
                
                //delete from dynamodb and s3
                [QPMailboxCDTVM deleteFromDynamoDBTheMessages:objects];
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    
                    [self.managedObjectContext performBlockAndWait:^{
                        NSLog(@"performing block");
                        BOOL allmessagesCleared = [Sent_message removeMessages:objects withManagedObjectContext:self.managedObjectContext];
                        
                        // If allmessagesCleared && we had messages, but they are now deleted
                        if (allmessagesCleared)
                        {
                            NSLog(@"newMessagesInserted");
                            
                            [self clearAllIndexPathsWithAnimation:UITableViewRowAnimationMiddle];
                            
                            [self fillUpMailbox:selectedSegmentIndex withAnimation:UITableViewRowAnimationMiddle];
//                            [self refreshMailbox:selectedSegmentIndex];
                            
                        }
                        NSLog(@"performed block");
                        
                    }];

                    
                    
                    [self hideProgressHUDSynchronously];
                });
            });
        }
    }
}














/*
 *  Deletes all messages from dynamodb
 */

+(BOOL )deleteFromDynamoDBTheMessages:(NSArray *)objects
{
    NSError * error = nil;
    
    NSLog(@"deleteFromDynamoDBTheMessages count %d", [objects count]);
    
    DynamoDBBatchWriteItemRequest *batchWriteRequest = [DynamoDBBatchWriteItemRequest new];
    NSMutableArray *writes = [NSMutableArray arrayWithCapacity:5];
    
    NSString *TABLE;
    NSString *HASHKEY;
    NSString *RANGEKEY;
    
    if ([[objects lastObject] isKindOfClass:[Sent_message class]])
    {
        NSLog(@"RUN OUTBOX");
        TABLE    = OUTBOX_TABLE;
        HASHKEY  = OUTBOX_HASH_KEY;
        RANGEKEY = OUTBOX_RANGE_KEY;
    }
    else if ([[objects lastObject] isKindOfClass:[Received_message class]])
    {
        NSLog(@"RUN INBOX");

        TABLE    = INBOX_TABLE;
        HASHKEY  = INBOX_HASH_KEY_RECEIVER;
        RANGEKEY = INBOX_RANGE_KEY_FILEPATH;
    }
    else
        return NO;
    
    
    [batchWriteRequest setRequestItemsValue:writes forKey:TABLE];

    
    
    int counter = 1;
    
    
    NSString * hashKey = [AmazonKeyChainWrapper username];
    
    for (NSManagedObject *message in objects)
    {
        NSString *filepath;
        
        if ([message isKindOfClass:[Sent_message class]])
            filepath = ((Sent_message *)message).filepath;
        else if ([message isKindOfClass:[Received_message class]])
            filepath = ((Received_message *)message).filepath;

        if (!filepath)
            continue;
        
        NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
        
        attributeDictionary[HASHKEY ] = [[DynamoDBAttributeValue alloc] initWithS:hashKey];
        attributeDictionary[RANGEKEY] = [[DynamoDBAttributeValue alloc] initWithS:filepath];
        
        NSLog(@"hashKey:%@", hashKey);
        NSLog(@"filepath:%@", filepath);
        
        
        DynamoDBDeleteRequest *deleteRequest = [DynamoDBDeleteRequest new];
        deleteRequest.key = attributeDictionary;
        
        DynamoDBWriteRequest *writeRequest = [DynamoDBWriteRequest new];
        writeRequest.deleteRequest = deleteRequest;
        
        [writes addObject:writeRequest];
        
        
        if (counter % 25 == 0 || [objects count] == counter)
        {
            NSLog(@"deleteFromDynamoDBTheMessages counter %d", [objects count]);

            DynamoDBBatchWriteItemResponse *batchWriteResponse = nil;
            
            NSUInteger retry = 3;
            for(int i = 0; i < retry ; i++)
            {
                NSLog(@"deleteFromDynamoDBTheMessages tries %d", i);

                [[QPNetworkActivity sharedInstance] increaseActivity];
                batchWriteResponse = [[AmazonClientManager ddb] batchWriteItem:batchWriteRequest];
                [[QPNetworkActivity sharedInstance] decreaseActivity];
                
                if(!batchWriteResponse.error)
                {
                    NSLog(@"!batchWriteResponse.error");

                    if(batchWriteResponse.unprocessedItems == nil || [batchWriteResponse.unprocessedItems count] == 0
                       || i == retry)
                    {
                        break;
                    }
                    else
                    {
                        [NSThread sleepForTimeInterval:pow(2, i) * 2];
                        batchWriteRequest = [DynamoDBBatchWriteItemRequest new];
                        
                        for(NSString *key in batchWriteResponse.unprocessedItems)
                        {
                            [batchWriteRequest setRequestItemsValue:[batchWriteResponse.unprocessedItems objectForKey:key] forKey:key];
                        }
                    }
                }
                else
                {
                    NSLog(@" batchWriteResponse error:%@", batchWriteResponse.error);
                    error = batchWriteResponse.error;
                }
            }
            
//            if (batchWriteResponse.unprocessedItems && [batchWriteResponse.unprocessedItems count] > 0)
//            {
//                NSLog(@"BatchWrite failed. Some items were not processed.");
//            }
            
            if([objects count] != counter)
            {
                batchWriteRequest = [DynamoDBBatchWriteItemRequest new];
                [batchWriteRequest setRequestItemsValue:writes forKey:TABLE];

            }
        }
        counter++;
    }
    return YES;
}






/*
 * Delete rows from dynamodb
 * Does this delete messages from the tmp file ?
 *
 *  Deletes all messages from s3 and calls function to deletes from dynamodb
 */


+(BOOL)deleteMessagesFromS3AndDynamoDB:(NSArray *)objects
{
    ///   For every message that we have not viewed delete from s3.
    
    if ([objects count])
    {
        /* Delete objects from Dynamodb first */
        
        BOOL didDeleteMessages = [QPMailboxCDTVM deleteFromDynamoDBTheMessages:objects];
        
//        if (didDeleteMessages && [[objects firstObject] isKindOfClass:[Sent_message class]])
//            return YES;
//        else if (!didDeleteMessages) // && Recevied_messags class
//        {
//            
//        }NSLog(@"That's a problem, this needs to be changed to be on Kwikcy server side");
        
        
        
        /* Delete objects from S3 first */
        S3DeleteObjectsRequest *deleteObjectsRequest = [[S3DeleteObjectsRequest alloc] init];
        deleteObjectsRequest.bucket = BUCKET_NAME;
        deleteObjectsRequest.quiet = YES;
        
        
        
        for (Sent_message *message in objects)
        {
            S3KeyVersion * key = [[S3KeyVersion alloc] initWithKey:message.filepath];
            [deleteObjectsRequest.objects addObject:key];
        }
        
        [S3DeleteObjectsResponse class];
        [[QPNetworkActivity sharedInstance] increaseActivity];
        S3DeleteObjectsResponse *response = [[AmazonClientManager s3] deleteObjects:deleteObjectsRequest];
        [[QPNetworkActivity sharedInstance] decreaseActivity];

        
        
        
        if (response.error)
        {
            NSLog(@"Error deleteing objects");
            return NO;
        }
        else
            return YES;
        
//        if ([response.deleteErrors count])
//        {
//            for (id obj in response.deleteErrors)
//                NSLog(@"QPMailboxCDTVM response.deleteErrors : /n %@", response.deleteErrors);
//        }
        
        
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
    }
}


/*
 *  Deletes a single messages from dynamodb
 */

+(BOOL)deleteInboxMessageFromDynamodbWithRangeKey:(NSString *)rangeKey
{
    return [KCMessageBox deleteInboxMessageFromDynamodbWithRangeKey:rangeKey];
}

+(BOOL)deleteOutboxMessageFromDynamodbWithRangeKey:(NSString *)rangeKey
{
    [KCMessageBox deleteOutboxMessageFromDynamodbWithRangeKey:rangeKey];
}








#pragma mark - UITableViewDataSource Editable



/* This method like clearMessages will delete the indexPaths from core data and delete anything in the path in the bucketlist */

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"commitEditingStyle");
    
    NSUInteger selectedSegmentIndex = self.mailboxSegmentControl.selectedSegmentIndex;
    
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        
        
        if (selectedSegmentIndex == KCSegmentControlInbox)
        {
            
            ReceivedMessage *message = [self.myMessageBox getMessageAtIndex:indexPath.row];
           
            NSLog(@"commitEditingStyle UITableViewCellEditingStyleDelete");

            // If we have not viewed media, we must first delete it from dynamodb and S3
            if (![[message getViewStatus] isEqualToString:@"YES"])
            {
                NSLog(@"commitEditingStyle message not viewed");

                NSString *filepath = [message getFilePath];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    
                    [self startProgressHUDWithText:@"Deleting"];
                    BOOL deletedFromDynamoDBInbox = [QPMailboxCDTVM deleteInboxMessageFromDynamodbWithRangeKey:filepath];
                    
                    S3DeleteObjectRequest *dor = [[S3DeleteObjectRequest alloc] init];
                    dor.bucket = BUCKET_NAME;
                    dor.key    = filepath;

                    [[QPNetworkActivity sharedInstance] increaseActivity];
                    S3DeleteObjectResponse *deleteObjectResponse = [[AmazonClientManager s3] deleteObject:dor];
                    [[QPNetworkActivity sharedInstance] decreaseActivity];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{

                        if (!deleteObjectResponse.error)
                        {
                            NSLog(@"commitEditingStyle no error");

                            if ( [message isKindOfClass:[ReceivedMessageImage class]])
                                [((ReceivedMessageImage *)message) clearProperties];
                            
                            [self.myMessageBox removeMessageAtIndex:indexPath.row];
                            
                            
                            [self.managedObjectContext performBlock:^{
                                [Received_message markMessageForDeletion:@[ [message getMessage] ]
                                                  inManagedObjectContext:self.managedObjectContext];
                            }];
                            
                            
                            NSLog(@"+++++++++count = %d", [self.myMessageBox numberOfMessages]);
                            [self deleteIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
                    
                            if (![self.myMessageBox hasMessages])
                            {
                                [self addEmptyRowWithRowAnimation:UITableViewRowAnimationMiddle];
                            }
                            
                            [self hideProgressHUDSynchronously];

                        }
                        else
                        {
                            NSLog(@"commitEditingStyle has a BIG error");
                            
                            if ( [message isKindOfClass:[ReceivedMessageImage class]])
                                [((ReceivedMessageImage *)message) clearProperties];
                            
                            [self.myMessageBox removeMessageAtIndex:indexPath.row];
                            
                            
                            [self.managedObjectContext performBlock:^{
                                [Received_message markMessageForDeletion:@[ [message getMessage] ]
                                                  inManagedObjectContext:self.managedObjectContext];
                            }];
                            
                            
                            NSLog(@"+++++++++count = %d", [self.myMessageBox numberOfMessages]);
                            [self deleteIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
                            
                            if (![self.myMessageBox hasMessages])
                            {
                                [self addEmptyRowWithRowAnimation:UITableViewRowAnimationMiddle];
                            }
                            
                            [self hideProgressHUDSynchronously];
                        }

                       
                    });
                });
            }
            else  // If media has already been viewed
            {
                NSLog(@"commitEditingStyle ReceivedMessageImage class");

                if ( [message isKindOfClass:[ReceivedMessageImage class]])
                    [((ReceivedMessageImage *)message) clearProperties];
                
                [self.myMessageBox removeMessageAtIndex:indexPath.row];
                
                [self.managedObjectContext performBlockAndWait:^{
                    [Received_message markMessageForDeletion:@[ [message getMessage] ] inManagedObjectContext:self.managedObjectContext];
                }];
    
                
                NSLog(@"+++++++++count = %d", [self.myMessageBox numberOfMessages]);

                [self deleteIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
                
                if (![self.myMessageBox hasMessages])
                {
                    [self addEmptyRowWithRowAnimation:UITableViewRowAnimationMiddle];
                }
            }
        }
        
        
        //KCSegmentControlOutbox
        else
        {

            NSLog(@"commitEditingStyle Outbox ");
            SentMessage *message = [self.myMessageBox getMessageAtIndex:indexPath.row];
            
            
//            Sent_message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
            
            if (message)
            {
                NSLog(@"commitEditingStyle Outbox message");

                NSArray *objects = @[ [message getSentMessage] ];
    
                NSLog(@"commitEditingStyle Outbox objects");

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    
                    [self startProgressHUDWithText:@"Deleting"];
                    
                    [QPMailboxCDTVM deleteOutboxMessageFromDynamodbWithRangeKey:[message getFilePath]];
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self.managedObjectContext performBlockAndWait:^{
                            [Sent_message removeMessages:objects
                                withManagedObjectContext:self.managedObjectContext];
                        }];
                        
                        
                        [self.myMessageBox removeMessageAtIndex:indexPath.row];
                        
                        NSLog(@"commitEditingStyle Outbox removeMessageAtIndex");

                        NSLog(@"+++++++++count = %d", [self.myMessageBox numberOfMessages]);

                        [self deleteIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationLeft];
                        
                        if (![self.myMessageBox hasMessages])
                        {
                            [self addEmptyRowWithRowAnimation:UITableViewRowAnimationMiddle];
                        }
                        
                        NSLog(@"commitEditingStyle Outbox removeMessageAtIndex date");

//                        [self refreshMailbox:selectedSegmentIndex];
                        [self hideProgressHUDSynchronously];
                    });
                });
            }
        }
    }
}































 






























#pragma mark Video Methods

-(MPMoviePlayerController *)moviePlayer
{
    if(!_moviePlayer) _moviePlayer = [[MPMoviePlayerController alloc] init];
    return _moviePlayer;
    
}



- (void)setVideoForReceivedMessage:(NSString *)path;
{
    [self.hud hideProgressHUD];
    
    NSLog(@"path is %@", path);

    if (path){
        self.path = path;
        [self startPlayingVideoWithURL:nil];
    }
    else {
        NSLog(@"QPMailboxCDTVM video does not exist?");
        [[Constants alertWithTitle:@"Error" andMessage:@"Unable to get video"] show];
    }
}


- (void) startPlayingVideoWithURL:(NSURL *)url
{
    if (!url)
        url = [NSURL fileURLWithPath:self.path];

    NSLog(@"url:%@",url);
    
    NSError *error = nil;
    BOOL isReacahble = [url checkResourceIsReachableAndReturnError:&error];
    NSLog(@"isReachable :%@, %@", isReacahble ? @"YES":@"NO", error);
    
    BOOL fileExist =  [[NSFileManager defaultManager] fileExistsAtPath:self.path];
    
    if(!fileExist)
    {
        NSLog(@"File does not exist in path");
        return;
    }
        if (self.moviePlayer){
            self.moviePlayer.contentURL = url;
        
        [self installMovieNotificationObservers];
        

        [self.moviePlayer prepareToPlay];
       /// [self.moviePlayer.view setFrame:self.view.frame];
        
        self.moviePlayer.controlStyle = MPMovieControlStyleNone;

        /* Scale the movie player to fit the aspect ratio */
        self.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
        
        self.moviePlayer.shouldAutoplay = YES;
        
        [self.view addSubview:self.moviePlayer.view];
        [self.moviePlayer setFullscreen:YES animated:YES];
        [self.moviePlayer play];
 
        
    } else {
        NSLog(@"Failed to instantiate the movie player.");
    }
    
    //delete table row from here and delete the video file after video has loaded and played.
}



#pragma mark Install Movie Notifications

/* Register observers for the various movie object notifications. */

-(void)installMovieNotificationObservers
{    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:self.moviePlayer];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.moviePlayer];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:self.moviePlayer];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:self.moviePlayer];
}






#pragma mark Movie Notification Handlers

/*  Notification called when the movie finished playing. */
- (void) moviePlayBackDidFinish:(NSNotification*)notification
{
    NSLog(@"moviePlayBackDidFinish notification");

    NSNumber *reason = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
	switch ([reason integerValue])
	{
            /* The end of the movie was reached. */
		case MPMovieFinishReasonPlaybackEnded:
            NSLog(@"moviePlayBackDidFinish MPMovieFinishReasonPlaybackEnded");

            /*
             Add your code here to handle MPMovieFinishReasonPlaybackEnded.
             */			break;
            
            /* An error was encountered during playback. */
		case MPMovieFinishReasonPlaybackError:
            NSLog(@"MPMovieFinishReasonPlaybackError: An error was encountered during playback,%@ ", [[notification userInfo] objectForKey:@"error"]);
            [self performSelectorOnMainThread:@selector(displayError:) withObject:[[notification userInfo] objectForKey:@"error"]
                                waitUntilDone:NO];
           
			break;
            
            /* The user stopped playback. */
		case MPMovieFinishReasonUserExited:
            NSLog(@"moviePlayBackDidFinish MPMovieFinishReasonUserExited");

			break;
            
		default:
            NSLog(@"moviePlayBackDidFinish default");

			break;
	}

    if (self.moviePlayer)
    {
        [self.moviePlayer setFullscreen:NO animated:YES];
        [self.moviePlayer.view removeFromSuperview];
        [self deletePlayerAndNotificationObservers];
    }
}

#pragma mark Error Reporting

-(void)displayError:(NSError *)theError
{
	if (theError)
	{
		UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"Error"
                              message: [theError localizedDescription]
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
		[alert show];
	}
}



/* Handle movie load state changes. */
- (void)loadStateDidChange:(NSNotification *)notification
{
    NSLog(@"1");

	MPMoviePlayerController *player = notification.object;
	MPMovieLoadState loadState = player.loadState;
    
	/* The load state is not known at this time. */
	if (loadState & MPMovieLoadStateUnknown)
	{    NSLog(@"2 MPMovieLoadStateUnknown");

	}
	
	/* The buffer has enough data that playback can begin, but it
	 may run out of data before playback finishes. */
	if (loadState & MPMovieLoadStatePlayable)
	{    NSLog(@"3 MPMovieLoadStatePlayable");

	}
	
	/* Enough data has been buffered for playback to continue uninterrupted. */
	if (loadState & MPMovieLoadStatePlaythroughOK)
	{
        NSLog(@"4 MPMovieLoadStatePlaythroughOK");

        // Add an overlay view on top of the movie view
        
	}
	
	/* The buffering of data has stalled. */
	if (loadState & MPMovieLoadStateStalled)
	{
        NSLog(@"5 MPMovieLoadStateStalled");

	}
}

/* Called when the movie playback state has changed. */
- (void) moviePlayBackStateDidChange:(NSNotification*)notification
{
    NSLog(@"1 moviePlayBackStateDidChange");

	MPMoviePlayerController *player = notification.object;
    
	/* Playback is currently stopped. */
	if (player.playbackState == MPMoviePlaybackStateStopped)
	{
        NSLog(@"11 MPMoviePlaybackStateStopped");

//        [overlayController setPlaybackStateDisplayString:@"stopped"];
	}
	/*  Playback is currently under way. */
	else if (player.playbackState == MPMoviePlaybackStatePlaying)
	{
        NSLog(@"22 MPMoviePlaybackStatePlaying");

//        [overlayController setPlaybackStateDisplayString:@"playing"];
	}
	/* Playback is currently paused. */
	else if (player.playbackState == MPMoviePlaybackStatePaused)
	{
        NSLog(@"33 MPMoviePlaybackStatePaused");

//        [overlayController setPlaybackStateDisplayString:@"paused"];
	}
	/* Playback is temporarily interrupted, perhaps because the buffer
	 ran out of content. */
	else if (player.playbackState == MPMoviePlaybackStateInterrupted)
	{
        NSLog(@"44 MPMoviePlaybackStateInterrupted");

//        [overlayController setPlaybackStateDisplayString:@"interrupted"];
	}
}


/* Notifies observers of a change in the prepared-to-play state of an object
 conforming to the MPMediaPlayback protocol. */
- (void) mediaIsPreparedToPlayDidChange:(NSNotification*)notification
{
	// Add an overlay view on top of the movie view
//    [self addOverlayView];
    NSLog(@"1 mediaIsPreparedToPlayDidChange");
}


#pragma mark Remove Movie Notification Handlers

/* Remove the movie notification observers from the movie object. */
-(void)removeMovieNotificationHandlers
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:self.moviePlayer];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification object:self.moviePlayer];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.moviePlayer];
}

/* Delete the movie player object, and remove the movie notification observers. */
-(void)deletePlayerAndNotificationObservers
{
    [self removeMovieNotificationHandlers];
    self.moviePlayer = nil;
}


@end
