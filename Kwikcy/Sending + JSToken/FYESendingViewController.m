//
//  FYESendingViewController.m
//  For Your Eyes
//
//  Created by Hanny Aly on 7/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//



#import "FYESendingViewController.h"
#import <AWSS3/AWSS3.h>

#import "AmazonKeyChainWrapper.h"
#import "AmazonClientManager.h"

#import "Constants.h"
#import "KCDate.h"
#import "Crypto.h"
#import "MBProgressHUD.h"
#import "Sent_message+methods.h"

#import "NSString+validate.h"

#import "AsyncImageUploader.h"

#import "QPCoreDataManager.h"

#import "QPNetworkActivity.h"

#import "DLCImagePickerController.h"


#import "KwikcyClientManager.h"

#import "KCServerResponse.h"

#import "KCAsyncImageUploader.h"

#import "KCSynchronousUploader.h"

#define MAXLENGTH 60

@interface FYESendingViewController ()
    <UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextView      *textMessage;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (nonatomic, strong) MBProgressHUD          *hud;
//@property (nonatomic, strong) NSMutableDictionary    *messageDictionary;
@property (nonatomic, strong) NSTimer    *HUDalarm;

@property (weak, nonatomic) IBOutlet JSTokenField *contactField;


@property (strong, nonatomic) NSNumber *beginningOfWord;

@property (weak, nonatomic, getter = isScreenshotSwitchOn) IBOutlet UISwitch *screenshotSwitch;


@end


@implementation FYESendingViewController




#pragma mark Life cycle


-(BOOL)prefersStatusBarHidden
{
    return NO;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:NO animated:NO];

//    self.textMessage.delegate = self;
    self.contactField.delegate = self;

    self.contactField.userInteractionEnabled = NO;
    
    self.managedObjectContext = [QPCoreDataManager sharedInstance].managedObjectContext;
    
    
    UIView *separator1 = [[UIView alloc] initWithFrame:CGRectMake(0, self.contactField.bounds.size.height-1, self.contactField.bounds.size.width, 1)];
    [separator1 setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [self.contactField addSubview:separator1];
    [separator1 setBackgroundColor:[UIColor clearColor]];


}




-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([self.contactsList count])
    {
        self.sendButton.enabled = YES;

        [self refreshTextFieldWithNewContactsToAdd:self.contactsList];
    }
    else
    {
        self.sendButton.enabled = NO;
        //[self.contactField.textField becomeFirstResponder];
    }
}




- (IBAction)userPressedOnScreenshotInfoButton:(UIButton *)sender

{
    [[[UIAlertView alloc] initWithTitle:@"Screenshot Safe"
                               message:@"By selecting this, you're okay with your friends taking a screenshot. You're foregoing any retribution against them. (i.e. Keep this unselected if you want to be notified about a screenshot taken."
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil]
     show ];
}





-(void)refreshTextFieldWithNewContactsToAdd:(NSMutableArray *)newContactsToAdd
{
    for (NSDictionary *dictionary in newContactsToAdd)
    {
        [self.contactField addTokenWithDictionary:dictionary representedObject:dictionary];
    }
}









#pragma mark -
#pragma mark JSTokenFieldDelegate

//- (void)tokenField:(JSTokenField *)tokenField didAddToken:(NSString *)title representedObject:(id)obj
//{
//    if ([obj isKindOfClass:[NSDictionary class]])
//    {
//        NSLog(@"object title is %@", title);
//        NSLog(@"obj is  %@", obj);
//        NSLog(@"name title is %@", ((NSDictionary *)obj)[USERNAME]);
////        [self.contactsList addObject:((NSDictionary *)obj)];
//    }
//    else
//    {
//        NSLog(@"object title is %@", title);
//        NSLog(@"obj is  %@", obj);
//        
//    }
////    tokenField.textField.text = @"";
//}





//- (void)tokenField:(JSTokenField *)tokenField didRemoveToken:(NSString *)title representedObject:(id)obj;
//{
//    NSLog(@"didRemoveToken title = %@", title);
//    NSLog(@"self.contactsList count = %lu", (unsigned long)[self.contactsList count]);
//
//    NSDictionary *a = (NSDictionary *)obj;
//    NSLog(@"username title = %@", a[USERNAME]);
//
//    [self.contactsList removeObject:(NSDictionary *)obj];
//    NSLog(@"self.contactsList count = %lu", (unsigned long)[self.contactsList count]);
//
//}





