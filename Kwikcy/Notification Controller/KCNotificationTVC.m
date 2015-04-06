//
//  KCNotificationTVC.m
//  Kwikcy
//
//  Created by Hanny Aly on 7/26/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCNotificationTVC.h"

#import "AmazonClientManager.h"
#import "AmazonKeyChainWrapper.h"
#import "Constants.h"
#import "QPNetworkActivity.h"

#import "QPCoreDataManager.h"
#import "User+methods.h"
#import "KCDate.h"
#import "KwikcyAWSRequest.h"

#import <AWSDynamoDB/AWSDynamoDB.h>

#import "KwikcyClientManager.h"
#import "KCServerResponse.h"

#import "KwikcyAWSRequest.h"

@interface KCNotificationTVC ()<UIAlertViewDelegate>

@property (nonatomic, strong)           NSMutableArray          *notifications;
@property (nonatomic, strong)           NSMutableArray          *revengePoints;


@property (nonatomic, strong)           NSManagedObjectContext  *managedObjectContext;
@property (weak, nonatomic) IBOutlet    UISegmentedControl      *notificationSegmentControl;



//@property (strong, nonatomic) NSMutableDictionary *contactsDictionary;
//@property (strong, nonatomic) NSMutableArray      *alphabetKeys;


@property (strong, nonatomic) NSMutableArray      *users;

@property (nonatomic, strong) UIBarButtonItem *clearButton;

@property (nonatomic, strong) NSIndexPath  *selectedIndexPath;
@property (nonatomic, strong) NSMutableDictionary *selectedSenderInfo;





@property (nonatomic, getter = isAddingForTheFirstTime) BOOL addingForTheFirstTime;


@property (nonatomic, getter = isDeletingRows) BOOL deletingRows;
@property (nonatomic, getter = isAddingRows)   BOOL addingRows;


@property (nonatomic, getter = isAddingEmptyRow)     BOOL addingEmptyRow;
@property (nonatomic, getter = isDeletingEmptyRow)   BOOL deletingEmptyRow;

@property (nonatomic, getter = isAddingAllRow)     BOOL addingAllRow;
@property (nonatomic, getter = isDeletingAllRow)   BOOL deletingAllRow;



@property (nonatomic, strong) UIActivityIndicatorView *spinningWheel;
@end




#define NOTIFICATIONS_SEGMENT_CONTROL  0
#define REVENGE_POINTS_SEGMENT_CONTROL 1



@implementation KCNotificationTVC


-(NSManagedObjectContext *)managedObjectContext
{
    if(!_managedObjectContext)
        _managedObjectContext = [QPCoreDataManager sharedInstance].managedObjectContext;
    return _managedObjectContext;
}


-(NSMutableArray *)notifications
{
    if (!_notifications)
        _notifications = [NSMutableArray new];
    return _notifications;
}

-(NSMutableArray *)revengePoints
{
    if (!_revengePoints)
        _revengePoints = [NSMutableArray new];
    return _revengePoints;
}

-(UIActivityIndicatorView *)spinningWheel
{
    if (!_spinningWheel)
    {
        _spinningWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _spinningWheel.color = [UIColor redColor];
        _spinningWheel.hidesWhenStopped = YES;
    }
    
    return _spinningWheel;
}




-(NSMutableArray *)users
{
    if(!_users)
        _users = [NSMutableArray new];
    return _users;
}


-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.spinningWheel];

    
    if (self.managedObjectContext)
    {
        NSArray * allUsers = [User getAllContactsInManagedObjectContext:self.managedObjectContext];
        
        if (allUsers)
        {
            for (User *user in allUsers)
            {
                [self.users addObject:user];
            }
            
            [self.users sortUsingComparator:^NSComparisonResult(User *user1, User *user2) {
                return [user1.username caseInsensitiveCompare:user2.username];
            }];
        }
    }
    [self loadTable];
}


//
//
//
//-(NSUInteger)numberOfObjectsInContactsDictionary
//{
//    NSArray *keys = [self.contactsDictionary allKeys];
//    NSUInteger totalUsers = 0;
//    
//    for (int i = 0; i < [keys count]; i++)
//    {
//        NSArray *users = self.contactsDictionary[keys[i]];
//        totalUsers += [users count];
//    }
//    return totalUsers;
//}
//-(void)viewDidLoad
//{
//    [super viewDidLoad];
//    
//    if (self.managedObjectContext)
//    {
//        NSArray * allUsers = [User getAllContactsInManagedObjectContext:self.managedObjectContext];
//        
//        if (allUsers)
//        {
//            for (User *user in allUsers)
//            {
//                NSString *firstName = user.username;
//                
//                NSString *firstLetterOfUser = [[firstName substringToIndex:1] uppercaseString];
//                
//                
//                if ([[self.contactsDictionary allKeys] containsObject:firstLetterOfUser])
//                {
//                    if (![self.contactsDictionary[firstLetterOfUser] containsObject:user])
//                    {
//                        [self.contactsDictionary[firstLetterOfUser] addObject:user];
//                    }
//                }
//                else
//                {
//                    self.contactsDictionary[firstLetterOfUser] = [NSMutableArray arrayWithObject:user];
//                }
//            }
//            
//            self.alphabetKeys = [[[self.contactsDictionary allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy];
//        }
//    }
//    
//    [self loadTable];
//}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    [self refreshTable:nil];
    
    //After this completes: numberOfSections and numberOfRows are called
    
    
    
    /*
    have to choose between alphabetKets and revenge notifications. And how to combine them

    we have our contacts in core data.
    self.revengePoints notifications can be array of data from server that we add to core data
    and then we reload those rows
    and we we replace self.revengePoints with self.contactsDictionary
     
     Change self.notifications style, 
     
     If we have no notifications, we should add [NSNull null] to array and test for it
     
     
    */
    
    
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    if ([self.refreshControl isRefreshing])
        [self.refreshControl endRefreshing];
    [super viewWillDisappear:animated];
}











