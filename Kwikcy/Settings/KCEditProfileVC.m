//
//  KCEditProfileVC.m
//  Quickpeck
//
//  Created by Hanny Aly on 4/2/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <AddressBook/AddressBook.h>

#import "KCEditProfileVC.h"

#import "QPCoreDataManager.h"
#import "User+methods.h"
#import "KwikcyClientManager.h"
#import "Constants.h"
#import "KCServerResponse.h"
#import "QPNetworkActivity.h"

#import "NSString+validate.h"

#import "ViewController_State+methods.h"

#import "Constants.h"

#import "AmazonKeyChainWrapper.h"


#import "KwikcyAWSRequest.h"



#define OK 1
#define DENY 0
#define EditProfileVC  @"KCEditProfileVC"


#define AllowAddressBookAlert 5
#define ErrorAlert 10


@interface KCEditProfileVC ()<UIAlertViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *allTextFields;


@property (weak, nonatomic) IBOutlet UITextField *realnameTextField;
@property (weak, nonatomic) IBOutlet UIButton *realnameTextFieldSaveButton;


//@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
//@property (weak, nonatomic) IBOutlet UIButton *emailTextFieldSaveButton;


@property (weak, nonatomic) IBOutlet UITextField *mobileTextField;
@property (weak, nonatomic) IBOutlet UIButton *mobileTextFieldSaveButton;


@property (weak, nonatomic) IBOutlet UITextField *codeConfirmationTextField;
@property (weak, nonatomic) IBOutlet UIView *codeConfirmationView;
@property (weak, nonatomic) IBOutlet UIView *mobileView;


@property (nonatomic, strong) ViewController_State *state;


@property (nonatomic, strong) UITextField *currentTextField;
@property (strong, nonatomic) IBOutlet UIView *slidingView;

@property (nonatomic, strong) NSString *oldText;

@end



@implementation KCEditProfileVC


/*
 * TODO: If realname exists, show it
 * If we already confirmed our email or mobile number then don't show the buttons, if someone wants to change it,
 * then allow text field to exist, if typing begins, animate show button. And allow a limit of getting a code to twice a day
 * on mobile phone
 */


/*
 * viewDidLoad gets called each time, the "Edit" button is clicked in user profile. 
 * viewDidAppear may be useless in this case
 */

- (void)viewDidLoad
{
    NSLog(@"KCEditProfileVC");
    [super viewDidLoad];
    
    
    for (UITextField *field in self.allTextFields)
    {
        field.leftView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
        field.leftViewMode = UITextFieldViewModeAlways;
        field.delegate = self;
    }
    
    //TODO: should change to make it hidden initially
    // The "add mobile code" textfield is shown, so we hide it move it up
    
    [self moveCodeViewUp];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
  
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    
    NSString *username = [AmazonKeyChainWrapper username];
    //Get object get our data from server
    self.managedObjectContext = [QPCoreDataManager sharedInstance].managedObjectContext;

    
    if (self.managedObjectContext)
    {
        [self.managedObjectContext performBlockAndWait:^{
            
            //Insert data in the text fields, if the user was in the middle of chnaging
            // name, but didn't save, too bad, clear the data and rewrite with orignal data
            
            User *mySelf = [User getUserForUsername:username inManagedContext:self.managedObjectContext];
            
            if (mySelf)
            {
                if (mySelf.realname)
                {
                    self.realnameTextField.text = mySelf.realname;
                }
                if (mySelf.mobile)
                    self.mobileTextField.text = mySelf.mobile;
            }
        }];
    }
    
    if (!self.realnameTextField.text || ![self.realnameTextField.text length] )
    {
        //    Get query for our real name and mobile confirmation, if not already stored in core data
        
        UIActivityIndicatorView *spinningWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinningWheel.color = [UIColor redColor];
        spinningWheel.hidesWhenStopped = YES;

        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinningWheel];
        
        self.view.userInteractionEnabled = NO;
        [spinningWheel startAnimating];
        
        NSDictionary *info = [KwikcyAWSRequest getDetailsForUser:username];
        
        [spinningWheel stopAnimating];
        self.view.userInteractionEnabled = YES;

        if (info[REALNAME])
        {
            self.realnameTextField.text = info[REALNAME];
        
            // Insert into Core data
            [User updateUserinfo:@{ ACTION   : InsertName,
                                    USERNAME : [AmazonKeyChainWrapper username],
                                    REALNAME : info[REALNAME]
                                  }
          inManagedObjectContext:self.managedObjectContext ];
        }
    }
}


