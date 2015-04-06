//
//  KCOptionsVC.m
//  Quickpeck
//
//  Created by Hanny Aly on 4/2/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCOptionsVC.h"

#import "KCSupportWebView.h"

@interface KCOptionsVC ()<UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *contactsButton;
@property (weak, nonatomic) IBOutlet UIButton *mobileSearchButton;
@property (weak, nonatomic) IBOutlet UIButton *contactUsButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;


@end

@implementation KCOptionsVC


-(void)viewDidLoad
{
    self.scrollView.delegate = self;
    
    [self.scrollView setScrollEnabled:YES];
    [self.scrollView setContentSize:CGSizeMake(320, 620)];
    
    
    [self.contactsButton     setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [self.mobileSearchButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [self.contactUsButton    setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [self.logoutButton       setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];    
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}
-(void)help
{
}

- (IBAction)buttonPressedForWebView:(UIButton *)sender
{

    // help center
    if (sender.tag == 1 )
    {
        [self performSegueWithIdentifier:@"Get Kwikcy Web Data" sender:self];
    }
    // Privacy policy
    else if (sender.tag == 2 )
    {
        
    }
    // Terms of Service
    else if (sender.tag == 3 )
    {
        ;
        
    }
//    if ([sender.titleLabel.text isEqualToString:@"   Help Center"])
//    {
//        
//    }
//    else if ([sender.titleLabel.text isEqualToString:@"   Privacy Policy"])
//    {
//        
//    }
//    else if ([sender.titleLabel.text isEqualToString:@"   Terms of Serice"])
//    {
//        
//    }
}



/* Prepare to segue to other views */


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqual:@"Help Center"])
    {
        NSLog(@"Help Center");
        
        [segue.destinationViewController performSelector:@selector(setWebTypeNumber:)
                                              withObject:[NSNumber numberWithInteger:KCWebTypeHelpCenter] ];
    }
    else if ([segue.identifier isEqual:@"Privacy Policy"])
    {
        NSLog(@"Privacy Policy");
        
        [segue.destinationViewController performSelector:@selector(setWebTypeNumber:)
                                              withObject:[NSNumber numberWithInteger:KCWebTypePrivacyPolicy] ];
    }
    else if ([segue.identifier isEqual:@"Terms of Service"])
    {
        NSLog(@"Terms of Service");
        
        [segue.destinationViewController performSelector:@selector(setWebTypeNumber:)
                                              withObject:[NSNumber numberWithInteger:KCWebTypeTermsOfService] ];
    }
}

@end
