//
//  KCLargeImageVC.m
//  Kwikcy
//
//  Created by Hanny Aly on 8/2/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCLargeImageVC.h"
#import <AWSS3/AWSS3.h>
#import "Constants.h"
#import "QPNetworkActivity.h"
#import "AmazonClientManager.h"

@interface KCLargeImageVC ()
@property (weak, nonatomic) IBOutlet UIImageView *largeProfileImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinningWheel;

@end

@implementation KCLargeImageVC

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
    
//    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
//                             forBarMetrics:UIBarMetricsDefault];
//    
//    self.navigationController.navigationBar.shadowImage = [UIImage new];
//    self.navigationController.navigationBar.translucent = YES;
//    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.tabBarController.tabBar.hidden = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.spinningWheel startAnimating];
    
    
    // Puts the file as an object in the bucket.
    S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc] initWithKey:self.s3PathWay withBucket:KWIKCY_PROFILE_BUCKET];
    
    [[QPNetworkActivity sharedInstance] increaseActivity];
    S3GetObjectResponse *response = [[AmazonClientManager s3] getObject:getObjectRequest];
    [[QPNetworkActivity sharedInstance] decreaseActivity];

    [self.spinningWheel stopAnimating];
    NSLog(@"Getting large phtotofe");
    if (!response.error)
    {
        NSLog(@"Getting large phtotofe no ERROR");

        NSData *data = response.body;
        
        if (data)
        {
            self.largeProfileImage.image = [UIImage imageWithData:data];
        }
    }
}


@end