-(UIActivityIndicatorView *)startActiviator:(id)sender
{
    UIActivityIndicatorView *spinningWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinningWheel.color = [UIColor redColor];
    spinningWheel.hidesWhenStopped = YES;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinningWheel];
    
    [sender setUserInteractionEnabled:NO];
    
    [spinningWheel startAnimating];
    
    return spinningWheel;
}


/*
 * Get the any info we type into the fields. 
 * Currently the only field we care about is mobile number, 
 * TODO: save state for email, email confirmtion will be sent through email
 */
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.state =  [ViewController_State getStateForViewController:EditProfileVC inManagedObjectContext:self.managedObjectContext];
    
    if (self.state)
    {
        NSLog(@"controllerState exists");
    
        self.mobileTextField.text = self.state.info;
        NSLog(@"controllerState.info = %@", self.state.info);
        
        [self moveCodeViewDown];
        
    }
}


-(void)viewWillDisappear:(BOOL)animated
{
    [self resignFirstResponder];
    [super viewWillDisappear:animated];
}


#pragma mark UITextField delegate methods


-(void)changeButtonTitleForTextField:(UITextField *)textField
{
    if ([textField isEqual:self.realnameTextField])
    {
        [self.realnameTextFieldSaveButton setTitle:@"Saved!" forState:UIControlStateNormal];
    }
    else if ([textField isEqual:self.mobileTextField])
    {
        [self.mobileTextFieldSaveButton setTitle:@"Sent!" forState:UIControlStateNormal];
    }
    else
    {
        
    }
}

-(void)resetButtonTitleForTextField:(UITextField *)textField
{
    if ([textField isEqual:self.realnameTextField])
    {
        [self.realnameTextFieldSaveButton setTitle:@"Save" forState:UIControlStateNormal];
    }
    if ([textField isEqual:self.mobileTextField])
    {
        [self.mobileTextFieldSaveButton setTitle:@"Confirm" forState:UIControlStateNormal];
    }
}











-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSLog(@"textFieldDidBeginEditing");
    
    self.currentTextField = textField;
    
    self.oldText = [textField.text copy];  //aqaman
    
    [self resetButtonTitleForTextField:textField];
    [self addCancelButtonforTextField:textField];
}


////
//if (self.currentTextField.inputAccessoryView)
//self.currentTextField.inputAccessoryView = nil;

#define CANCEL_BUTTON_HEIGHT 50
-(void)addCancelButtonforTextField:(UITextField *)textField
{
    UIButton  *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 20, CANCEL_BUTTON_HEIGHT, CANCEL_BUTTON_HEIGHT)];
    [cancelButton addTarget:self action:@selector(cancelButtonPressedSoDismissKeyBoad) forControlEvents:UIControlEventTouchDown];

    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted|UIControlStateSelected];
    
    textField.inputAccessoryView = cancelButton;
    textField.inputAccessoryView.backgroundColor = [UIColor redColor];
}

-(void)cancelButtonPressedSoDismissKeyBoad
{
    //Return textfield to original state
    self.currentTextField.text = self.oldText;
    [self.currentTextField resignFirstResponder];
 
    self.currentTextField = nil;
    self.oldText = nil;
}



-(void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"textFieldDidEndEditing");
    
    if (self.oldText)
        if (![self.oldText isEqualToString:textField.text])
            textField.text = self.oldText;
    self.oldText = nil;

    
//    if (self.currentTextField)
//    {
//        NSLog(@"textFieldDidEndEditing CHANGE TEXT BACK TO OLD");
//        
//        self.currentTextField.text = self.oldText;
//    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"textFieldShouldReturn");
    [textField resignFirstResponder];
    return YES;
}


/*
 User presses cancel button
 User presses send button
 User changes textFields
 */




