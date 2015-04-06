//
//  QPContactsViewController.m
//  Quickpeck
//
//  Created by Hanny Aly on 6/27/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "QPContactsViewController.h"

#import "QPCoreDataManager.h"
#import "Constants.h"
#import "User+methods.h"

#import "KwikcyAWSRequest.h"

#define SENDING_LIMIT 3

@interface QPContactsViewController ()

/* contactsDictionary is a dictionary whose keys are the alphabet and the objects
 * are arrays of contacts
 */
@property (strong, nonatomic) NSMutableDictionary *contactsDictionary;
@property (strong, nonatomic) NSMutableArray      *alphabetKeys;
@property (strong, nonatomic) NSMutableArray      *contactsToSendTo;
@property (nonatomic)         BOOL                 useAccessoryMarks;

@end


@implementation QPContactsViewController

//@synthesize contactsToSendTo  = _contactsToSendTo;



-(BOOL)useAccessoryMarks
{
    return YES;
}


-(void)userPressesSearchButton
{
    [self performSegueWithIdentifier:@"Go to contact view" sender:self];
}

-(void)userPressedNextButton
{
    [self performSegueWithIdentifier:@"Go to sending view" sender:self];
}



//Delegate method
-(void)messageWasSent:(BOOL)sent withProgressBar:(UIProgressView *)progressBar;
{
    NSLog(@"sendSentMessageToDelegate       Sending Controller 2");
    [self.cameraDelegate messageWasSent:sent withProgressBar:progressBar];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Go to sending view"])
    {
        
        FYESendingViewController *sendingVC = (FYESendingViewController *)segue.destinationViewController;
        sendingVC.delegate = self;
    
        
        
        [segue.destinationViewController performSelector:@selector(setMediaInfo:) withObject:self.mediaInfo];
        [segue.destinationViewController performSelector:@selector(setContactsList:) withObject:self.contactsToSendTo];
        [segue.destinationViewController performSelector:@selector(setManagedObjectContext:) withObject:self.managedObjectContext];
        [segue.destinationViewController performSelector:@selector(setOperationQueue:) withObject:self.operationQueue];
    }
    else if ([segue.identifier isEqualToString:@"Go to contact view"])
    {
        //do nothing
    }
}


-(BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
//    self.clearsSelectionOnViewWillAppear = YES;
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.useAccessoryMarks)
    {
        UIBarButtonItem *searchButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(userPressesSearchButton)];
        
        
        UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(userPressedNextButton)];
        
        self.navigationItem.rightBarButtonItems = @[nextButton, searchButton];
        
        nextButton.enabled = NO;
        nextButton.tintColor = [UIColor grayColor];
    }
    else
    {
        UIBarButtonItem *searchButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(userPressesSearchButton)];
        self.navigationItem.rightBarButtonItem = searchButton;
    }
    
    
    
    if (self.managedObjectContext)
    {
        NSArray * allUsers = [User getAllOKContactsInManagedObjectContext:self.managedObjectContext];
        
        if (allUsers && [allUsers count])
        {
            NSMutableDictionary * contactsBook = [NSMutableDictionary new];
            
            for (User *user in allUsers)
            {
                NSString *firstName = user.username;
                
                NSString *firstLetterOfUser = [[firstName substringToIndex:1] uppercaseString];
                
                NSArray *keys = [contactsBook allKeys];
                
                if ([keys containsObject:firstLetterOfUser])
                {
                    NSMutableArray *listOfUsers = contactsBook[firstLetterOfUser];
                    
                    if (![listOfUsers containsObject:user])
                    {
                        [listOfUsers addObject:user];
                    }
                }
                else
                {
                    NSMutableArray *listOfUsers = [NSMutableArray array];
                    contactsBook[firstLetterOfUser] = listOfUsers;
                    [listOfUsers addObject:user];
                }
            }
            
            self.contactsDictionary = contactsBook;
            self.alphabetKeys = [[[self.contactsDictionary allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy];
        }
    }
    [self.tableView reloadData];
    [self checkToSeeIfNextButtonIsEnabled];
}





#pragma mark - Set up


-(NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext)
        _managedObjectContext = [QPCoreDataManager sharedInstance].managedObjectContext;
    return _managedObjectContext;
}



-(NSMutableArray *)contactsToSendTo
{
    if (!_contactsToSendTo)
        _contactsToSendTo = [[NSMutableArray alloc] init];
    return _contactsToSendTo;
}






#pragma mark - UITableViewDataSource Editable

//TODO: Need to change editing to network call of unfriending, or blocking

 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
     NSLog(@"commitEditingStyle");
     
     if (!self.useAccessoryMarks)
     {
         if (editingStyle == UITableViewCellEditingStyleDelete)
         {
             // Delete the row from the data source
             
             NSString * letter = self.alphabetKeys[indexPath.section];
             NSMutableArray * usersInSection = self.contactsDictionary[letter];
            
             User *user = usersInSection[indexPath.row];
             [User deleteUser:user inManagedObjectContext:self.managedObjectContext];
             
             [usersInSection removeObjectAtIndex:indexPath.row];

             
             // If users still in section, then just delete row
             if ([usersInSection count])
             {
                 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//                 [self.contactsDictionary[letter] = contactsOfASection;
             }
             
             // If section is empty, remove key, remove array and delete section
             else
             {
                 [self.alphabetKeys removeObject:letter];
                 [self.contactsDictionary removeObjectForKey:letter];
                 [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationMiddle];

             }
         }
         else if (editingStyle == UITableViewCellEditingStyleInsert)
         {
             // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
         }
     }
}


// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.useAccessoryMarks)
        return NO;
    else
        return YES;
}





-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//    return self.contactsInCoreDataIsEmpty ? 1 :[self.alphabetKeys count];
    return [self.alphabetKeys count] ? [self.alphabetKeys count] : 1;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
//    return self.contactsInCoreDataIsEmpty ? nil :[self.alphabetKeys[section] capitalizedString];
    return  nil;//[self.alphabetKeys count] ? [self.alphabetKeys[section] capitalizedString] : nil;
}


#pragma mark - Table view delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.alphabetKeys count] ? [self.contactsDictionary[self.alphabetKeys[section]] count] : 1;
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self.alphabetKeys count])
    {
        static NSString *noCellIdentifier = @"NoContactsCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:noCellIdentifier];
        
        if (!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:noCellIdentifier];

        cell.userInteractionEnabled = NO;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    static NSString *cellIdentifier       = @"ContactCell";
    static NSString *cellStatusIdentifier = @"ContactStatusCell";

    UITableViewCell *cell;
    
    User *user = self.contactsDictionary[self.alphabetKeys[indexPath.section]][indexPath.row];

    if ([user.status isEqualToString:STATUS_FRIEND] ||
        [user.status isEqualToString:FRIEND_ASYM_KNOWKINGLY] ||
        [user.status isEqualToString:FRIEND_ASYM_UNKNOWINGLY_KNOWINGLY])
    {
        NSLog(@"cellForRowAtIndexPath status friends");
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
        if (!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    else // status should be friends
    {
        NSLog(@"cellForRowAtIndexPath status not friends");

        cell = [tableView dequeueReusableCellWithIdentifier:cellStatusIdentifier];
        
        if (!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellStatusIdentifier];
        
        
        UILabel *status     = (UILabel *)[cell viewWithTag:5];
        status.textColor    = [UIColor redColor];
       
        if ([user.status isEqualToString:STATUS_PENDING])
            status.text = @"Pending";
        
        else
            NSLog(@"ERROR CELL STATUS MISSING FOR CELL");
        cell.userInteractionEnabled = NO;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UILabel     *username     = (UILabel *)[cell viewWithTag:1];
    UILabel     *realname     = (UILabel *)[cell viewWithTag:2];
    UIImageView *usersImage   = (UIImageView *)[cell viewWithTag:3];
    
    [Constants makeImageRound:usersImage];
    

    
    username.text = user.username;
    realname.text = user.realname;
    
    UIImage *personImage = [UIImage imageWithData:user.data];
    
    
    if (personImage)
        usersImage.image = personImage;
    else
    {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

            NSLog(@"network call for image");
            
            NSDictionary *userDictionary = [KwikcyAWSRequest getDetailsForUser:username.text];
            
            UIImage *userimage = userDictionary[IMAGE];
            
            if (userimage)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    usersImage.image = userimage;
                    
                    [User updateUserinfo:@{ USERNAME: user.username,
                                            ACTION  : InsertImage,
                                            DATA    : userDictionary[DATA]
                                           }
                  inManagedObjectContext:self.managedObjectContext];
                });
            }
        });
    }
    
    UIImageView *checkMark = (UIImageView *)[cell viewWithTag:4];
    checkMark.hidden = YES;
    
    for (NSDictionary *userInfo in self.contactsToSendTo)
    {
        if ([userInfo[USERNAME] isEqualToString:username.text])
        {
            checkMark.hidden = NO;
            break;
        }
    }
    return cell;
}



#pragma mark - Table view delegate

 
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.useAccessoryMarks)
    {
        UITableViewCell *pickerCell = [self.tableView cellForRowAtIndexPath:indexPath];

        NSString * username  = [((UILabel *)[pickerCell viewWithTag:1]).text copy];
        UIImage *image       = [((UIImageView *)[pickerCell viewWithTag:3]).image copy];


        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[USERNAME] = username;
        userInfo[IMAGE] = [NSNull null];

        if (image)
        {         
            userInfo[IMAGE] = image;
        }
        
        UIImageView *selectedIndicator = ((UIImageView *)[pickerCell viewWithTag:4]);

        
        
        if ([self.contactsToSendTo count] >= SENDING_LIMIT && selectedIndicator.isHidden)
        {
            [[Constants alertWithTitle:@"Limit reached"
                            andMessage:[NSString stringWithFormat:@"You can select up to %d people", SENDING_LIMIT]] show];
            return;
        }
        
        
        
        NSDictionary *user;
        for (user in self.contactsToSendTo)
        {
            if ([user[USERNAME] isEqualToString:username])
            {
                break;
            }
        }
        
        [UIView animateWithDuration:0.4
                         animations:^{
                             selectedIndicator.hidden = !selectedIndicator.isHidden;
                         }
                         completion:^(BOOL finished)
                         {
                             selectedIndicator.isHidden?[self.contactsToSendTo removeObject:user] : [self.contactsToSendTo addObject:userInfo];
                           
                            [self checkToSeeIfNextButtonIsEnabled];
                         }
         ];
    }
}

 
 
-(void)checkToSeeIfNextButtonIsEnabled
{
    UIBarButtonItem *nextButton = [self.navigationItem.rightBarButtonItems objectAtIndex:0];
 
    if ([self.contactsToSendTo count])
    {
        nextButton.enabled = YES;
        nextButton.tintColor = [UIColor redColor];
 
    }
    else
    {
        nextButton.enabled = NO;
        nextButton.tintColor = [UIColor grayColor];
    }
}




@end
