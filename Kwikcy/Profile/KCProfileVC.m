//
//  KCProfileVC.m
//  Quickpeck
//
//  Created by Hanny Aly on 4/2/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//
#import "User+methods.h"
#import "QPCoreDataManager.h"
#import "Constants.h"

#import "BlockActionSheet.h"
#import "MBProgressHUD.h"
#import "QPNetworkActivity.h"

#import <AWSDynamoDB/AWSDynamoDB.h>
#import "AmazonKeyChainWrapper.h"
#import "AmazonClientManager.h"
#import "QPProfileMethods.h"


#import "KCProfileVC.h"

#import "QPProfileMethods.h"

#import "KwikcyClientManager.h"
#import "KCServerResponse.h"

#import "KCLargeImageVC.h"

@interface KCProfileVC ()

@property (nonatomic, strong) NSString *username;
@property (weak, nonatomic) IBOutlet UILabel *realname;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;

@property (strong, nonatomic) MBProgressHUD *hud;

@property (weak, nonatomic) IBOutlet UILabel *followingCount;
@property (weak, nonatomic) IBOutlet UILabel *followersCount;

@property (weak, nonatomic) IBOutlet UILabel *trustValue;
@property (weak, nonatomic) IBOutlet UILabel *betrayedValue;
@property (weak, nonatomic) IBOutlet UILabel *avengeValue;

@property (nonatomic) NSUInteger numberOfReceivedPhotos;
@property (nonatomic) NSUInteger numberOfScreenShotsTakenByMe;
@property (nonatomic) NSUInteger numberOfScreenShotsTakenByOthers;
@property (nonatomic) NSUInteger numberOfSentPhotos;
@property (nonatomic) NSUInteger numberOfRevengePointsUsed;





@property (strong, nonatomic) UIActivityIndicatorView *spinningWheel;

@property (atomic) BOOL doneLoadingPhoto;
@property (atomic) BOOL doneLoadingPoints;

@end


@implementation KCProfileVC



-(UIActivityIndicatorView *)spinningWheel
{
    if (!_spinningWheel)
    {
        _spinningWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _spinningWheel.color = [UIColor redColor];
        _spinningWheel.hidesWhenStopped = YES;
    }
    return _spinningWheel;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.spinningWheel];

    
    self.managedObjectContext = [QPCoreDataManager sharedInstance].managedObjectContext;
  
 
    self.username = [AmazonKeyChainWrapper username];
    [self.navigationItem setTitle:self.username];
    
    self.realname.text = @"";

 
    
    [Constants makeImageRound:self.profileImageView];
    
    
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]
                                         initWithTarget:self
                                         action:@selector(userTappedOnProfileImageView)];
    singleTap.numberOfTapsRequired = 1;
    self.profileImageView.userInteractionEnabled = YES;
    [self.profileImageView addGestureRecognizer:singleTap];
  
    
    
    self.followersCount.hidden = YES;
    self.followingCount.hidden = YES;
    

    self.trustValue.text    = @"-";
    self.betrayedValue.text = @"-";
    self.avengeValue.text   = @"-";
}




-(void)viewWillDisappear:(BOOL)animated
{
    if ([self.spinningWheel isAnimating])
        [self.spinningWheel stopAnimating];
    
    [super viewWillDisappear:animated];
}