//- (BOOL)tokenFieldShouldReturn:(JSTokenField *)tokenField
//{
//    NSLog(@"tokenFieldShouldReturn");
//    
//    NSString *userLowerCase = [[tokenField.textField.text lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    
//    
//    if ([self.contactsList count])
//    {
//        NSLog(@"tokenFieldShouldReturn contactsList count");
//        for (NSDictionary *obj in self.contactsList) {
//            NSString *userName = obj[USERNAME];
//            if ([userName isEqualToString:userLowerCase])
//                tokenField.textField.text = @"";
//                return NO;
//        }
//    }
//    
//    NSMutableString *recipient = [NSMutableString string];
//	
//    
//    //character set contains whitespace and punctuation characters
//	NSMutableCharacterSet *charSet = [[NSCharacterSet whitespaceCharacterSet] mutableCopy];
//	[charSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
//    
//
//    NSString *rawStr = tokenField.textField.text;
//    
//	for (int i = 0; i < [rawStr length]; i++)
//	{
//        //if character in string rawStr is not in the punctuation/whitespace set
//		if (![charSet characterIsMember:[rawStr characterAtIndex:i]])
//		{
//			[recipient appendFormat:@"%@",[NSString stringWithFormat:@"%c", [rawStr characterAtIndex:i]]];
//		}
//	}
//    if ([rawStr length])
//	{
//		[tokenField addTokenWithTitle:rawStr representedObject:recipient];
//	}
//    
//    return NO;
//}





















#pragma mark Message Text View Methods

//-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
//{
//    NSLog(@"textView:shouldChangeTextInRange");
//
//    /* Text is greater than 60 characters
//     * "Send" button  = "\n" = 1 amd Delete Button has length of 0
//     */
//    
//    /* If text is greater than 60 characters stop typing */
//    if (textView.text.length + 1 > MAXLENGTH && text.length) {
//        return NO;
//    }
//    /* If return -> "Send" button was pressed */
//    else if([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound ) {
//        NSLog(@"Send button /return button pressed");
//        if (![self.contactsList count]){
//            [[Constants alertWithTitle:nil andMessage:@"Enter a username to send to"] show];
//            return NO;
//        }
//        else
//        {
//            for (NSString *user in self.contactsList) {
//                if (user.length < 3){
//                    [[Constants alertWithTitle:nil andMessage:[NSString stringWithFormat:@"%@ does not exist", user]] show];
//                    return NO;
//                }
//            }
//        }
//        
//        [self sendVideo:nil];
//        return NO;
//    }
//    // Allow for adding text and backspace
//    else
//        return YES;
//}





#pragma mark Contacts Text Field Methods
- (IBAction)sendToTextFieldSelected
{
    [self.contactField.textField becomeFirstResponder];
}


- (IBAction)messageTextFieldSelected
{
    [self.textMessage becomeFirstResponder];
}




///  Message textfield methods

//-(BOOL)textFieldShouldReturn:(UITextField *)textField
//{
//    NSLog(@"textFieldShouldReturn");
//    [self.textMessage becomeFirstResponder];
//    return YES;
//}
//
//
//-(void)textFieldDidEndEditing:(UITextField *)textField
//{
//    NSLog(@"textFieldDidEndEditing");
//    [textField resignFirstResponder];
//}




//- (IBAction)goToContactsPage
//{
//    [self performSegueWithIdentifier:@"Go To Contacts Page" sender:nil];
//}



//-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    
//    NSLog(@"segue identifier = %@", segue.identifier);
//    if ([segue.identifier isEqualToString:@"Go to sending view"])
//    {
//        [self sendMyContactsBackToContactsViewController];
//    }
//}








/*
 * Contains an array of dictionaries
 *
 * Format: USERNAME: username, IMAGE: imageView
 *
 */