#define Save_User_Info @"SaveUserInfo"
- (IBAction)saveRealnameForUser:(UIButton *)sender
{

    UITextField *textField = self.realnameTextField;

    NSString    *name      = self.realnameTextField.text;
    
    
    if (!name)
        return;
    
    
    if ([name isEqualToString:self.oldText])
    {
        self.oldText = nil;
        [[Constants alertWithTitle:nil andMessage:@"Name is saved"] show];
        return;
    }
    
    UIActivityIndicatorView *spinningWheel = [self startActiviator:sender];

    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[COMMAND]             = UPDATE_PERSONAL_INFO;
    parameters[REALNAME]            = name;
    
    
    [KwikcyClientManager sendRequestWithParameters:parameters
                             withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
     {
         [spinningWheel stopAnimating];
         sender.userInteractionEnabled = YES;

         
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
   
                     [User updateUserinfo:@{ ACTION   : InsertName,
                                             USERNAME : [AmazonKeyChainWrapper username],
                                             REALNAME : name
                                           }
                   inManagedObjectContext:self.managedObjectContext ];
                     
                     
                     self.oldText = nil;
                     [self changeButtonTitleForTextField:textField];

                     [textField resignFirstResponder];

                 }
                 else
                 {
                     NSLog(@"serverResponse was unsuccessful!");

                     [[Constants alertWithTitle:@"Error" andMessage:serverResponse.message] show];
                 }
             }
             else
             {
                 [[[UIAlertView alloc] initWithTitle:@"Error"
                                             message:serverResponse.message
                                            delegate:self
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil] show];
             }
         }
     }];
}






#pragma mark Server confirmation actions



/*
 * Mobile confirmation - 1st step
 *
 * User inserts mobile number and presses button for "code"
 */
- (IBAction)sendRequestToReceiveMobileConfirmationCode:(UIButton *)sender
{
    UITextField *textField = self.mobileTextField;
    

    
    NSString *mobileNumber = [NSString purifyMobileNumber:textField.text];

    if ([mobileNumber length] < 10 || [mobileNumber length] > 11)
    {
        [[Constants alertWithTitle:@"Mobile number is not correct" andMessage:@"Enter a 10 digit mobile number"] show];
        return;
    }
    

    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[MOBILE]  = mobileNumber;
    parameters[COMMAND] = REQUEST_MOBILE_CONFIRMATION_CODE;
    
    
    UIActivityIndicatorView *spinningWheel = [self startActiviator:sender];
    
    
    [KwikcyClientManager sendRequestWithParameters:parameters
                             withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
    {
        [spinningWheel stopAnimating];
        sender.userInteractionEnabled = YES;


        if (error){
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
                    CFTimeInterval now = CACurrentMediaTime();
                
                    NSDictionary *state = @{
                                            VIEWCONTROLLERNAME:EditProfileVC,
                                            TIME:[NSNumber numberWithDouble:now],
                                            VALID:[NSNumber numberWithBool:YES],
                                            ACTION:@"save",
                                            OBJECTVIEW:@"codeTextField",
                                            INFO:self.mobileTextField.text
                                           };
                    
                    
                    self.state =  [ViewController_State saveStateForViewController:state
                                                            inManagedObjectContext:self.managedObjectContext];
                    
                    
                    [self changeButtonTitleForTextField:textField];
                    
                    [textField resignFirstResponder];
                    
                    [[Constants alertWithTitle:@"Mobile Confirmation" andMessage:@"Your confirmation code will be sent to you soon. Please enter it below"] show];

                    [UIView animateWithDuration:1.0
                                          delay:0
                                        options: UIViewAnimationOptionCurveEaseOut
                                     animations:^{
                                         
                                         [self moveCodeViewDown];
                                     }
                                     completion:^(BOOL finished){
                                         NSLog(@"Done!");
                                     }];
                }
                else
                {
                    [[Constants alertWithTitle:nil andMessage:serverResponse.message] show];
                    self.oldText = nil;
                    [textField resignFirstResponder];
                    
                
                    [User updateUserinfo:@{ ACTION   : InsertMobile,
                                            USERNAME : [AmazonKeyChainWrapper username],
                                            MOBILE   : mobileNumber
                                            }
                  inManagedObjectContext:self.managedObjectContext ];


                }
            }
            else
            {
                 UIAlertView * alert =  [[UIAlertView alloc] initWithTitle:@"Error"
                                            message:serverResponse.message
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
                alert.tag = ErrorAlert;
                [alert show];
                
            }
        }
     }];
}