-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    self.navigationController.navigationBarHidden = NO;



    [self.spinningWheel startAnimating];
    
    
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
       
        UIImage *image = [self getMediumImage];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.doneLoadingPhoto = YES;
            [self finish];

            self.profileImageView.image = image;
        });
    });
    
    
    
    
    if (self.managedObjectContext)
    {
        [self.managedObjectContext performBlockAndWait:^{
            
            User *mySelf = [User getUserForUsername:[AmazonKeyChainWrapper username] inManagedContext:self.managedObjectContext];
            
            if (mySelf)
            {
                if (mySelf.realname)
                    self.realname.text = mySelf.realname;
            }
         }];
    }
    
    
    // Get my own data from server
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        
        NSMutableDictionary *hashKey = [NSMutableDictionary dictionary];
        hashKey[USERNAME] = [[DynamoDBAttributeValue alloc] initWithS:self.username];
        
        DynamoDBGetItemRequest *request  = [[DynamoDBGetItemRequest alloc] init];
        request.tableName = USER_POINTS_TABLE;
        request.key = hashKey;
        
        [[QPNetworkActivity sharedInstance] increaseActivity];
        DynamoDBGetItemResponse *getItemResponse = [[AmazonClientManager ddb] getItem:request];
        [[QPNetworkActivity sharedInstance] decreaseActivity];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            self.doneLoadingPoints = YES;
            [self finish];
            
            if (!getItemResponse.error)
            {
                NSMutableDictionary *item = getItemResponse.item;
                
                if (item)
                {
                    self.numberOfSentPhotos             = [((DynamoDBAttributeValue*)item[NumberOfSentPhotos]).n intValue];
                    self.numberOfReceivedPhotos         = [((DynamoDBAttributeValue*)item[NumberOfReceivedPhotos]).n intValue] ;
                    
                    self.numberOfScreenShotsTakenByMe   = [((DynamoDBAttributeValue*)item[NumberOfScreenShotsTaken]).n intValue];
                    self.numberOfScreenShotsTakenByOthers = [((DynamoDBAttributeValue*)item[NumberOfScreenShotsTakenByOthers]).n intValue];
                    self.numberOfRevengePointsUsed      = [((DynamoDBAttributeValue*)item[NumberOfRevengePointsUsed]).n intValue];
                    
                    
                    
                    
                    
                    // Evaluate the honest value
                    
                    if (self.numberOfReceivedPhotos)
                    {
                        float trust = ((float)(self.numberOfReceivedPhotos - self.numberOfScreenShotsTakenByMe)) / self.numberOfReceivedPhotos  * 100 ;
                        int roundedOffHonestValue = [QPProfileMethods getPercentage:trust];
                        
                        self.trustValue.text = [NSString stringWithFormat:@"%d%%", roundedOffHonestValue];
                    }
                   
                    
                    
                    
                    
                
                    
                    // Evaluate the revenge value
                    
                    if (self.numberOfScreenShotsTakenByOthers)
                    {
                        float avenge                =  ((float)self.numberOfRevengePointsUsed) / self.numberOfScreenShotsTakenByOthers * 100 ;
                        int roundedOffRevengeValue  = [QPProfileMethods getPercentage:avenge];
                        
                        self.avengeValue.text = [NSString stringWithFormat:@"%d%%", roundedOffRevengeValue];
                    }
                
                    
                    
                    
                    // Evaluate the betray value
                    
                    if (self.numberOfSentPhotos)
                    {
                        float betray  = ((float)self.numberOfScreenShotsTakenByOthers) / self.numberOfSentPhotos * 100;
                        int roundedOffBetrayValue = [QPProfileMethods getPercentage:betray];
                        
                        self.betrayedValue.text = [NSString stringWithFormat:@"%d%%", roundedOffBetrayValue];
                    }
                }
            }
        });
    });
}






-(void)showHUDWithMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hud = [MBProgressHUD getAndShowUniversalHUD:self.view withText:message animated:YES];
    });
}

-(void)showHUDWithMessageSynch:(NSString *)message
{
    self.hud = [MBProgressHUD getAndShowUniversalHUD:self.view withText:message animated:YES];
}

-(void)hideHUDSynch
{
    [self.hud hideProgressHUD];
}

-(void)hideHUDAsynch
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.hud hideProgressHUD];
    });
}




- (IBAction)userDidSelectPointsButtonWithTitle:(UIButton *)sender
{
    if ([sender.currentTitle isEqualToString:@"Honest"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Honest Statistics"
                                                        message:[NSString stringWithFormat:@"Photos received: %lu\nScreenshots taken: %lu",(unsigned long)self.numberOfReceivedPhotos, (unsigned long)self.numberOfScreenShotsTakenByMe ]
                                                       delegate:nil
                                              cancelButtonTitle:@"Done"
                                              otherButtonTitles: nil];
        
        [alert show];
    }
    else if ([sender.currentTitle isEqualToString:@"Betrayed"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Betrayed Statistics"
                                                        message:[NSString stringWithFormat:@"Screenshots taken by others: %lu\nRevenge points used: %lu",(unsigned long)self.numberOfScreenShotsTakenByOthers, (unsigned long)self.numberOfRevengePointsUsed ]
                                                       delegate:nil
                                              cancelButtonTitle:@"Done"
                                              otherButtonTitles: nil];
        
        [alert show];
    }
    else if ([sender.currentTitle isEqualToString:@"Revenge"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Revenge Statistics"
                                                        message:[NSString stringWithFormat:@"Photos sents: %lu\nScreenshots taken by others: %lu",(unsigned long)self.numberOfSentPhotos, (unsigned long)self.numberOfScreenShotsTakenByOthers ]
                                                       delegate:nil
                                              cancelButtonTitle:@"Done"
                                              otherButtonTitles: nil];
        
        [alert show];
    }
}