//-(void)getContactsToSendTo:(NSArray *)addedContacts andContactsToRemove:(NSArray *)removedContacts;
//{
//    NSLog(@"FYESendingViewController getContactsToSendTo");
//    
//    NSMutableArray *newContactsToAdd    = [NSMutableArray array];
//    NSMutableArray *newContactsToRemove = [NSMutableArray array];
//    
//    
//    if (addedContacts)
//    {
//        for (NSDictionary *newContact in addedContacts)
//        {
//            NSString *newContactsName  = newContact[USERNAME];
//            
//            BOOL inArray = NO;
//            
//            for (NSDictionary *currentContact in self.contactsList)
//            {
//                NSString *currentContactName  = currentContact[USERNAME];
//        
//                if ([[currentContactName lowercaseString] isEqualToString:[newContactsName lowercaseString]])
//                {
//                    inArray = YES;
//                    break;
//                }
//            }
//            if (!inArray)
//                [newContactsToAdd addObject:newContact];
//        }
//    }
//    
//    
//    if (removedContacts)
//    {
//        for (NSDictionary *removedContact in removedContacts)
//        {
//            NSString *removedContactsName  = removedContact[USERNAME];
//            
//            for (NSDictionary *currentContact in self.contactsList)
//            {
//                NSString *currentContactName  = currentContact[USERNAME];
//                if ([[currentContactName lowercaseString] isEqualToString:[removedContactsName lowercaseString]])
//                {
//                    [newContactsToRemove addObject:removedContact];
//                    break;
//                }
//            }
//        }
//    }
//    
//    NSLog(@"newContactsToAdd final count count = %lu", (unsigned long)[newContactsToAdd count]);
//    NSLog(@"removedContacts  final count count = %lu", (unsigned long)[newContactsToRemove count]);
//
//    
//    [self refreshTextFieldWithNewContactsToAdd:newContactsToAdd andThoseToRemove:newContactsToRemove];
//}












-(void)alertWithMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[Constants alertWithTitle:nil andMessage:message] show];
    });
}