/*
 * Mobile confirmation - 3rd step
 *
 * Some alert view pops up
 */

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"ALertView clickedButtonAtIndex");

    if (alertView.tag == AllowAddressBookAlert)
    {
        NSLog(@"ALertView tag = 5");
        // If OK, then add contacts and send to server
        if (buttonIndex == DENY)
        {
            //show hud
            [self sendRequestWithMobileConfirmationCodeOnly];

        }
        else // == OK
        {
            [self getAccessToAddressBook];
        }
    }
    else { // error : (alertView.tag == 10) ErrorAlert
        [self moveCodeViewUp];
    }
}



/*
 * Mobile confirmation - 2nd step
 *
 * User enters sms "code" and presses send
 * An alert view will pop up asking for permission to send its contacts
 */
- (IBAction)userPressedButtonToConfirmMobileCode:(UIButton *)sender
{
    NSLog(@"userPressedButtonToConfirmMobileCode");
    
    UIAlertView * a = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Let %@ Access Your Address Book?", APP_NAME ]
                                                message:@"This allows people in your contacts to search for you by your mobile number"
                                                delegate:self
                                      cancelButtonTitle:@"Don't Allow" // nil
                                      otherButtonTitles:@"OK", nil];  // Don't Allow  = button 0, OK = button 1
    a.tag = AllowAddressBookAlert;
    [a show];
}





-(void)getAccessToAddressBook
{
    
    // Request authorization to Address Book
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error)
        {        
            // First time access has been granted, add the contact
            if (granted) {
                NSLog(@"User gave us access");
                [self sendRequestWithMobileConfirmationCodeAndContacts];
            } else {
                // User denied access
                NSLog(@"User denied us access");
                [self sendRequestWithMobileConfirmationCodeOnly];
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
        NSLog(@"User has previously given access");
        [self sendRequestWithMobileConfirmationCodeAndContacts];

    }
    else {
        NSLog(@"User has previously denied access");
        [self sendRequestWithMobileConfirmationCodeOnly];

        // The user has previously denied access
        // Send an alert telling user to change privacy setting in settings app
    }
    
}





#define FIRST @"firstname"
#define LAST  @"lastname"

-(NSArray *)getUserMobileContacts
{
    NSMutableArray *contacts = [NSMutableArray new];
    

    CFErrorRef *error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);

    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex numberOfPeople = ABAddressBookGetPersonCount(addressBook);
    
    for(int i = 0; i < numberOfPeople; i++)
    {
        NSMutableDictionary *newContact = [[NSMutableDictionary alloc] init];
    
        ABRecordRef person = CFArrayGetValueAtIndex( allPeople, i );
        
        NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
        NSLog(@"Name:%@ %@", firstName, lastName);
        
            
        
        newContact[FIRST]  = (firstName != nil ? firstName:[NSNull null]);
        newContact[LAST]  = (lastName != nil ? lastName:[NSNull null]);

        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        
        
        
        NSMutableArray *mobileNumbers = [NSMutableArray new];
      
        for (CFIndex i = 0; i < ABMultiValueGetCount(phoneNumbers); i++) {
            NSString *phoneNumber = (__bridge_transfer NSString *) ABMultiValueCopyValueAtIndex(phoneNumbers, i);
            NSLog(@"phone:%@", phoneNumber);
            [mobileNumbers addObject:phoneNumber];
        }
        
        newContact[MOBILE] = mobileNumbers;
        
        [contacts addObject:newContact];
        
    }
    
    return (contacts != nil) ? contacts : nil;
}



/*  Mobile confirmatin code functions */

-(void)sendRequestWithMobileConfirmationCodeOnly
{
    
    [self sendRequestWithMobileConfirmationCodeAndContacts:nil];
}


-(void)sendRequestWithMobileConfirmationCodeAndContacts
{
    NSArray *contacts = [self getUserMobileContacts];
    [self sendRequestWithMobileConfirmationCodeAndContacts:contacts];
}


