//
//  QPUserProfileVC.m
//  Quickpeck
//
//  Created by Hanny Aly on 1/30/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "QPUserProfileVC.h"
#import "Constants.h"
#import "KCProfileImageDownloader.h"


#import "KwikcyClientManager.h"
#import "QPProfileMethods.h"

#import "KCServerResponse.h"
#import "AmazonKeyChainWrapper.h"
#import "KCLargeImageVC.h"

#import "User+methods.h"
#import "QPCoreDataManager.h"

#import "QPNetworkActivity.h"

@interface QPUserProfileVC()


@property (weak, nonatomic) IBOutlet UIImageView *userProfilePhoto;

@property (weak, nonatomic) IBOutlet UILabel *realName;

@property (weak, nonatomic) IBOutlet UILabel *trustValue;
@property (weak, nonatomic) IBOutlet UILabel *avengeValue;
@property (weak, nonatomic) IBOutlet UILabel *betrayedValue;



@property (weak, nonatomic) IBOutlet UILabel *followingCount;
@property (weak, nonatomic) IBOutlet UILabel *followersCount;


@property (weak, nonatomic) IBOutlet UILabel *followPrivacySetting;
@property (weak, nonatomic) IBOutlet UILabel *addPrivacySetting;



@property (weak, nonatomic) IBOutlet UIButton *followButton;
@property (weak, nonatomic) IBOutlet UIButton *addContactButton;


@property (strong, nonatomic) UIActivityIndicatorView *spinningWheel;

@property (weak, nonatomic) IBOutlet UILabel *failedToGetInformationLabel;

@property (nonatomic, strong) UIImage *profileImage;

@property (atomic) BOOL doneLoadingPhoto;
@property (atomic) BOOL doneLoadingPoints;

@property (nonatomic, strong) NSManagedObjectContext    *managedObjectContext;

@property (nonatomic, strong) NSString *username;

@end



@implementation QPUserProfileVC


-(void)userTappedOnProfileImageView
{
    if (self.userProfilePhoto.image)
    {
        [self performSegueWithIdentifier:@"Show full profile" sender:self];
    }
}


-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.managedObjectContext = [QPCoreDataManager sharedInstance].managedObjectContext;

    self.username = self.userInfo[USERNAME];
    NSString *realname = self.userInfo[REALNAME];
    
    self.realName.text   = [realname length] ? realname : @"";
    self.realName.hidden = [self.realName.text length] ? NO:YES;
    
    
    self.followButton.hidden         = YES;
    self.followPrivacySetting.hidden = YES;
    self.addPrivacySetting.hidden    = YES;
    
    
    self.trustValue.text    = @"-";
    self.avengeValue.text   = @"-";
    self.betrayedValue.text = @"-";
    
    
    self.navigationItem.title = self.username;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]
                                         initWithTarget:self
                                         action:@selector(userTappedOnProfileImageView)];
    singleTap.numberOfTapsRequired = 1;
    
    
    [Constants makeImageRound:self.userProfilePhoto];
    
    
    self.userProfilePhoto.userInteractionEnabled = YES;
    [self.userProfilePhoto addGestureRecognizer:singleTap];
    
    


    
    if ([self.username isEqualToString:[AmazonKeyChainWrapper username]])
    {
        self.addContactButton.hidden = YES;
    }
    
    
    [self disableContactButton];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.profileImage)
        self.userProfilePhoto.image = self.profileImage;
    
    
    self.spinningWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinningWheel.color = [UIColor redColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.spinningWheel];
    self.spinningWheel.hidesWhenStopped = YES;
    [self.spinningWheel startAnimating];
    
    
    [self getMediumImageForUser:self.username];
    [self getDetailsForUser:self.username];
    
}


/*
 Gets user points, and info about allowing adds and followings
 
 */