-(void)loadTable
{
    NSLog(@"loadTable");
    NSUInteger addingRows;
    if (self.notificationSegmentControl.selectedSegmentIndex == NOTIFICATIONS_SEGMENT_CONTROL)
    {
        addingRows = [self.notifications count];
    }
    else
    {
        addingRows = [self.users count];
    }
    
    if( addingRows )
    {
        NSMutableArray *indexPaths = [NSMutableArray new];
        
        for (int i = 0; i < addingRows; i++)
        {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        [self insertIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
    else
    {
        [self addEmptyRowWithRowAnimation:UITableViewRowAnimationMiddle];
    }
    NSLog(@"loadTable done");

}



-(void)reloadTable
{
    NSLog(@"reloadTable");
    NSUInteger deleteingRows;
    NSUInteger addingRows;
    
    if (self.notificationSegmentControl.selectedSegmentIndex == NOTIFICATIONS_SEGMENT_CONTROL)
    {
        deleteingRows = [self.users count];
        addingRows    = [self.notifications count];
    }
    else
    {
        deleteingRows = [self.notifications count];
        addingRows    = [self.users count];
    }
    
    if( deleteingRows )
    {
        NSMutableArray *indexPaths = [NSMutableArray new];
        
        for (int i = 0; i < deleteingRows; i++)
        {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        [self deleteAllIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
    else
    {
        [self deleteEmptyRowWithRowAnimation:UITableViewRowAnimationTop];
    }
    

    if( addingRows )
    {
        NSMutableArray *indexPaths = [NSMutableArray new];
        
        for (int i = 0; i < addingRows; i++)
        {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        [self insertIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
    else
    {
        [self addEmptyRowWithRowAnimation:UITableViewRowAnimationMiddle];
    }
    NSLog(@"reloadTable done");
}







-(void)refreshTable:(UIRefreshControl *)sender
{
    NSLog(@"refreshTable");

    if (self.notificationSegmentControl.selectedSegmentIndex == NOTIFICATIONS_SEGMENT_CONTROL)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            dispatch_async(dispatch_get_main_queue(), ^{

                [self.spinningWheel startAnimating];
        
            });
            
            NSMutableArray *newNotifications = [KwikcyAWSRequest getNotificationsForTable:NOTIFICATION_TABLE
                                                                  withHashKey:NOTIFICATION_HASH_KEY
                                                                forAttributes:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.spinningWheel stopAnimating];

                NSMutableArray *nonDuplicateNotifications = [self getNonDuplicateNewNotifications:newNotifications];
            
            
                // If we're still on the screen
                if (self.notificationSegmentControl.selectedSegmentIndex == NOTIFICATIONS_SEGMENT_CONTROL)
                {
                    if ([nonDuplicateNotifications count])
                        [self insertIntoTableViewNewNotifications:nonDuplicateNotifications];
//                    else
//                    {
//                        
//                        NSMutableArray *indexPaths = [NSMutableArray new];
//                        
//                        for (int i = 0; i < [self.notifications count]; i++)
//                        {
//                            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
//                        }
//        
//                        
//                        NSLog(@"RELOAD DATA");
//                        [self updateIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
//                    }
                }
               

                if ([sender isRefreshing])
                    [sender endRefreshing];
            });
        });
    }

    
    
    else // REVENGE_POINTS_SEGMENT_CONTROL
    {
        NSLog(@"refreshTable notificationSegmentControl REVENGE_POINTS_SEGMENT_CONTROL");

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                [self.spinningWheel startAnimating];
                
            });
            
            NSMutableArray *newNotifications = [KwikcyAWSRequest getNotificationsForTable:REVENGE_POINTS_TABLE
                                                                  withHashKey:REVENGE_HASH_KEY
                                                                forAttributes:[NSMutableArray arrayWithArray:@[REVENGE_RANGE_KEY_AGAINST, REVENGE_POINTS]]];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                [self.spinningWheel stopAnimating];

                
                // If we're still on the screen
                if (self.notificationSegmentControl.selectedSegmentIndex == REVENGE_POINTS_SEGMENT_CONTROL)
                {
                    NSLog(@"refreshTable REVENGE_POINTS_SEGMENT_CONTROL");

                    [self refreshRevengeNotifications:newNotifications];
                }
                
                if ([sender isRefreshing])
                    [sender endRefreshing];
                NSLog(@"refreshTable done");
            });
        });
    }
}






