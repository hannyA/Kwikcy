//
//  QPForgotPasswordVC.m
//  Quickpeck
//
//  Created by Hanny Aly on 1/5/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "QPForgotPasswordVC.h"

@interface QPForgotPasswordVC ()

@end

@implementation QPForgotPasswordVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}



-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.backItem.title = @"Home";
}

@end