-(void)getDetailsForUser:(NSString *)username;
{
    NSMutableDictionary *userDetails = [NSMutableDictionary new];
    
    NSMutableDictionary *variables = [NSMutableDictionary new];
    variables[COMMAND]      = GET_USER_INFO;
    variables[@"contact"]   = username;
    
    
    [KwikcyClientManager sendRequestWithParameters:variables
                             withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
     {
         NSLog(@"getDetailsForUser getDetailsForUser");

         if (error)
         {
             NSLog(@"Delegate getDetailsForUser, error");
         }
         else
         {
             KCServerResponse *serverResponse = (KCServerResponse *)response;
             
             if (received200Response)
             {
                 if (serverResponse.successful)
                 {
                     NSMutableDictionary *item  = ((KCServerResponse *)response).info;
                     
                     
                     NSString *numberOfSentPhotos               = item[NumberOfSentPhotos];
                     NSString *numberOfReceivedPhotos           = item[NumberOfReceivedPhotos];
                     
                     NSString *numberOfScreenShotsTaken         = item[NumberOfScreenShotsTaken];
                     NSString *numberOfScreenShotsTakenByOthers = item[NumberOfScreenShotsTakenByOthers];
                     NSString *numberOfRevengePointsUsed        = item[NumberOfRevengePointsUsed];
                     
                     
                     userDetails[NumberOfSentPhotos]                = numberOfSentPhotos;
                     userDetails[NumberOfReceivedPhotos]            = numberOfReceivedPhotos;
                     userDetails[NumberOfScreenShotsTaken]          = numberOfScreenShotsTaken;
                     userDetails[NumberOfScreenShotsTakenByOthers]  = numberOfScreenShotsTakenByOthers;
                     userDetails[NumberOfRevengePointsUsed]         = numberOfRevengePointsUsed;
                     
                     
                     NSString *status = item[STATUS];
                     
                     if ([status isEqual:[NSNull null]])
                     {
                         userDetails[ContactAllowed]      = item[ContactAllowed];
                         userDetails[IN_THE_ADDRESS_BOOK] = item[IN_THE_ADDRESS_BOOK];
                     }
                     else
                     {
                         userDetails[STATUS] = status;
                     }
                 }
                 else
                 {
                     NSLog(@"serverResponse was unsuccessful ! = %@", serverResponse.message);
                 }
             }
             else
             {
                 NSLog(@"serverResponse was unsuccessful!");
             }
         }
         
         [self receivedUserDetails:userDetails];
     }];
}





-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"Show full profile"])
    {
        NSString *profilePathfile = [NSString stringWithFormat:@"%@/%@", self.userInfo[USERNAME], LARGE_IMAGE ];
        
        ((KCLargeImageVC *) segue.destinationViewController).s3PathWay = profilePathfile;
    }
}





-(void)viewWillDisappear:(BOOL)animated
{
    if ([self.spinningWheel isAnimating])
        [self.spinningWheel stopAnimating];
        
    [super viewWillDisappear:animated];
}