- (IBAction)switchNotificationTableView:(UISegmentedControl *)sender
{
    // query and get kcIOU table info for user and add it to _pointNotifications
    
    if ([self.spinningWheel isAnimating])
        [self.spinningWheel stopAnimating];
    
    if (sender.selectedSegmentIndex == NOTIFICATIONS_SEGMENT_CONTROL)
    {
        self.navigationItem.rightBarButtonItem = self.clearButton;
        self.clearButton = nil;
    }
    else
    {
        self.clearButton = self.navigationItem.rightBarButtonItem;
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    [self reloadTable];
    
    [self refreshTable:nil];
}







-(void)refreshRevengeNotifications:(NSMutableArray *)notifications
{
    if (![notifications count])
        return;
    
    NSMutableArray *indexPathsToUpdate = [NSMutableArray new];
    NSMutableArray *indexPathsToInsert = [NSMutableArray new];

    
    for (NSDictionary *notification in notifications)
    {
        NSString *user   = notification[REVENGE_RANGE_KEY_AGAINST];
        NSString *points = notification[REVENGE_POINTS];
        
        BOOL didFindUserInRevengeNotifications;
        for (NSMutableDictionary * notice in self.revengePoints)
        {
            if ([notice[REVENGE_RANGE_KEY_AGAINST] isEqualToString:user])
            {
                didFindUserInRevengeNotifications = YES;
               
                if( ![notice[REVENGE_POINTS] isEqualToString:points] )
                {
                    NSLog(@"refreshRevengeNotifications: adding new points");

                    notice[REVENGE_POINTS] = points;
                    
                    NSIndexPath *indexPath = [self indexPathForUser:user];
                    if (indexPath)
                        [indexPathsToUpdate addObject:indexPath];
                }
                break;
            }
        }
        
        if( !didFindUserInRevengeNotifications )
        {
            [self.revengePoints addObject:notification];
            NSLog(@"Error: did not FindUserInRevengeNotifications");

            NSIndexPath *indexPath = [self indexPathForUser:user];
           
            //If user found in our contacts
            if (indexPath)
            {
                NSLog(@"Error none: didFindUserInRevengeNotifications ok");

                [indexPathsToUpdate addObject:indexPath];
            }
            else
            {
                // If not found we have to add new user into core data contacts and insert row
                NSLog(@"Error: User %@ not found", user);
                NSLog(@"TODO: Insert new row");
                [indexPathsToInsert addObject:indexPath];

            }
        }
    }
    
    
    if([self.users count])
    {
        NSLog(@"refreshRevengeNotifications insert and update");

        if([indexPathsToInsert count])
            NSLog(@"refreshRevengeNotifications indexPathsToInsert has items");

        
        if([indexPathsToUpdate count])
            NSLog(@"refreshRevengeNotifications indexPathsToUpdate has items");

        [self insertIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationMiddle];
        [self updateIndexPaths:indexPathsToUpdate withRowAnimation:UITableViewRowAnimationFade];
    }
    else
    {
        NSLog(@"refreshRevengeNotifications insert only");
        [self insertIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationMiddle];
    }
}



-(NSIndexPath *)indexPathForUser:(NSString *)username
{
    for (int i = 0; i < [self.users count]; i++)
    {
        User *user = self.users[i];
        
        if ([user.username isEqualToString:username])
        {
            return [NSIndexPath indexPathForRow:i inSection:0];
        }
    }
    
    return nil;
}










- (IBAction)pulldownRefresh:(UIRefreshControl *)sender
{
    NSLog(@"pulldownRefresh");
    [self refreshTable:sender];
}






/*
 *  Returns array of notifications not already found in self.notifications
 */

-(NSMutableArray *)getNonDuplicateNewNotifications:(NSMutableArray *)notifications
{
    NSLog(@"addNonDuplicateNewNotifications");
    NSMutableArray *nonDups = [NSMutableArray array];
    
    if (self.notificationSegmentControl.selectedSegmentIndex == NOTIFICATIONS_SEGMENT_CONTROL)
    {
        for (NSDictionary *notification in notifications)
        {
            NSString *noticationType = notification[NOTIFICATION];
            if ([noticationType isEqualToString:SCREENSHOT_NOTIFICATION])
            {
                NSString * rangeKey = notification[FILEPATH];
                
                BOOL found = NO;
                for (NSDictionary *dic in self.notifications)
                {
                    if ([dic[FILEPATH] isEqualToString:rangeKey])
                    {
                        found = YES;
                        break;
                    }
                }
                if (!found)
                {
                    [nonDups addObject:notification];
                }
            }
            else if ([noticationType isEqualToString:REQUEST_TO_ADD_CONTACT] ||
                     [noticationType isEqualToString:RESPONSE_TO_ADD_CONTACT] ||
                     [noticationType isEqualToString:NOTICE])
            {
                NSString * rangeKey = notification[FILEPATH];
                
                BOOL found = NO;
                for (NSDictionary *dic in self.notifications)
                {
                    if ([dic[FILEPATH] isEqualToString:rangeKey])
                    {
                        found = YES;
                        break;
                    }
                }
                if (!found)
                {
                    [nonDups addObject:notification];
                }
            }
            
        }
    }
    else
    {
        for (NSDictionary *revengeNotification in notifications)
        {
            NSString * user = revengeNotification[REVENGE_RANGE_KEY_AGAINST];
            
            BOOL found = NO;
            for (NSDictionary *dic in self.revengePoints)
            {
                if ([dic[REVENGE_RANGE_KEY_AGAINST] isEqualToString:user])
                {
                    found = YES;
                    break;
                }
            }
            if (!found)
            {
                [nonDups addObject:revengeNotification];
            }
        }
    }
    
    return nonDups;
}




-(void)insertIntoTableViewNewNotifications:(NSMutableArray *)newNotificationsAdded
{
    NSLog(@"insertIntoTableViewNewNotifications");
    NSUInteger numberOfNewNotificationsToAdd = [newNotificationsAdded count];
    
    if (!numberOfNewNotificationsToAdd)
        return;

    
    if (self.notificationSegmentControl.selectedSegmentIndex == NOTIFICATIONS_SEGMENT_CONTROL)
    {
        NSInteger previousNumberOfNotificationsInArray = [self.notifications count];

        [self.notifications addObjectsFromArray:newNotificationsAdded];
        
        
//        [self.notifications sortUsingComparator:^NSComparisonResult(NSDictionary *notice1, NSDictionary *notice2) {
//            return [notice1[DATE] caseInsensitiveCompare:notice2[DATE]];
//        }];
        
        
        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:DATE ascending:NO];
        self.notifications = [[self.notifications sortedArrayUsingDescriptors:@[descriptor]] mutableCopy];
        

        NSMutableArray *indexPaths = [NSMutableArray new];
        
        if (!previousNumberOfNotificationsInArray)  // if empty, table view is showing  "NO new notifications"
        {
            [self deleteEmptyRowWithRowAnimation:UITableViewRowAnimationMiddle];
            
            NSInteger notificationsCount =  [ self.notifications count];
            
            for (int i = 0; i < notificationsCount; i++)
            {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            [self insertIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
            
            //            [self.tableView reloadData];
        }
        else
        {
            NSMutableArray *indexPaths = [NSMutableArray array];
            
            for (NSDictionary *obj in newNotificationsAdded)
            {
                NSUInteger index = [self.notifications indexOfObject:obj];
                [indexPaths addObject:[NSIndexPath indexPathForItem:index inSection:0]];
            }
            [self insertIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        }
    }
    
    
    else // REVENGE_POINTS_SEGMENT_CONTROL
    {
        NSInteger previousNumberOfNotificationsInArray = [self.revengePoints count];
        
        [self.revengePoints addObjectsFromArray:newNotificationsAdded];
        
//        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:REVENGE_RANGE_KEY_AGAINST ascending:YES];
//        self.revengePoints = [[self.revengePoints sortedArrayUsingDescriptors:@[descriptor]] mutableCopy];

        
        
        
        
        
        if (!previousNumberOfNotificationsInArray)  // if empty, table view is showing  "NO new notifications"
        {
            NSLog(@"insertIntoTableViewNewNotifications REVENGE empty");
            [self deleteEmptyRowWithRowAnimation:UITableViewRowAnimationMiddle];
        }
        else
        {
            NSLog(@"insertIntoTableViewNewNotifications REVENGE not empty");
        }
        
        
        
        NSMutableArray *indexPaths = [NSMutableArray array];
        
        for (NSDictionary *obj in newNotificationsAdded)
        {
            NSUInteger index = [self.revengePoints indexOfObject:obj];
            [indexPaths addObject:[NSIndexPath indexPathForItem:index inSection:0]];
        }
        NSLog(@"insertIntoTableViewNewNotifications REVENGE not empty inserting");
        
        [self insertIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    
    }
}











#pragma mark Table View Insert/Delete IndexPaths

-(void)deleteIndexPaths:(NSArray *)indexPaths withRowAnimation:(NSInteger)animation
{
    if (![indexPaths count])
        return;
    self.deletingRows = YES;
    
    [self.tableView deleteRowsAtIndexPaths:indexPaths
                          withRowAnimation:animation ];
    
    self.deletingRows = NO;
}



-(void)insertIndexPaths:(NSArray *)indexPaths withRowAnimation:(NSInteger)animation
{
    if (![indexPaths count])
        return;
    self.addingRows = YES;
    [self.tableView insertRowsAtIndexPaths:indexPaths
                          withRowAnimation:animation];
    self.addingRows = NO;
}



-(void)updateIndexPaths:(NSArray *)indexPaths withRowAnimation:(NSInteger)animation
{
    if (![indexPaths count])
        return;
//    self.addingRows = YES;
    [self.tableView reloadRowsAtIndexPaths:indexPaths
                          withRowAnimation:animation];
//    self.addingRows = NO;
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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"numberOfRowsInSection");
    if (self.isDeletingEmptyRow || self.isDeletingAllRow)
    {
        NSLog(@"numberOfRowsInSection deleteing all rows or isDeletingEmptyRow");
        return 0;
    }
    
    if (self.isDeletingRows)
    {
        return [self.notifications count] ? [self.notifications count]: 0;
   
    }

    if (self.isAddingRows)
    {
        NSLog(@"numberOfRowsInSection isAddingRows");

        if (self.notificationSegmentControl.selectedSegmentIndex == NOTIFICATIONS_SEGMENT_CONTROL)
        {
            NSLog(@"numberOfRowsInSection isAddingRows notifications %d", [self.notifications count]);

            return [self.notifications count];
        }
        else
        {
            NSLog(@"numberOfRowsInSection isAddingRows revengePoints %d", [self.users count]);

            return [self.users count];
        }
    }
    
    if(self.isAddingEmptyRow)
    {
        NSLog(@"numberOfRowsInSection isAddingEmptyRow");
        return 1;
    }
    
    if (self.notificationSegmentControl.selectedSegmentIndex == NOTIFICATIONS_SEGMENT_CONTROL)
    {
        NSLog(@"numberOfRowsInSection NOTIFICATIONS_SEGMENT_CONTROL");

        return [self.notifications count] ? [self.notifications count]: 1;
    }
    else
    {
        NSLog(@"numberOfRowsInSection REVENGE_POINTS_SEGMENT_CONTROL [self.users count] = %d", [self.users count]);

        return [self.users count] ? [self.users count]: 1;
    }
}




/*
 *
    TODO: We should not have to test self.notificationSegmentControl.selectedSegmentIndex each time,
            Instead we should check what the notification type of the selected item.
 
 *  Test Cases:
 *
 *      1) SCREENSHOT_NOTIFICATION
 *      2) REQUEST_TO_ADD_CONTACT
 *
 */

#define TagTypeScreenShot           1
#define TagTypeScreenShotContacts   2
#define TagTypeRequestAdd           3
#define TagTypeResponseToAdd        4



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.notificationSegmentControl.selectedSegmentIndex == NOTIFICATIONS_SEGMENT_CONTROL)
    {
        NSMutableDictionary *notification = [self.notifications objectAtIndex:indexPath.row];
        
        NSString *notificationType = notification[NOTIFICATION];
        NSString *sender           = notification[SENDER];

        
        
        notification[@"IndexPath"] = indexPath;
        notification[@"selectedSegment"] = @(NOTIFICATIONS_SEGMENT_CONTROL);
        

        
        self.selectedSenderInfo = notification;
        
        if ([notificationType isEqualToString:SCREENSHOT_NOTIFICATION])
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"What to do with %@", sender]
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Notify user's friends",
                                                                        @"Publicize user's profile image",
                                                                        @"Forgive", nil];
            
//            @"Publicize a private photo to their friends WOS",

            alertView.tag = TagTypeScreenShot;
            [alertView show];
            
            
        }
        else if ([notificationType isEqualToString:REQUEST_TO_ADD_CONTACT])
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Accept request",
                                                                        @"Deny request", nil];

            alertView.tag = TagTypeRequestAdd;
            [alertView show];
        }
        