-(void)sendRequestWithMobileConfirmationCodeAndContacts:(NSArray *)contacts
{
    // Allow contacts to be uploaded
    
    NSLog(@"sendRequestWithMobileConfirmationCodeAndContacts");
    NSString *code = self.codeConfirmationTextField.text;

    NSMutableDictionary *info = [NSMutableDictionary dictionary];
                                 
    
    info[COMMAND]  = VERIFY_MOBILE_CONFIRMATION_CODE;
    info[CODE]     = code;
    info[CONTACTS] = (contacts != nil)? contacts :[NSNull null] ;
    
    
    UIActivityIndicatorView *spinningWheel = [self startActiviator:self.mobileTextFieldSaveButton];

    
    [KwikcyClientManager sendRequestWithParameters:info
                             withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
     {
         
         [spinningWheel stopAnimating];
         self.mobileTextFieldSaveButton.userInteractionEnabled = YES;
         
         if (error)
         {
             NSLog(@"Received non 200 response");
         }
         else
         {
             //
             if (received200Response)
             {
                 KCServerResponse *serverResponse = (KCServerResponse *)response;
                 if (serverResponse.successful)
                 {
                      
//                     serverResponse.info[CONTACTS] == uploaded
                     NSString *message = serverResponse.info[CONTACTS] ? @"Your friends can now search for you":nil ;
                     [[Constants alertWithTitle:@"Mobile number confirmed" andMessage:message] show];
                     
                     [self.currentTextField resignFirstResponder];

                     [ViewController_State deleteStateForViewController:self.state inManagedObjectContext:self.managedObjectContext];
                     
                     
                     NSString *mobileNumber = [NSString purifyMobileNumber:self.mobileTextField.text];
                     [User updateUserinfo:@{ACTION:InsertMobile, MOBILE:mobileNumber }
                   inManagedObjectContext:self.managedObjectContext ];
                     
                                        
                    
                     
                     [UIView animateWithDuration:1.0
                                           delay:0
                                         options: UIViewAnimationOptionCurveEaseOut
                                      animations:^{
                                          [self moveCodeViewUp];
                                      }
                                      completion:^(BOOL finished){
                                          NSLog(@"Done!");
                                      }];
                 }
                 // If code was not correct or time limit for code is up
                 else
                     [[Constants alertWithTitle:@"Mobile confirmation error" andMessage:serverResponse.message] show];
             }
             
         }
     }];
}







#pragma mark Mobile code block
// These functions show and hide the "code" text field and view

-(void)moveCodeViewDown
{
    //    NSLog(@"Please move code block down");
    
    CGRect moveDown = CGRectMake(self.mobileView.frame.origin.x,
                                 self.mobileView.frame.origin.y +
                                 self.mobileView.frame.size.height + 3,
                                 self.codeConfirmationView.frame.size.width,
                                 self.codeConfirmationView.frame.size.height);
    self.codeConfirmationView.frame = moveDown;
}

-(void)moveCodeViewUp
{
    CGRect moveUp = CGRectMake(self.mobileView.frame.origin.x,
                               self.mobileView.frame.origin.y,
                               self.codeConfirmationView.frame.size.width,
                               self.codeConfirmationView.frame.size.height);
    
    self.codeConfirmationView.frame = moveUp;
}