-(void)receivedUserDetails:(NSDictionary *)userDetails
{
    self.doneLoadingPoints = YES;
    
    if (![userDetails count])
    {
        NSLog(@"receivedUserDetails:notificaiton = userinfo fail");
        self.failedToGetInformationLabel.hidden = NO;
        [self finish];
        return;
    }
    
    NSString *numberOfSentPhotos                = userDetails[NumberOfSentPhotos];
    NSString *numberOfReceivedPhotos            = userDetails[NumberOfReceivedPhotos];
    NSString *numberOfScreenShotsTaken          = userDetails[NumberOfScreenShotsTaken];
    NSString *numberOfScreenShotsTakenByOthers  = userDetails[NumberOfScreenShotsTakenByOthers];
    NSString *numberOfRevengePointsUsed         = userDetails[NumberOfRevengePointsUsed];

//    NSString *numberOfFollowers                 =  userInfo[NumberOfFollowers];
//    NSString *numberFollowing                   =  userInfo[NumberFollowing];
    
    
    NSString *status                            =  userDetails[STATUS];
    
    NSString *contactAllowed;
    BOOL      inTheAddressBook;
    
    if (!status)
    {
        contactAllowed    = userDetails[ContactAllowed];
        inTheAddressBook  = [userDetails[IN_THE_ADDRESS_BOOK] boolValue];
    }
    
    
    
    
    
    /*
     *  Options are "Add" or "Request Add"
     */
    
    if ([self.username isEqualToString:[AmazonKeyChainWrapper username]])
    {
        ;
    }
    
    else if (status)  // if  status = realtionship: friend, pending, denied, blocked
    {
        if ([status isEqualToString:STATUS_FRIEND] ||
            [status isEqualToString:FRIEND_ASYM_KNOWKINGLY])
        {
            [self disableContactButton];
            [self.addContactButton setTitle:@"Friends" forState:UIControlStateNormal];
            self.addPrivacySetting.hidden = YES;
    
            NSDictionary *userInfo = @{USERNAME: self.username,
                                       REALNAME: self.realName.text,
                                       DATA:     self.userInfo[DATA],
                                       };

            if (self.managedObjectContext)
            {
                NSLog(@"please insert user in core data");
                [self.managedObjectContext performBlock:^{
                    [User insertUser:userInfo inManagedObjectContext:self.managedObjectContext];
                }];
            }
        }
        
        
        
        /*
        NSDictionary *userInfo = @{USERNAME: self.profileDelegate.username,
                                   REALNAME: self.realName.text,
                                   DATA: UIImageJPEGRepresentation(self.profileImage, 1)
                                   };
        if (self.managedObjectContext)
        {
            [self.managedObjectContext performBlock:^{
                [User insertUser:userInfo inManagedObjectContext:self.managedObjectContext];
            }];
        }
         
         */
        
        
        
        
        else if ([status isEqualToString:FRIEND_ASYM_UNKNOWINGLY] ||
                 [status isEqualToString:STATUS_REQUESTEE_PENDING] ||
                 [status isEqualToString:STATUS_DENIER] ||
                 [status isEqualToString:STATUS_BLOCKER] )
        {
            NSLog(@"here posted FRIEND_ASYM_UNKNOWINGLY ");

            [self.addContactButton setTitle:@"Add User" forState:UIControlStateNormal];
            [self enableContactButton];
            self.addPrivacySetting.hidden = YES;
        }
        
        // status returns their relationship with us.
        else if ([status isEqualToString:STATUS_REQUESTER_PENDING] )
        {
            NSLog(@"here posted STATUS_REQUESTER_PENDING ");
            [self disableContactButton];
            [self.addContactButton setTitle:@"Pending" forState:UIControlStateNormal];
            self.addPrivacySetting.hidden = YES;
        }
        
        else if ([status isEqualToString:STATUS_DENIED] )
        {
            NSLog(@"here posted STATUS_DENIED ");
            [self disableContactButton];
            [self.addContactButton setTitle:@"Denied" forState:UIControlStateNormal];
            self.addPrivacySetting.hidden = YES;
        }
        else if ([status isEqualToString:STATUS_BLOCKED] )
        {
            NSLog(@"here posted STATUS_BLOCKED ");
            [self disableContactButton];
            [self.addContactButton setTitle:@"Blocked" forState:UIControlStateNormal];
            self.addContactButton.hidden = YES;
        }
    }
    
    
    
    
    /*
     
     After adding user in search, update contact list in ViewDidLoad Viewwill appear
     
     If request is pending show it in contacts. Don't allow it to be selectable
     
     */
    
    
    
    
    // anyone can add user
    else if ([contactAllowed isEqualToString:USER_ADD_STATUS_PUBLIC])
    {
        NSLog(@"here posted USER_ADD_STATUS_PUBLIC ");
        [self enableContactButton];
        [self.addContactButton setTitle:@"Add User" forState:UIControlStateNormal];
        self.addPrivacySetting.hidden = YES;
    }
    
    // yes, but needs to be accepted
    else if ([contactAllowed isEqualToString:USER_ADD_STATUS_PRIVATE] )
    {
        NSLog(@"here posted USER_ADD_STATUS_PRIVATE ");

        [self enableContactButton];
        [self.addContactButton setTitle:@"Request Add" forState:UIControlStateNormal];
        self.addPrivacySetting.hidden = YES;
    }
    
    else  // USER_ADD_STATUS_PRIVATE_ALLOW_ADDRESS_BOOK
    {
        NSLog(@"here posted inTheAddressBook ");

        if (inTheAddressBook)
        {
            [self enableContactButton];
            [self.addContactButton setTitle:@"Add" forState:UIControlStateNormal];
            self.addPrivacySetting.hidden = YES;
        }
        else
        {
            [self enableContactButton];
            [self.addContactButton setTitle:@"Request Add" forState:UIControlStateNormal];
            self.addPrivacySetting.hidden = YES;
        }
    }
    
    
    
    
    // Evaluate the trust value
    
    NSUInteger receivedPhotos  = [numberOfReceivedPhotos integerValue];
    if (receivedPhotos)
    {
        float screenshotsTakenByMe = [numberOfScreenShotsTaken floatValue];
        
        
        float trust = (receivedPhotos - screenshotsTakenByMe) / receivedPhotos  * 100 ;
        int trustInt  = [QPProfileMethods getPercentage:trust];
        
        self.trustValue.text = [NSString stringWithFormat:@"%d%%", trustInt];
    }
    else
        self.trustValue.text = @"-";


    
    
    
    // Evaluate the avenge value

    NSUInteger revengePointsIHave = [numberOfScreenShotsTakenByOthers integerValue];
 
    if (revengePointsIHave)
    {
        float revengePointsUsed = [numberOfRevengePointsUsed floatValue];
    
    
        float avenge = (revengePointsUsed / revengePointsIHave) * 100 ;
        int avengeInt  = [QPProfileMethods getPercentage:avenge];
        
        self.avengeValue.text = [NSString stringWithFormat:@"%d%%", avengeInt];
    }
    else
         self.avengeValue.text = @"-";
        
    
    
    // Evaluate the betray value

    float sentPhotos = [numberOfSentPhotos floatValue];
    if (sentPhotos)
    {
        NSUInteger screenShotsTakenByOthers = [numberOfScreenShotsTakenByOthers integerValue];
        
        float betray = screenShotsTakenByOthers / sentPhotos * 100;
        int betrayInt  = [QPProfileMethods getPercentage:betray];
        
        self.betrayedValue.text = [NSString stringWithFormat:@"%d%%", betrayInt];
    }
    else
         self.betrayedValue.text = @"-";

    [self finish];
}