//        else if ([notificationType isEqualToString:RESPONSE_TO_ADD_CONTACT])
//        {
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
//                                                                message:nil
//                                                               delegate:self
//                                                      cancelButtonTitle:@"Cancel"
//                                                      otherButtonTitles:@"Accept request", @"Deny request", nil];
//            
//            alertView.tag = TagTypeRequestAdd;
//            [alertView show];
//        }
        

        
        
    }
    else
    {
        User *user = [self.users objectAtIndex:indexPath.row];
        
        for (NSMutableDictionary *notice in self.revengePoints)
        {
            if ([notice[REVENGE_RANGE_KEY_AGAINST] isEqualToString:user.username])
            {
                if ([notice[CLICKABLE] boolValue]) // if ([notice[REVENGE_POINTS] integerValue])
                {
                    notice[@"IndexPath"] = indexPath;
                    notice[@"selectedSegment"] = @(NOTIFICATIONS_SEGMENT_CONTROL);
                    
                    self.selectedSenderInfo = notice;
                    
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"What to do with %@", user.username]
                                                                        message:nil
                                                                       delegate:self
                                                              cancelButtonTitle:@"Cancel"
                                                              otherButtonTitles:@"Notify user's friends",
                                                                                @"Publicize user's profile image",
                                                                                @"Forgive", nil];
                    
                    //            @"Publicize a private photo to their friends WOS",
                    
                    alertView.tag = TagTypeScreenShotContacts;
                    [alertView show];
                    
                }

                break;
            }
        }
    }
}


#define Cancel          0
#define AcceptRequest   1
#define DenyRequest     2
#define BlockUser       3


#define NotifyFriends           1
#define PublicizeProfile        2
#define StealPhoto              3
#define ForgiveUser             4





/*
 *  Test Cases:
 *
 *      1) SCREENSHOT_NOTIFICATION
 *      2) REQUEST_TO_ADD_CONTACT
 *
 */



