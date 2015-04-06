//
//  KCContactsSearchOptionTVC.m
//  Kwikcy
//
//  Created by Hanny Aly on 8/7/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCContactsSearchOptionTVC.h"
#import "Constants.h"
#import "AmazonKeyChainWrapper.h"
#import "KwikcyClientManager.h"
#import "KCServerResponse.H"

@interface KCContactsSearchOptionTVC ()

@end

@implementation KCContactsSearchOptionTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIActivityIndicatorView *spinningWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinningWheel.color = [UIColor redColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinningWheel];
    
    spinningWheel.hidesWhenStopped = YES;
    
    [spinningWheel startAnimating];
    
    self.tableView.userInteractionEnabled = NO;
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    parameters[COMMAND]  = GET_CONTACTS_SEARCH_OPTION;
    
    [KwikcyClientManager sendRequestWithParameters:parameters
                             withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
     {
         [spinningWheel stopAnimating];
         self.tableView.userInteractionEnabled = YES;
         
         self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveContactsPrivacyOption)];
         
         if (error)
         {
             [[Constants alertWithTitle:@"Connection Error"
                             andMessage:@"Could not get current mobile search options due to an internet connection error"] show];
         }
         else
         {
             KCServerResponse *serverResponse = (KCServerResponse *)response;
             
             if (received200Response)
             {
                 if (serverResponse.successful)
                 {                     
                     NSString *option = serverResponse.info[OPTION];
                     // Update the tableView
                     
                     UITableViewCell *cell;
                     if ([option isEqualToString:USER_ADD_STATUS_PUBLIC])
                     {
                         cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                     }
                     else if ([option isEqualToString:USER_ADD_STATUS_PRIVATE])
                     {
                         cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                     }
                     else if ([option isEqualToString:USER_ADD_STATUS_PRIVATE_ALLOW_ADDRESS_BOOK])
                     {
                         cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                     }
                     
                     UILabel *label = (UILabel *)[cell viewWithTag:1];
                     label.textColor = [UIColor redColor];
                     
                     UIImageView *checkMark = (UIImageView *)[cell viewWithTag:2];
                     checkMark.hidden = NO;
                 }
                 else
                 {
                     NSLog(@"GET_CONTACTS_SEARCH_OPTION serverResponse was unsuccessful!: %@", serverResponse.message);
                 }
             }
             else
             {
                 [[Constants alertWithTitle:@"Kwikcy error" andMessage:@"Could not get current mobile settings"] show];
             }
         }
     }];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    for (int i = 0; i < 3; i++ )
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        
        UILabel *label = (UILabel *)[cell viewWithTag:1];
        label.textColor = [UIColor blackColor];
        
        UIImageView *checkMark = (UIImageView *)[cell viewWithTag:2];
        checkMark.hidden = YES;
        
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    label.textColor = [UIColor redColor];
    
    UIImageView *checkMark = (UIImageView *)[cell viewWithTag:2];
    checkMark.hidden = NO;
}



-(void)saveContactsPrivacyOption
{
    int i;
    for (i = 0; i < 3; i++ )
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        UIImageView *checkMark = (UIImageView *)[cell viewWithTag:2];
        
        if (!checkMark.isHidden)
        {
            break;
        }
    }
    
    if (i == 3)
    {
        [[Constants alertWithTitle:nil andMessage:@"Select an option"] show];
        return;
    }
    
    NSString *option;
    
    switch (i)
    {
        case 0: option = USER_ADD_STATUS_PUBLIC;
            break;
        case 1: option = USER_ADD_STATUS_PRIVATE;
            break;
        case 2: option = USER_ADD_STATUS_PRIVATE_ALLOW_ADDRESS_BOOK;
            break;
        default:
        {
            NSLog(@"Should never happen");
            [[Constants alertWithTitle:nil andMessage:@"Select an option"] show];
            return;
        }
    }
    
    UIActivityIndicatorView *spinningWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinningWheel.color = [UIColor redColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinningWheel];
    
    spinningWheel.hidesWhenStopped = YES;
    
    [spinningWheel startAnimating];
    
    
    self.tableView.userInteractionEnabled = NO;
    
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    parameters[COMMAND]  = CHANGE_CONTACTS_PRIVACY_SETTING;
    parameters[OPTION]   = option;
    
    
    [KwikcyClientManager sendRequestWithParameters:parameters
                             withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
     {
         
         [spinningWheel stopAnimating];
         self.tableView.userInteractionEnabled = YES;
         
         self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveContactsPrivacyOption)];
         
         if (error)
         {
             [[Constants alertWithTitle:@"Connection Error"
                             andMessage:@"Could not send request due to an internet connection error"] show];
         }
         else
         {
             KCServerResponse *serverResponse = (KCServerResponse *)response;
             
             if (received200Response)
             {
                 if (serverResponse.successful)
                 {
                     NSLog(@"serverResponse.successful!");
                     
                     // Update the tableView
                     [[Constants alertWithTitle:@"Saved" andMessage:serverResponse.info[MESSAGE]] show];
                 }
                 else
                 {
                     NSLog(@"serverResponse was unsuccessful!");
                     [[Constants alertWithTitle:@"Error" andMessage:serverResponse.message] show];
                 }
             }
             else
             {
                 NSLog(@"serverResponse was not 200!");
                 [[Constants alertWithTitle:nil andMessage:serverResponse.message] show];
             }
         }
     }];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 3;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


@end