-(void)getMediumImageForUser:(NSString *)username
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        NSString *profilePathfile = [NSString stringWithFormat:@"%@/%@", username, MEDIUM_IMAGE ];
        // Puts the file as an object in the bucket.
        S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc] initWithKey:profilePathfile
                                                                            withBucket:KWIKCY_PROFILE_BUCKET];
        
        [[QPNetworkActivity sharedInstance] increaseActivity];
        S3GetObjectResponse *response = [[AmazonClientManager s3] getObject:getObjectRequest];
        [[QPNetworkActivity sharedInstance] decreaseActivity];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.doneLoadingPhoto = YES;
            
            if (!response.error)
            {
                NSData *data = response.body;
                
                if (data)
                {
                    UIImage *image = [UIImage imageWithData:data];
                    
                    self.profileImage = image;
                    self.userProfilePhoto.image = image;
                }
            }
            [self finish];
        });
    });
}




-(void)finish
{
    if (self.doneLoadingPoints && self.doneLoadingPhoto)
    {
        if ([self.spinningWheel isAnimating])
            [self.spinningWheel stopAnimating];
    }
}



- (IBAction)followUser
{
    return;
    
    NSMutableDictionary *variables = [NSMutableDictionary new];
    
    //Setup buttons
    NSString *followingAllowed = self.userInfo[FollowingAllowed];
    
    
    // Anyone can follow us/ Anyone can follow user
    if(followingAllowed == nil || [followingAllowed isEqualToString:@"yes"] || [followingAllowed isEqualToString:@"private"])
    {
        variables[COMMAND]        = @"followRequest";
        variables[PersonToFollow] = self.username;
    }
    // Disable follow button, no one can even request to follow
    else if([followingAllowed isEqualToString:@"allDenied"])
    {
        [[Constants alertWithTitle:@"Uh oh"
                        andMessage:[NSString stringWithFormat:@"%@ doesn't want anymore followers",
                                    self.username]] show];
        return;
    }

    [KwikcyClientManager sendRequestWithParameters:variables
                             withCompletionHandler:^(BOOL success, Response *response, NSError *error) {
                                 
         if (!error)
         {
             if (success)
             {
                                 
             }
         }
    }];
}