- (IBAction)sendVideo:(UIBarButtonItem *)sender
{
    NSLog(@"sendVideo");
    self.sendButton.enabled = NO;
    [self.textMessage resignFirstResponder];
    [self.contactField.textField resignFirstResponder];


    // Error checking
    if (![self.contactsList count])
    {
        [self alertWithMessage:@"Select a user from your contacts"];
        return;
        
//        NSString *name = [self.contactField.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//        
//        if ([name length])
//        {
//            [self.contactsList addObject:name];
//        }
//        else
//        {
//            [self alertWithMessage:@"Enter a username"];
//            return;
//        }
    }
    
    
    NSMutableArray *invalidUsers = [NSMutableArray new];
    for (NSDictionary * user in self.contactsList)
    {
        NSString *username = user[USERNAME];
        if (![NSString validateUserName:username] || username.length < 3){
            [invalidUsers addObject:user];
        }
    }
    
    if ([invalidUsers count] == 1)
    {
        NSDictionary * user = [invalidUsers lastObject];
        NSString *username = user[USERNAME];

        [self alertWithMessage:[NSString stringWithFormat:@"%@ does not exist", username]];
        return;
    }
    else if ([invalidUsers count] > 1)
    {
        NSMutableArray *invalidUsernames = [NSMutableArray array];
        
        for (NSDictionary * user in invalidUsers)
        {
            [invalidUsernames addObject:user[USERNAME]];
        }
        
        NSString * users = [invalidUsernames componentsJoinedByString:@", "];
        [self alertWithMessage:[NSString stringWithFormat:@"Users: %@do not exist", users]];
        return;
    }

    
    NSString *username  = [AmazonKeyChainWrapper username];

    
    //realdate is inserted into database
    // dateInSeconds used as random string
        
    NSString *dateInSeconds = [KCDate getTimeInSecondsFromDate:[NSDate date]];
    NSString *dateInSecondsForFileName = [dateInSeconds stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    
    
    NSMutableArray *validUsernames = [NSMutableArray array];
    
    for (NSDictionary * user in self.contactsList)
    {
        [validUsernames addObject:user[USERNAME]];
    }
    
    
    
    NSString *mediaType = self.mediaInfo[MEDIATYPE];
    
    NSString *filename  = [NSString stringWithFormat:@"%@_%@", dateInSecondsForFileName, username];
  
    
        
    NSString *filepath;
    /* MEDIATYPE will be "video" / "photo" / "text" / "audio" */
    
    if ([mediaType isEqualToString:IMAGE]){
        filename = [NSString stringWithFormat:@"%@.jpg", filename];
        filepath = [NSString stringWithFormat:@"%@/%@/%@", username, IMAGE, filename];
    }
    else if ([mediaType isEqualToString:VIDEO]){
        filename = [NSString stringWithFormat:@"%@.mov", filename];
        filepath = [NSString stringWithFormat:@"%@/%@/%@", username, VIDEO, filename];
    }
    else {
        filename = [NSString stringWithFormat:@"%@.mp3", filename];
        filepath = [NSString stringWithFormat:@"%@/%@/%@", username, AUDIO, filename];
    }

    
    NSString *contacts = [validUsernames componentsJoinedByString:@" "];
    
    
    NSMutableDictionary *messageDictionary = [NSMutableDictionary new];
    
    
    messageDictionary[SENDER]          = username;
    messageDictionary[DATE]            = dateInSeconds;
    messageDictionary[FILENAME]        = filename;
    messageDictionary[FILEPATH]        = filepath;
    messageDictionary[MEDIATYPE]       = mediaType;
    messageDictionary[RECEIVERS_ARRAY] = validUsernames;
    messageDictionary[RECEIVERS]       = contacts;
    
    messageDictionary[SCREENSHOT_SAFE]       = @(self.screenshotSwitch.isOn);

    NSLog(@"SCREENSHOT_SAFE is %@", self.screenshotSwitch.isOn ? @(YES):@(NO) );
    
    if ([mediaType isEqualToString:IMAGE])
    {
        messageDictionary[IMAGE] = self.mediaInfo[IMAGE];
        messageDictionary[DATA]  = self.mediaInfo[DATA];
    }
    else if ([mediaType isEqualToString:VIDEO])
        messageDictionary[MOVIEURL] = self.mediaInfo[MOVIEURL];
    
    
    /* Creating dictionary with all needed data */
    messageDictionary[MESSAGE] = [NSNull null];

    
//            if (self.textMessage.text.length > 0)
//                [self.messageDictionary setObject:[self.textMessage.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] forKey:MESSAGE];
//            else
//                [self.messageDictionary setObject:[NSNull null] forKey:MESSAGE];
    
    
    
    

    if([self.operationQueue operationCount] > 2)
    {
        [[Constants alertWithTitle:nil andMessage:@"Try again in a little while"] show];
        self.sendButton.enabled = YES;
        return;
    }

    

    [self.managedObjectContext performBlockAndWait:^{
        [Sent_message insertSentMessageWithInfo:messageDictionary
                         inManagedObjectContext:self.managedObjectContext];
    }];
    
    
    

//    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
//    
//    [progressView setProgressTintColor:[UIColor blackColor]];
//    [progressView setTrackTintColor:[UIColor redColor]];
  
//    
//    KCAsyncImageUploader *uploader = [[KCAsyncImageUploader alloc] initWithMessageDictionary:messageDictionary andProgressView:progressView withManagedObjectContext:self.managedObjectContext];
//    
//    [uploader start];
    
    // 2nd thread, upload photo to s3
//    AsyncImageUploader *imageUploader =
//    [[AsyncImageUploader alloc] initWithMessageDictionary:messageDictionary
//                                          andProgressView:progressView
//                                 withManagedObjectContext:self.managedObjectContext];
//
//    [self.operationQueue addOperation:imageUploader];

    
    
    KCSynchronousUploader *imageUploader =
    [[KCSynchronousUploader alloc] initWithMessageDictionary:messageDictionary
                                          andProgressView:nil
                                 withManagedObjectContext:self.managedObjectContext];
    
    [self.operationQueue addOperation:imageUploader];
    
    
    
    
    
    [self sendSentMessageToDelegate:YES andProgressBar:nil];
}



/*
 * Put request to send metadata to dynamodb
 * On success, we can store this information on core data and use getItems instead on querying
 */


-(void)sendSentMessageToDelegate:(BOOL)sent andProgressBar:(UIProgressView *)progressBar;
{
    NSLog(@"sendSentMessageToDelegate       Sending Controller 1");
    [self.delegate messageWasSent:YES withProgressBar:progressBar];
    NSLog(@"sendSentMessageToDelegate       Sending Controller call pop To Root");

    [self.navigationController popToRootViewControllerAnimated:NO];
}






@end