-(UIImage *)getMediumImage
{
    NSString *profilePathfile = [NSString stringWithFormat:@"%@/%@", self.username, MEDIUM_IMAGE ];

    // Puts the file as an object in the bucket.
    S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc] initWithKey:profilePathfile
                                                                        withBucket:KWIKCY_PROFILE_BUCKET];
    
    [[QPNetworkActivity sharedInstance] increaseActivity];
    S3GetObjectResponse *response = [[AmazonClientManager s3] getObject:getObjectRequest];
    [[QPNetworkActivity sharedInstance] decreaseActivity];

    UIImage *image;

    if (!response.error)
    {
        NSData *data = response.body;
        
        if (data)
            image = [UIImage imageWithData:data];
    }
    return image;
}














-(void)finish
{
    if (self.doneLoadingPoints && self.doneLoadingPhoto)
    {
        if ([self.spinningWheel isAnimating])
        {
            [self.spinningWheel stopAnimating];
        }
    }
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqual:@"Show Camera"])
    {
        DLCImagePickerController *cameraController = (DLCImagePickerController *)segue.destinationViewController;
        cameraController.profileDelegate = self;
  
    }
    else if ([segue.identifier isEqual:@"Show Edit Screen"])
    {
    }
    else if ([segue.identifier isEqual:@"Show Options Screen"])
    {
    }
    else if([segue.identifier isEqualToString:@"Show full profile"])
    {
        NSString *profilePathfile = [NSString stringWithFormat:@"%@/%@", self.username, LARGE_IMAGE ];
        
        ((KCLargeImageVC *) segue.destinationViewController).s3PathWay = profilePathfile;
    }
}




- (void)userTappedOnProfileImageView
{
    BlockActionSheet *alert = [BlockActionSheet sheetWithTitle:@"Change Profile Picture"];
    
    
    
    [alert addButtonWithTitle:@"Take Photo" block:^{
        [self performSegueWithIdentifier:@"Show Camera" sender:nil];
    }];
    
    
    [alert addButtonWithTitle:@"Choose from library" block:^{
        // Pop up  library
        
        UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePickerController.delegate = self;
        imagePickerController.allowsEditing = NO;
        [self presentViewController:imagePickerController animated:YES completion:NULL];
    }];
    
    
    [alert addButtonWithTitle:@"View full profile image" block:^{
        [self performSegueWithIdentifier:@"Show full profile" sender:self];
    }];
    
    
    [alert setCancelButtonWithTitle:@"Cancel" block:^{}];
    [alert addButtonWithTitle:@"" block:^{}];
    [alert addButtonWithTitle:@"" block:^{}];
    
    [alert showInView:self.view];
}



// Selected photo from libary
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"KCProfile imagePickerController: didFinishPickingMediaWithInfo:");

    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self showHUDWithMessage:@"Saving"];
    });

    [self dismissViewControllerAnimated:YES completion:^{
        
        UIImage* outputImage = [info objectForKey:UIImagePickerControllerEditedImage];
        if (!outputImage)
            outputImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        
        NSMutableDictionary *parameters = [NSMutableDictionary new];
        
        parameters[COMMAND]   = UPDATE_PROFILE_PHOTO;
        parameters[ACTION]    = ADD;
        parameters[MEDIATYPE] = IMAGE;
        parameters[IMAGE]     = [UIImageJPEGRepresentation(outputImage, 1.0) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        
        [KwikcyClientManager sendRequestWithParameters:parameters
                                     withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
         {
             [self hideHUDSynch];
             
             
             if (error)
             {
                 [[Constants alertWithTitle:@"Connection Error"
                                 andMessage:@"Could not send request due to a connection error"] show];
             }
             else
             {
                 KCServerResponse *serverResponse = (KCServerResponse *)response;
                 
                 if (received200Response)
                 {
                     if (serverResponse.successful)
                     {
                         UIImage *image = [self getMediumImage];
                         self.doneLoadingPhoto = YES;
                         [self finish];

                         self.profileImageView.image = image;

                     }
                     else
                     {
                         [[Constants alertWithTitle:@"Error" andMessage:serverResponse.message] show];
                     }
                 }
             }
         }];
    }];

}



// Library did cancel
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



+(NSString *)encodeToBase64String:(NSData *)data
{
    return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}







@end