#define RESPONSE                    @"Response"

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == Cancel)
        return;
    
    
    if (alertView.tag == TagTypeScreenShot)
    {
        NSLog(@"clickedButtonAtIndex for TagTypeScreenShot");

        NSMutableDictionary *info = self.selectedSenderInfo;
        
        
        
        NSString    *notificationType = info[NOTIFICATION];
        NSString    *sender           = info[SENDER];
        NSIndexPath *indexPath        = info[@"IndexPath"];
       
        
        // let the tableviewcell be unable clickable
        info[CLICKABLE] = @(NO);

        
        NSUInteger selectedSegmentIndex = NOTIFICATIONS_SEGMENT_CONTROL;
      
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

        cell.userInteractionEnabled =  [info[CLICKABLE] boolValue];
        
        
        
        NSMutableDictionary *parameters = [NSMutableDictionary new];
        
        parameters[COMMAND]  = SCREENSHOT_RESPONSE;
        
        parameters[RECEIVER] = sender;
        parameters[FILEPATH] = info[FILEPATH];

        
        if (buttonIndex == NotifyFriends)
            parameters[ACTION] = @"NotifyFriends";
        else if (buttonIndex == PublicizeProfile)
            parameters[ACTION] = @"PublizeWorld";
        else if (buttonIndex == ForgiveUser)
            parameters[ACTION] = @"Forgive";
        

        [self.spinningWheel startAnimating];
        
        [KwikcyClientManager sendRequestWithParameters:parameters
                                 withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
         {
             [self.spinningWheel stopAnimating];
             
             
             if (error)
             {
                 info[CLICKABLE] = @(YES);

                 [[Constants alertWithTitle:@"Connection Error"
                                 andMessage:@"Could not connect to server. Check your connection"] show];
             }
             else
             {
                 KCServerResponse *serverResponse = (KCServerResponse *)response;
                 
                 if (received200Response)
                 {
                     if (serverResponse.successful)
                     {
                         //Make cell userINteration diabled
                        
                         if (buttonIndex == NotifyFriends)
                             [[Constants alertWithTitle:nil andMessage:@"User's friends will be notified"] show];
                         
                         else if (buttonIndex == PublicizeProfile)
                             [[Constants alertWithTitle:nil andMessage:@"User added to WOS "] show];

                         else if (buttonIndex == ForgiveUser)
                             [[Constants alertWithTitle:nil andMessage:@"User has been forgiven"] show];
                         

                     }
                     else
                     {
                         info[CLICKABLE] = @(YES);

                         NSLog(@"serverResponse was unsuccessful!");
                         [[Constants alertWithTitle:@"Error" andMessage:serverResponse.message] show];
                     }
                 }
             }
             
             cell.userInteractionEnabled =  [info[CLICKABLE] boolValue];

         }];
    }
    
    
    
    
    if (alertView.tag == TagTypeScreenShotContacts)
    {
        NSLog(@"clickedButtonAtIndex for TagTypeScreenShotContacts");
        
        NSMutableDictionary *info = self.selectedSenderInfo;
        
        
        NSString    *against           = info[REVENGE_RANGE_KEY_AGAINST];
        
        
        // let the tableviewcell be unable clickable
        info[CLICKABLE] = @(NO);
        
        NSIndexPath *indexPath        = info[@"IndexPath"];
        UITableViewCell *cell         = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.userInteractionEnabled   =  [info[CLICKABLE] boolValue];
        
        
        
        NSMutableDictionary *parameters = [NSMutableDictionary new];
        
        parameters[COMMAND]  = SCREENSHOT_RESPONSE;
        
        parameters[RECEIVER] = against;
        parameters[FILEPATH] = @"null";
        
        
        if (buttonIndex == NotifyFriends)
            parameters[ACTION] = @"NotifyFriends";
        else if (buttonIndex == PublicizeProfile)
            parameters[ACTION] = @"PublizeWorld";
        else if (buttonIndex == ForgiveUser)
            parameters[ACTION] = @"Forgive";
        
        
        [self.spinningWheel startAnimating];
        
        [KwikcyClientManager sendRequestWithParameters:parameters
                                 withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
         {
             [self.spinningWheel stopAnimating];
             
             
             if (error)
             {
                 info[CLICKABLE] = @(YES);
                 
                 [[Constants alertWithTitle:@"Connection Error"
                                 andMessage:@"Could not connect to server. Check your connection"] show];
             }
             else
             {
                 KCServerResponse *serverResponse = (KCServerResponse *)response;
                 
                 if (received200Response)
                 {
                     if (serverResponse.successful)
                     {
                         //Make cell userINteration diabled
                         
                         if (buttonIndex == NotifyFriends)
                             [[Constants alertWithTitle:nil andMessage:@"User's friends will be notified"] show];
                         
                         else if (buttonIndex == PublicizeProfile)
                             [[Constants alertWithTitle:nil andMessage:@"User added to WOS "] show];
                         
                         else if (buttonIndex == ForgiveUser)
                             [[Constants alertWithTitle:nil andMessage:@"User has been forgiven"] show];
                         
                         
                         
                     }
                     else
                     {
                         info[CLICKABLE] = @(YES);
                         
                         NSLog(@"serverResponse was unsuccessful!");
                         [[Constants alertWithTitle:@"Error" andMessage:serverResponse.message] show];
                     }
                 }
                 
                 
                 NSLog(@"Class type %@", [serverResponse.info[@"updatedPoints"] class] );
                 NSNumber *updatedPoints = serverResponse.info[@"updatedPoints"];

                 NSLog(@"updatedPoints = %@", updatedPoints);
                 
                 
                 if ([updatedPoints intValue])
                     info[CLICKABLE] = @(YES);
                 else
                     info[CLICKABLE] = @(NO);
                 
                 
                 info[REVENGE_POINTS] = [updatedPoints stringValue];
//                 pointCount.text = notificaiton[REVENGE_POINTS] ? notificaiton[REVENGE_POINTS]: @"0";

             }
             
             [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
             
             
//             cell.userInteractionEnabled =  [info[CLICKABLE] boolValue];
             
         }];
    }
    
    
    
    
    
    
    else if (alertView.tag == TagTypeRequestAdd)
    {
        if (buttonIndex == AcceptRequest  || buttonIndex == DenyRequest)
        {
            NSMutableDictionary *info = self.selectedSenderInfo;
            
            
            
            NSString    *notificationType = info[NOTIFICATION];
            NSString    *sender           = info[SENDER];
            NSIndexPath *indexPath        = info[@"IndexPath"];
            
            info[CLICKABLE] = @(NO);
            
            
//            NSUInteger selectedSegmentIndex = NOTIFICATIONS_SEGMENT_CONTROL;
            
            
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            
            cell.userInteractionEnabled =  [info[CLICKABLE] boolValue];
            
            
            
            //RESPONSE_TO_ADD_CONTACT
            NSMutableDictionary *parameters = [NSMutableDictionary new];
            
            parameters[COMMAND]         = RESPONSE_TO_ADD_CONTACT;
            parameters[STATUS_FRIEND]   = sender;
            parameters[FILEPATH]        = info[FILEPATH];

            
            if (buttonIndex == AcceptRequest)
                parameters[STATUS]  = STATUS_FRIEND;
            else if (buttonIndex == DenyRequest)
                parameters[STATUS]  = STATUS_DENIED;
        

            
            
            [self.spinningWheel startAnimating];
            

            [KwikcyClientManager sendRequestWithParameters:parameters
                                     withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
             {
                 [self.spinningWheel stopAnimating];

                 if (error)
                 {
                     info[CLICKABLE] = @(YES);

                     [[Constants alertWithTitle:@"Connection Error"
                                     andMessage:@"Could not connect to server. Check your connection"] show];
                 }
                 else
                 {
                     KCServerResponse *serverResponse = (KCServerResponse *)response;
                     
                     if (received200Response)
                     {
                         if (serverResponse.successful)
                         {
                             NSLog(@"serverResponse.successful! info: %@", serverResponse.info);
                             //Update core data?
                             
                              if (buttonIndex == DenyRequest)
                                  return;
                             
                             else if (buttonIndex == AcceptRequest)
                             {
                                 
                                 NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
   
                                 userInfo[USERNAME] = sender;
                                 userInfo[STATUS] = STATUS_FRIEND;
                                 
                                 NSMutableDictionary *userDetails = [KwikcyAWSRequest getDetailsForUser:sender];
                                 
                              
                                 if(userDetails[REALNAME])
                                     userInfo[REALNAME] = userDetails[REALNAME];
                                 if(userDetails[IMAGE])
                                     userInfo[IMAGE]     = UIImageJPEGRepresentation(userDetails[IMAGE], 1);
                                 
                                 if (self.managedObjectContext)
                                 {
                                     [self.managedObjectContext performBlock:^{
                                         [User insertUser:userInfo inManagedObjectContext:self.managedObjectContext];
                                     }];
                                 }
                             }
                         }
                         else
                         {
                             info[CLICKABLE] = @(YES);

                             NSLog(@"serverResponse was unsuccessful!");
                             [[Constants alertWithTitle:@"Error" andMessage:serverResponse.message] show];
                         }
                     }
                 }
                 
                 cell.userInteractionEnabled =  [info[CLICKABLE] boolValue];

             }];
        }
        
        
        else if (buttonIndex == BlockUser)
        {
            
        }
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Notification table cellForRowAtIndexPath");
    if (self.notificationSegmentControl.selectedSegmentIndex == NOTIFICATIONS_SEGMENT_CONTROL)
    {
        
        static NSString *ScreenShotNotificationIdentifier = @"ScreenShotNotificationCell";
        static NSString *EmptyCell = @"EmptyCell";
        
        
        if (![self.notifications count])
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:EmptyCell];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:EmptyCell];
            }
            cell.userInteractionEnabled = NO;
            return cell;
        }
        
        
        
        
        
        NSDictionary *notification = self.notifications[indexPath.row];
        NSString *notificationType = notification[NOTIFICATION];

        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ScreenShotNotificationIdentifier forIndexPath:indexPath];
        if (!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:ScreenShotNotificationIdentifier];
        
        cell.userInteractionEnabled =  [notification[CLICKABLE] boolValue];

        
        NSString *userName = notification[SENDER];

        UIImageView *mediaTypeImage = (UIImageView *)[cell viewWithTag:1];
        mediaTypeImage.contentMode  = UIViewContentModeScaleAspectFit;
        UILabel *messageLabel = (UILabel *)[cell viewWithTag:3];

        if ([notificationType isEqualToString:SCREENSHOT_NOTIFICATION])
        {
            mediaTypeImage.image = [UIImage imageNamed:@"X-mark-filled-pink"];

            messageLabel.text = [NSString stringWithFormat:@"%@ screenshoted you", userName];

        }
        else if ([notificationType isEqualToString:REQUEST_TO_ADD_CONTACT])
        {
            //TODO WHAT IMAGE TO ADD HERE????
            mediaTypeImage.image = [UIImage imageNamed:@"RECEIVED NOTIFICATION???"];
            
            messageLabel.text = [NSString stringWithFormat:@"%@ wants to be friends", userName];
            
        }
        else if ([notificationType isEqualToString:RESPONSE_TO_ADD_CONTACT])
        {
            NSString *mesage = notification[MESSAGE];
            if ([mesage isEqualToString:STATUS_FRIEND])
            {
                mediaTypeImage.image = [UIImage imageNamed:@"FRIEND NOTIFICATION???"];
                messageLabel.text = [NSString stringWithFormat:@"%@ accepted friend request", userName];
            }
            
            else if ([mesage isEqualToString:STATUS_DENIED])
            {
                mediaTypeImage.image = [UIImage imageNamed:@"DENIED NOTIFICATION???"];
                messageLabel.text = [NSString stringWithFormat:@"%@ doesn't want to friends", userName];
            }
        }
        
        else if ([notificationType isEqualToString:NOTICE])
        {
            mediaTypeImage.image = nil;

            messageLabel.text = notification[MESSAGE];
        }
        
        
        
        
        UIImageView *usersFaceImage  = (UIImageView *)[cell viewWithTag:2];
        
        [Constants makeImageRound:usersFaceImage];
        
        usersFaceImage.contentMode = UIViewContentModeScaleAspectFit;
        
        
        __block UIImage *userImage ;
        [self.managedObjectContext performBlockAndWait:^{
            userImage = [User getImageForContact:userName inManagedObjectContext:self.managedObjectContext];
            
        }];
        
        // if we have person's image, use it
        if (userImage)
            usersFaceImage.image = userImage;
        else {
            NSLog(@"********** PHOTO MISSING");
            //async call dynamodb for this person's image that awe don't have
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                UIImage *image = [KwikcyAWSRequest getProfileImageForUser:userName];
                dispatch_async(dispatch_get_main_queue(), ^{
                    //TODO: store image in core data
                    usersFaceImage.image = image;
                });
            });
        }
        
        
        // Set timeStampLabel
        UILabel *timeStampLabel = (UILabel *)[cell viewWithTag:4];
        
        //message.date is in seconds so convert
        NSDictionary *timeDate   = [KCDate getDateAndTime:notification[DATE]];
        
        NSDictionary *todaysDate = [KCDate getDictionaryFromTodaysDate];
        timeStampLabel.text = [KCDate howLongAgoWasMessageDate:timeDate sentFrom:todaysDate];

        return cell;
    }
    
    
    
    
    else  // REVENGE_POINTS_SEGMENT_CONTROL
    {
        NSLog(@"Notification: cellForRowAtIndexPath: REVENGE_POINTS_SEGMENT_CONTROL");
        

        static NSString *RevengeCellIdentifier     = @"RevengeCell";
        static NSString *RevengeNoNameCelldentifier     = @"RevengeNoNameCell";
        
        static NSString *EmptyPointsCellIdentifier = @"EmptyPointsCell";
        
        
        if (![self.users count])
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:EmptyPointsCellIdentifier];
            
            if (!cell)
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:EmptyPointsCellIdentifier];
            
            cell.userInteractionEnabled = NO;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
    
        
        User *user = self.users[indexPath.row];
        
        UITableViewCell *cell;
        if (!user.realname)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:RevengeNoNameCelldentifier];
        
            if (!cell)
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RevengeNoNameCelldentifier];
        }
        else
        {
            cell = [tableView dequeueReusableCellWithIdentifier:RevengeCellIdentifier];
            
            if (!cell)
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RevengeCellIdentifier];
          
            UILabel *realname     = (UILabel *)[cell viewWithTag:3];
            realname.text = user.realname;
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        
        UILabel     *username     = (UILabel *)[cell viewWithTag:2];
        UIImageView *usersImage   = (UIImageView *)[cell viewWithTag:1];
        UILabel     *pointCount   = (UILabel *)[cell viewWithTag:4];
        
        
        [Constants makeImageRound:usersImage];
        usersImage.contentMode = UIViewContentModeScaleAspectFit;

        
        username.text = user.username;
        
        pointCount.text = @"0";
        NSLog(@"Notification: cellForRowAtIndexPath: point 0");

        for (NSDictionary *notificaiton in self.revengePoints)
        {
            if([user.username isEqualToString:notificaiton[REVENGE_RANGE_KEY_AGAINST]])
            {
                pointCount.text = notificaiton[REVENGE_POINTS] ? notificaiton[REVENGE_POINTS]: @"0";
                
                if ([pointCount.text intValue])
                {
                    cell.userInteractionEnabled = YES;
                }
                break;
            }
        }
        
        
        UIImage *personImage = [UIImage imageWithData:user.data];
        
        if (personImage)
            usersImage.image = personImage;
        else
        {
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                
                UIImage *userimage = [KwikcyAWSRequest getProfileImageForUser:username.text];
                
                if (userimage)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        usersImage.image = userimage;
                    });
                }
            });
        }
        
        return cell;
    }
}




// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.notificationSegmentControl.selectedSegmentIndex == NOTIFICATIONS_SEGMENT_CONTROL && [self.notifications count])
        return YES;
    else
        return NO;
}





 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
     NSLog(@"commitEditingStyle:forRowAtIndexPath:");
     if (editingStyle == UITableViewCellEditingStyleDelete)
     {
         // Delete the row from the data source
         BOOL deleted = [self deleteSingleMessageFromDynamoDB:self.notifications[indexPath.row]];
         if (!deleted)
             return;
         
         [self.notifications removeObjectAtIndex:indexPath.row];
         
         if (![self.notifications count])
         {
             //TODO change this
//             [self InsertEmptyTable];
             
             [self.tableView reloadData];
         }
         else
             [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
     }
     else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
 }



// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}














-(BOOL)deleteSingleMessageFromDynamoDB:(NSDictionary*)notification
{
    NSString *hashKey  = notification[USERNAME];
    NSString *rangeKey = notification[FILEPATH];
    
    NSMutableDictionary *attributeDictionary      = [NSMutableDictionary dictionary];
    attributeDictionary[NOTIFICATION_HASH_KEY]  = [[DynamoDBAttributeValue alloc] initWithS:hashKey];
    attributeDictionary[NOTIFICATION_RANGE_KEY] = [[DynamoDBAttributeValue alloc] initWithS:rangeKey];
    
    DynamoDBDeleteItemRequest * dynamoDBDeleteRequest = [[DynamoDBDeleteItemRequest alloc] initWithTableName:NOTIFICATION_TABLE
                                                                                                      andKey:attributeDictionary];
 
    
    [self.spinningWheel startAnimating];
    
    [[QPNetworkActivity sharedInstance] increaseActivity];
    DynamoDBDeleteItemResponse * dynamoDBDeleteResponse = [[AmazonClientManager ddb] deleteItem:dynamoDBDeleteRequest];
    [[QPNetworkActivity sharedInstance] decreaseActivity];
    
    [self.spinningWheel stopAnimating];
    
    if (dynamoDBDeleteResponse.error)
    {
        NSLog(@"deleteSingleMessageFromDynamoDB Error: %@", dynamoDBDeleteResponse.error);
        return NO;
    }
    return YES;
}