-(void)enableContactButton
{
    self.addContactButton.userInteractionEnabled = YES;
    self.addContactButton.alpha = 1.0;
}

-(void)disableContactButton
{
    self.addContactButton.userInteractionEnabled = NO;
    self.addContactButton.alpha = 0.5;
}







/*
 
        After adding user in search, update contact list in ViewDidLoad Viewwill appear
 
        If request is pending show it in contacts. Don't allow it to be selectable
 
 */




/*

 person.status = "friends", "pending", "denied", "blocked"
 
 
 */


//Send to server to add user in my contacts.

#define CONTACT @"contact"

- (IBAction)addUser
{
    [self disableContactButton];
    
    NSMutableDictionary *variables = [NSMutableDictionary new];
    
    variables[COMMAND]      = REQUEST_TO_ADD_CONTACT;
    variables[CONTACT]      = self.username;
    
    
    [KwikcyClientManager sendRequestWithParameters:variables
                             withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
     {
         if (error)
         {
             [self enableContactButton];
             [[Constants alertWithTitle:@"Connection Error"
                             andMessage:@"Could not send request due to an internet connection error"] show];
         }
         // No connection error
         else
         {
             KCServerResponse *serverResponse = (KCServerResponse *)response;
             
             if (received200Response)
             {
                 if (serverResponse.successful)
                 {
                     
                     
                     NSDictionary *info = serverResponse.info;
                     
                     NSString *contactAllowed = info[ContactAllowed];
                     NSString *message        = info[MESSAGE];
                    
                     [self.addContactButton setTitle:contactAllowed forState:UIControlStateNormal];

                     //Add user into core data contact list
                    
                     
                     NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                     
                     userInfo[USERNAME] = self.username;
                     userInfo[REALNAME] = self.realName.text;
                     userInfo[DATA]   = UIImageJPEGRepresentation(self.profileImage, 1);
                
                     

                     if([contactAllowed isEqualToString:@"Already friends"] ||
                        [contactAllowed isEqualToString:@"Added"])
                     {
                         userInfo[STATUS] = STATUS_FRIEND;
                     }
                     
                     else if([contactAllowed isEqualToString:@"Sent"])
                     {
                         // DO NOT Add as friend
                         userInfo[STATUS] = PENDING;
                         [[Constants alertWithTitle:nil
                                         andMessage:response.message] show];
                     }
                     
                     if (self.managedObjectContext)
                     {
                         [self.managedObjectContext performBlock:^{
                             [User insertUser:userInfo inManagedObjectContext:self.managedObjectContext];
                         }];
                     }
                 }
                 else
                 {
                     NSString *message = response.message;
                     
                     if ([message isEqualToString:@"Request pending"])
                     {
                         [self.addContactButton setTitle:message forState:UIControlStateNormal];
                     }
                     
                     else if ([message isEqualToString:@"User has denied your request"])
                     {
                         [[Constants alertWithTitle:nil andMessage:response.message] show];
                     }
                     
                     else if ([message isEqualToString:@"User has blocked you"])
                     {
                         [[Constants alertWithTitle:nil andMessage:response.message] show];
                     }
                 }
             }
             else
                 [self enableContactButton];
         }
     }];
}



/*
 
 After adding user in search, update contact list in ViewDidLoad Viewwill appear
 
 If request is pending show it in contacts. Don't allow it to be selectable
 
 */



@end




