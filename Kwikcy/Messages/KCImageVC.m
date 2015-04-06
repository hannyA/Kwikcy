//
//  KCImageVC.m
//  Kwikcy
//
//  Created by Hanny Aly on 8/22/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCImageVC.h"
#import "Constants.h"


#import <AWSS3/AWSS3.h>
#import "QPNetworkActivity.h"
#import "KwikcyClientManager.h"
#import "KCServerRequest.h"
#import "KCServerResponse.h"
#import "AmazonKeyChainWrapper.h"

#import "KCMailboxCoreDataMethods.h"

@interface KCImageVC ()<AmazonServiceRequestDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *labelCountBackground;
@property (weak, nonatomic) IBOutlet UILabel *labelCount;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinningWheel;

@property (nonatomic, getter = isReceivedMessageSet) BOOL receivedMessageIsSet;

@property (nonatomic, getter = hasViewAppeared) BOOL viewDidAppear;

@end

@implementation KCImageVC




-(void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"kcImage: viewDidLoad");
    
    [Constants makeImageRound:self.labelCountBackground];
    
    self.spinningWheel.hidden = NO;

    self.labelCount.hidden = YES;
    self.labelCountBackground.hidden = YES;
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"kcImage: viewdidAppear");
    
    self.viewDidAppear = YES;

    [self popControllerIfTimeIsUp];
}


/*
    The process:
    
    View did load
    View will appear
 
    Count is set to 0
 
 
 
    ViewDidLoad
 
 */


-(void)popControllerIfTimeIsUp
{
    NSLog(@"kcImage: popControllerIfTimeIsUp");
    if ([self.count isEqualToString:@"0"])
    {
        NSLog(@"kcImage: popControllerIfTimeIsUp is 0");
        if (self.hasViewAppeared)
        {
            NSLog(@"kcImage: popViewControllerAnimated normal");
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            NSLog(@"kcImage: isBeingPresented");
            [self performSelector:@selector(popViewControllerAfterDelay)
                       withObject:nil
                       afterDelay:0.5];
        }
    }
}


-(void)popViewControllerAfterDelay
{
    [self.navigationController popViewControllerAnimated:YES];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"kcImage: viewWillAppear");

    
    //TODO: Or we can remove this and add it to setupImage
    
    /*
    if ([[self.receivedMessage getMessage].screenshot_safe boolValue])
    {
        NSLog(@"Screen shot allowed");
        return;
    }
    
     */
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenShotTaken:)
                                                 name:UIApplicationUserDidTakeScreenshotNotification
                                               object:nil];
    
    
    
    self.tabBarController.tabBar.hidden = YES;
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    
    // shadow image is line under navigation bar
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    
    
    
    [self setupImage];

    
    
    //    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
    //    self.navigationController.navigationBar.trans = [UIColor clearColor];
    
    //    self.navigationController.navigationBar.hidden = YES;
    //    self.navigationController.navigationBar.translucent
    //
    //    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    //    [self.navigationController.navigationController.navigationBar]
    
}




-(void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
    
    

    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefaultPrompt];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = NO;
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationUserDidTakeScreenshotNotification
                                                  object:nil];
    [super viewWillDisappear:animated];
}






-(void)setCount:(NSString *)count
{
    _count = count;
    self.labelCount.text = _count;
    [self popControllerIfTimeIsUp];
}


-(void)setupImage
{
    if (self.isReceivedMessageSet)
    {
        [self.spinningWheel stopAnimating];
    
        if (self.receivedMessage.image)
        {
            self.labelCount.hidden = NO;
            self.labelCountBackground.hidden = NO;
            
            self.imageView.image = self.receivedMessage.image;

            self.labelCount.text = [self.receivedMessage.timeLeft stringValue];
            
        }
        //Show error image
        else
        {
            self.imageView.image = [UIImage imageNamed:@"X-mark-hollow-blue"];
            [self performSelector:@selector(popControllerForNoImage) withObject:nil afterDelay:2.0];
        }

    }
}

-(void)setReceivedMessage:(ReceivedMessageImage *)receivedMessage
{
    NSLog(@"KCImageVC: setReceivedMessage");
    _receivedMessage = receivedMessage;

    self.receivedMessageIsSet = YES;

    [self setupImage];
}


-(void)animateSpinningWheelForFirstTime
{
    [self.spinningWheel startAnimating];
}




-(void)popControllerForNoImage
{
    [self.navigationController popViewControllerAnimated:YES];
}








#pragma mark - AmazonServiceRequestDelegate Implementations


-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"didReceiveResponse");
    
}

-(void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data
{
    NSLog(@"didReceiveData");

}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    NSLog(@"didCompleteWithResponse");

}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError");
    
    
}







- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}










//The OS will postNotification.

-(void)screenShotTaken:(NSNotification*)info
{
    NSLog(@"screenShotTaken");
    

    if ([[self.receivedMessage getMessage].screenshot_safe boolValue])
    {
        NSLog(@"Screen shot allowed");
        return;
    }
    NSLog(@"Screen shot NOT allowed");

    
    //Get current index of image of which screen shot was taken

    NSString *betrayed = [self.receivedMessage getPersonFrom];
    NSString *filepath = [self.receivedMessage getFilePath];
    
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    
    parameters[RECEIVER]  = betrayed;
    parameters[FILEPATH]  = filepath;
    
    
    parameters[COMMAND] = SEND_NOTIFICATON;
    
    
    [KwikcyClientManager sendRequestWithParameters:parameters
                             withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
     {
         if (!error)
         {
             NSLog(@"screenShotTaken no error");
             KCServerResponse *serverResponse = (KCServerResponse *)response;
             
             if (received200Response)
             {
                 if (!serverResponse.successful)
                 {
                     //TODO: Add this for core data
                     //Store in core data the sending failure and send another time
                     NSLog(@"serverResponse was unsuccessful! for notify screenshot");
                     NSDictionary * dic = @{
                                            USERNAME:[AmazonKeyChainWrapper username],
                                            RECEIVER: betrayed,
                                            FILEPATH:filepath
                                            };
                     [self addScreenShotInfoToCoreData:dic];
                 }
             }
         }
         else
         {
             //TODO: Add this for core data
             NSLog(@"screenShotTaken error");
             //Store in core data the sending failure and send another time
             NSDictionary * dic = @{USERNAME:[AmazonKeyChainWrapper username],
                                    RECEIVER: betrayed,
                                    FILEPATH:filepath};
             [self addScreenShotInfoToCoreData:dic];
         }
     }];
}



-(void)addScreenShotInfoToCoreData:(NSDictionary *)dic
{
    [KCMailboxCoreDataMethods  addScreenShotInfoToCoreData:dic];
}


@end
