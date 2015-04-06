//
//  KCUserContactUsVC.m
//  Kwikcy
//
//  Created by Hanny Aly on 4/22/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCUserContactUsVC.h"
#import "AmazonClientManager.h"
#import "AmazonKeyChainWrapper.h"
#import "Constants.h"
#import "KCDate.h"
#import "QPNetworkActivity.h"

#import "KwikcyClientManager.h"
#import "KCServerResponse.h"

@interface KCUserContactUsVC ()<UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textViewMessage;

@end

@implementation KCUserContactUsVC


#define CONTACT_US_TABLE @"kcContactUs"

#define Place_Holder @"Questions, thoughts or problems? Let us know"



-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
 
    self.textViewMessage.text = Place_Holder;
    self.textViewMessage.textColor = [UIColor redColor];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.textViewMessage becomeFirstResponder];

}


-(void)viewWillDisappear:(BOOL)animated
{
    [self resignFirstResponder];
    [super viewWillDisappear:animated];
}



/*
 *  Called when keyboards shows up
 */
-(void)textViewDidBeginEditing:(UITextView *)textView
{
    textView.selectedRange =  NSMakeRange(0, 0);
}





-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // place holder exist and user presses back space
    if ([textView.text isEqualToString:Place_Holder] && ![text length])
        ; //do nothing
    else if ([textView.text isEqualToString:Place_Holder] && [text isEqualToString:@"\n"])
    {
        return NO;
    }
    else if ([textView.text isEqualToString:Place_Holder] && ![text isEqualToString:@"\n"])
    {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    
    // one character left and user backspaces, replace to place holder
    else if ([textView.text length] == 1 && ![text length])
    {
        textView.text = Place_Holder;
        textView.textColor = [UIColor redColor];
        textView.selectedRange =  NSMakeRange(0, 0);

    }
    // pressed send
    else if( [text isEqualToString:@"\n"] )
    {
        [self sendMessage];
        return NO;
    }
    
    return YES;
}




-(void)sendMessage
{
    UIActivityIndicatorView *spinningWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinningWheel.color = [UIColor redColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinningWheel];
    spinningWheel.hidesWhenStopped = YES;
  
    [spinningWheel startAnimating];
    
    
    
    
    
    
//    NSString *time        = [KCDate getTimeInSecondsFromDate:[NSDate date]];
//    NSString *dateAndTime = [KCDate getDateFromSecondsForContacts:time];
//
//    // key and range
// 
//    NSMutableDictionary *userDic = [NSMutableDictionary dictionary];
//    userDic[USERNAME] = [[DynamoDBAttributeValue alloc] initWithS:[AmazonKeyChainWrapper username]];
//    userDic[DATE]     = [[DynamoDBAttributeValue alloc] initWithS:dateAndTime];
//    userDic[MESSAGE]  = [[DynamoDBAttributeValue alloc] initWithS:self.textViewMessage.text];
//
//    //Send DynamoDB Request to database
//
//    DynamoDBPutItemRequest *request  = [[DynamoDBPutItemRequest alloc] initWithTableName:CONTACT_US_TABLE
//                                                                                 andItem:userDic];
//
//    [[QPNetworkActivity sharedInstance] increaseActivity];
//    DynamoDBPutItemResponse *response = [[AmazonClientManager ddb] putItem:request];
//    [[QPNetworkActivity sharedInstance] decreaseActivity];
//
//    
//    
//    [[QPNetworkActivity sharedInstance] increaseActivity];
//    [spinningWheel stopAnimating];
    
    
    
    
    
    
    NSString *time        = [KCDate getTimeInSecondsFromDate:[NSDate date]];
    NSString *dateAndTime = [KCDate getDateFromSecondsForContacts:time];

    NSMutableDictionary *variables = [NSMutableDictionary new];
    
    variables[COMMAND]    = CONTACT_US;

    variables[DATE]      = dateAndTime;
    variables[MESSAGE]   = self.textViewMessage.text;

    [KwikcyClientManager sendRequestWithParameters:variables
                             withCompletionHandler:^(BOOL receieved200Response, Response *response, NSError *error)
     {
         
         [spinningWheel stopAnimating];
         [[QPNetworkActivity sharedInstance] decreaseActivity];

         if ( !error )
         {
             if (receieved200Response && ((KCServerResponse *)response).successful)
             {
                 
                 [self.textViewMessage resignFirstResponder];
                 
                 [[Constants alertWithTitle:nil andMessage:@"Message received"] show];
                 [self.navigationController popViewControllerAnimated:YES];
             }
             else
             {
                 [[Constants alertWithTitle:nil andMessage:@"Sorry. We can't seem to accept your message right now. Please try again later"] show];
             }
         }
         else
         {
             [[Constants alertWithTitle:@"Connection Error"
                             andMessage:@"Could not send request due to an internet connection error"] show];
         }
     }];
     
                     
                     
                     
                     
                     
                     
                     
                     
                     
    
//    
//    [self.textViewMessage resignFirstResponder];
//    
//
//    if (!response.error)
//    {
//        [[Constants alertWithTitle:nil andMessage:@"Message received"] show];
//        [self.navigationController popViewControllerAnimated:YES];
//    }
//    else
//    {
//        [[Constants alertWithTitle:nil andMessage:@"Sorry. We can't seem to accept your message right now. Please try again later"] show];
//    }
}


@end