- (IBAction)clearAllNotifications:(UIBarButtonItem *)sender
{
    NSLog(@"clearAllNotifications start");

    if (self.notificationSegmentControl.selectedSegmentIndex == NOTIFICATIONS_SEGMENT_CONTROL)
    {
        
        if (![self.notifications count])
            return;
        
        [self.spinningWheel startAnimating];

        
        NSMutableArray *itemsFailedToDelete = [self clearNotificationsTable:self.notifications];
        NSLog(@"clearNotificationsTable done");

        NSMutableArray *indexesToDelete     = [NSMutableArray array];
        
        NSMutableArray *notificationsToDelete = [NSMutableArray array];
        
        int count = (int)[self.notifications count];

        if (![itemsFailedToDelete count])
        {
            NSLog(@"itemsFailedToDelete is empty");

            [self.notifications removeAllObjects];
            NSLog(@"notifications removeAllObjects");

            for (int i = 0; i < count; i++)
            {
                NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
                [indexesToDelete addObject:path];
            }

            NSLog(@"itemsFailedToDelete is empty, deleteIndexPaths 1");

            [self deleteIndexPaths:indexesToDelete withRowAnimation:UITableViewRowAnimationTop];
            NSLog(@"itemsFailedToDelete is empty, deleteIndexPaths 2");

        }
        else
        {
            NSLog(@"itemsFailedToDelete is not empty");

            for (int i = 0; i < count; i++)
            {
                NSDictionary *notification  = self.notifications[i];

                BOOL delete = YES;
                for (NSDictionary *keys in itemsFailedToDelete)
                {
                    if ([keys[NOTIFICATION_HASH_KEY] isEqualToString:notification[USERNAME]] &&
                        [keys[NOTIFICATION_RANGE_KEY] isEqualToString:notification[FILEPATH]])
                    {
                        delete = NO;
                        break;
                    }
                }
                if (delete)
                {
                    [notificationsToDelete addObject:notification];
                    NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
                    [indexesToDelete addObject:path];
                }
            }
            
            [self.notifications removeObjectsInArray:notificationsToDelete];
            
            
            NSLog(@"self.notifications count %lu", (unsigned long)[self.notifications count]);
            
            [self deleteIndexPaths:indexesToDelete withRowAnimation:UITableViewRowAnimationTop];
            
//            [self.tableView deleteRowsAtIndexPaths:indexesToDelete withRowAnimation:UITableViewRowAnimationTop];
          
        }
        
        NSLog(@"addEmptyRowWithRowAnimation working" );

        if (![self.notifications count])
        {
            NSLog(@"addEmptyRowWithRowAnimation working 2" );

            [self addEmptyRowWithRowAnimation:UITableViewRowAnimationTop];
         
        }
    //        if ([self.notifications count])
    //            [self.tableView deleteRowsAtIndexPaths:indexesToDelete withRowAnimation:UITableViewRowAnimationTop];
    //        else
    //        {
    //            //TODO
    //            // [self insertEmptyRow];
    //            [self.tableView reloadData];
    //        }
    }
    
        
//    else
//    {
//        //TODO:
//        // This could be forgive all? After pressing button,
//        // UIAlertView would have to pop up asking if he's sure
//        
//    }
    [self.spinningWheel stopAnimating];
}