-(void)keyboardShow:(NSNotification *)n
{
    NSLog(@"keyboardShow");
    NSDictionary *userDictionary = [n userInfo];
    
    NSNumber *duration = userDictionary[UIKeyboardAnimationDurationUserInfoKey];
    
    
    CGRect keyboardSizeRect = [userDictionary[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    keyboardSizeRect = [self.slidingView convertRect:keyboardSizeRect fromView:nil];
    
    //    NSLog(@"\nkeyboardSize.origin.x = %f,\n \
    //          keyboardSize.origin.y = %f, \n \
    //          keyboardSize.size.width = %f, \n \
    //          keyboardSize.size.height = %f  ",
    //          keyboardSizeRect.origin.x,
    //          keyboardSizeRect.origin.y,
    //          keyboardSizeRect.size.width,
    //          keyboardSizeRect.size.height );
    
    //    NSLog(@"\nself.currentTextField.frame.origin.x = %f,\n \
    //          self.currentTextField.frame.origin.y = %f, \n \
    //          self.currentTextField.frame.size.width = %f, \n \
    //          self.currentTextField.frame.size.height = %f  ",
    //          self.currentTextField.frame.origin.x,
    //          self.currentTextField.frame.origin.y,
    //          self.currentTextField.frame.size.width,
    //          self.currentTextField.frame.size.height );
    
    
    
    
    CGRect theWholeContainerOfTextFieldView = self.currentTextField.superview.frame;
    
    //    NSLog(@"\ntextFieldView.origin.x = %f,\n \
    //          textFieldView.origin.y = %f, \n \
    //          textFieldView.size.width = %f, \n \
    //          textFieldView.size.height = %f  ",
    //          theWholeContainerOfTextFieldView.origin.x,
    //          theWholeContainerOfTextFieldView.origin.y,
    //          theWholeContainerOfTextFieldView.size.width,
    //          theWholeContainerOfTextFieldView.size.height );
    
    
    //    NSLog(@"maxY(theWholeContainerOfTextFieldView) = %f,\n ", CGRectGetMaxY(theWholeContainerOfTextFieldView));
    
    
    CGFloat topOfCancelButtonLocation  = keyboardSizeRect.origin.y;
    CGFloat bottomOfTextFieldContainer = CGRectGetMaxY(theWholeContainerOfTextFieldView);
    
    if ( bottomOfTextFieldContainer > topOfCancelButtonLocation )
    {
        NSLog(@"something is covered");
        
        CGFloat slidingDistance = topOfCancelButtonLocation - bottomOfTextFieldContainer;
        
        NSLog(@"animate durtion = %f", [duration floatValue]);
        
        NSTimeInterval dur = [duration floatValue];
        
        
        [UIView animateWithDuration:(dur? dur:0.25) animations:^{
            self.slidingView.frame = CGRectMake(0, slidingDistance ,
                                                self.slidingView.frame.size.width,
                                                self.slidingView.frame.size.height);
            //            self.slidingView.center = CGPointMake(self.view.center.x, self.view.center.y - (y + 15));
        }];
    }
    
    
    //    CGFloat y = CGRectGetMaxY(textFieldView) - ([[UIScreen mainScreen] bounds].size.height -
    //                                                keyboardSize.size.height -
    //                                                CANCEL_BUTTON_HEIGHT );
    //
    
    
    //    NSLog(@"CGRectGetMaxY = %f, keyboardSize.size.height = %f ", CGRectGetMaxY(textFieldView), keyboardSize.size.height );
    //
    //    NSLog(@"Y coordinate = %f", y);
    
    
    //    NSLog(@"r.origin.y = %f < CGRectGetMaxY(f)= %f", keyboardSize.origin.y , CGRectGetMaxY(textFieldView));
    
    //    if (keyboardSize.origin.y  - CANCEL_BUTTON_HEIGHT  < CGRectGetMaxY(textFieldView))
    //    {
    //        NSLog(@"something is covered");
    //
    //        [UIView animateWithDuration:[duration floatValue] animations:^{
    //            self.slidingView.center = CGPointMake(self.view.center.x, self.view.center.y - (y + 15));
    //        }];
    //    }
}

-(void)keyboardHide:(NSNotification *)n
{
    //    NSLog(@"keyboardHide");
    //    NSLog(@"self.view.center.x = %f, self.view.center.y = %f", self.view.center.x, self.view.center.y);
    
    //    NSLog(@"self.slidingView.center.x = %f, self.slidingView.center.y = %f", self.slidingView.center.x, self.slidingView.center.y);
    
    //    NSLog(@"self.slidingView.frame.origin.x = %f, self.slidingView.frame.origin.y = %f",
    //          self.slidingView.frame.origin.x, self.slidingView.frame.origin.y);
    
    
    //    NSLog(@"self.slidingView.frame.origin.x = %f, self.slidingView.frame.origin.y = %f",
    //          self.slidingView.bounds.origin.x, self.slidingView.bounds.origin.y);
    
    //    NSLog(@"self.slidingView.frame.size.width = %f, self.slidingView.frame.size.height = %f",
    //          self.slidingView.frame.size.width, self.slidingView.frame.size.height);
    
    
    NSLog(@"keyboardHide");
    
    
    NSDictionary *userDictionary = [n userInfo];
    
    NSNumber *duration = userDictionary[UIKeyboardAnimationDurationUserInfoKey];
    
    NSTimeInterval dur = [duration floatValue];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.slidingView.frame = CGRectMake(0, 0, self.slidingView.frame.size.width, self.slidingView.frame.size.height);
    }];
}











@end