-(NSMutableArray*)clearNotificationsTable:(NSArray *)notifications
{
    
    NSMutableArray *notDeletedNotifications = [NSMutableArray array];
    
    NSError * error = nil;
    
    NSLog(@"deleteFromDynamoDBTheMessages count %lu", (unsigned long)[notifications count]);
    
    DynamoDBBatchWriteItemRequest *batchWriteRequest = [DynamoDBBatchWriteItemRequest new];
    NSMutableArray *writes = [NSMutableArray arrayWithCapacity:5];
    
    
    [batchWriteRequest setRequestItemsValue:writes forKey:NOTIFICATION_TABLE];
    
    
    int counter = 1;
    
    for (NSDictionary *notification in notifications)
    {
        
        
        NSString *hashKey  = notification[USERNAME];
        NSString *rangeKey = notification[FILEPATH];
    
        
        NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
        
        attributeDictionary[NOTIFICATION_HASH_KEY ] = [[DynamoDBAttributeValue alloc] initWithS:hashKey];
        attributeDictionary[NOTIFICATION_RANGE_KEY] = [[DynamoDBAttributeValue alloc] initWithS:rangeKey];
        
        
        DynamoDBDeleteRequest *deleteRequest = [DynamoDBDeleteRequest new];
        deleteRequest.key = attributeDictionary;
        
        DynamoDBWriteRequest *writeRequest = [DynamoDBWriteRequest new];
        writeRequest.deleteRequest = deleteRequest;
        
        [writes addObject:writeRequest];
        
        
        if (counter % 25 == 0 || [notifications count] == counter)
        {
            DynamoDBBatchWriteItemResponse *batchWriteResponse = nil;
            
            NSUInteger retry = 3;
            for(int i = 0; i < retry ; i++)
            {
                [[QPNetworkActivity sharedInstance] increaseActivity];
                batchWriteResponse = [[AmazonClientManager ddb] batchWriteItem:batchWriteRequest];
                [[QPNetworkActivity sharedInstance] decreaseActivity];
                
                if(!batchWriteResponse.error)
                {
                    if(batchWriteResponse.unprocessedItems == nil || [batchWriteResponse.unprocessedItems count] == 0
                       || i == retry)
                    {
                        break;
                    }
                    else
                    {
                        [NSThread sleepForTimeInterval:pow(2, i) * 2];
                        batchWriteRequest = [DynamoDBBatchWriteItemRequest new];
                        
                        for (NSString *key in batchWriteResponse.unprocessedItems)
                        {
                            [batchWriteRequest setRequestItemsValue:[batchWriteResponse.unprocessedItems objectForKey:key] forKey:key];
                        }
                    }
                }
                else
                {
                    error = batchWriteResponse.error;
                }
            }
            
            
            // Reverse engineering unprocessedItems.
            if (batchWriteResponse.unprocessedItems && [batchWriteResponse.unprocessedItems count] > 0)
            {
                NSLog(@"BatchWrite failed. Some items were not processed.");
                
                NSMutableArray *writes = [batchWriteResponse.unprocessedItems objectForKey:NOTIFICATION_TABLE];
                
                for (DynamoDBWriteRequest *writeRequest in writes)
                {
                    DynamoDBDeleteRequest *deleteRequest = writeRequest.deleteRequest;
                    
                    NSMutableDictionary *attributeDictionary = deleteRequest.key;
                    
                    NSString * hash = ((DynamoDBAttributeValue *)attributeDictionary[NOTIFICATION_HASH_KEY]).s;
                    NSString * range = ((DynamoDBAttributeValue *)attributeDictionary[NOTIFICATION_RANGE_KEY]).s;
                    
                    
                    NSDictionary *failedToDelete = @{NOTIFICATION_HASH_KEY: hash,
                                                     NOTIFICATION_RANGE_KEY:range};
                    
                    
                    [notDeletedNotifications addObject:failedToDelete];
                }
            }
            
            
            if([notifications count] != counter)
            {
                batchWriteRequest = [DynamoDBBatchWriteItemRequest new];
                [batchWriteRequest setRequestItemsValue:writes forKey:NOTIFICATION_TABLE];
        
            }
        }
        counter++;
    }
    return notDeletedNotifications;
}







@end
