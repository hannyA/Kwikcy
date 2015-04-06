//
//  RegistrationTableViewController.m
//  For Your Eyes
//
//  Created by Hanny Aly on 7/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RegistrationTableViewController.h"
#import "MBProgressHUD.h"

#import "AmazonClientManager.h"
#import "Constants.h"
#import "Response.h"
#import "QPNetworkActivity.h"
#import "QPCoreDataManager.h"

#import "AmazonKeyChainWrapper.h"
#import "Crypto.h"
#import "RegisterRequest.h"
#import "LoginResponseHandler.h"
#import "LoginResponse.h"


#import "User+methods.h"
#import "NSString+validate.h"

#import "KwikcyAWSRequest.h"

@interface RegistrationTableViewController ()

@property (weak, nonatomic) IBOutlet UITextField *userRealName;
@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet UITextField *userPassword;

@property (weak, nonatomic) IBOutlet UITextField *userEmail;
@property (weak, nonatomic) IBOutlet UITextField *userMobileNumber;

@property (strong, nonatomic) MBProgressHUD *hud;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *registerButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@property (weak, nonatomic) IBOutlet UIButton *bigRegisterButton;


@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorForUsername;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorForEmail;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorForPassword;

@property (weak, nonatomic) IBOutlet UIButton *successButtonForUsername;
@property (weak, nonatomic) IBOutlet UIButton *successButtonForEmail;
@property (weak, nonatomic) IBOutlet UIButton *successButtonForPassword;

@property (strong, nonatomic) NSString *errorMessageForUsernameLabel;
@property (strong, nonatomic) NSString *errorMessageForEmailLabel;
@property (strong, nonatomic) NSString *errorMessageForPasswordLabel;



@property (nonatomic, getter = isUsernameValid) BOOL usernameIsValid;
@property (nonatomic, getter = isPasswordValid) BOOL passwordIsValid;


@property (strong, nonatomic) NSURLConnection *conn;
@property (strong, nonatomic) Response *response;

@property(nonatomic)        NSUInteger  statusCode;
@property(nonatomic,strong) NSMutableData   *responseData;
@property(nonatomic,strong) ResponseHandler   *handler;




@end


@implementation RegistrationTableViewController


#pragma mark life cycle

- (void)viewDidLoad
{ 
    [super viewDidLoad];
    [self.userRealName becomeFirstResponder];
  
    [self.bigRegisterButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [self.bigRegisterButton setHidden:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self disableRegisterButton];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.userRealName becomeFirstResponder];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [self clearKeyBoard];
    [super viewWillDisappear:animated];
}


-(BOOL)prefersStatusBarHidden
{
    return NO;
}

- (IBAction)cancelPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)clearKeyBoard
{
    [self.userRealName resignFirstResponder];
    [self.userName resignFirstResponder];
    [self.userPassword resignFirstResponder];
}





-(void)showHUDWithMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hud = [MBProgressHUD getAndShowUniversalHUD:self.view withText:message animated:YES];
    });
}



-(void)showActivityIndicator:(UIActivityIndicatorView*)activityIndicator
{
    [[QPNetworkActivity sharedInstance] increaseActivity];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [activityIndicator startAnimating];
    });
}

-(void)hideActivityIndicator:(UIActivityIndicatorView*)activityIndicator
{
    [[QPNetworkActivity sharedInstance] decreaseActivity];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [activityIndicator stopAnimating];
    });
}



- (IBAction)userWantsToKnowWhyThereIsAnError:(UIButton *)sender
{
    if ( [sender isEqual:self.successButtonForUsername] && self.errorMessageForUsernameLabel)
    {
        [[Constants alertWithTitle:nil andMessage:self.errorMessageForUsernameLabel] show];
    }
    else if ([sender isEqual:self.successButtonForPassword] && self.errorMessageForPasswordLabel)
    {
        [[Constants alertWithTitle:nil andMessage:self.errorMessageForPasswordLabel] show];
    }
}



#pragma mark Right side button helper methods


-(void)showSuccessfulButton:(UIButton *)button
{
    [button setImage:[UIImage imageNamed:@"Check-mark-filled-pink"]
            forState:UIControlStateNormal];
    button.hidden = NO;
    button.userInteractionEnabled = NO;

    
    if ( [button isEqual:self.successButtonForUsername])
        self.errorMessageForUsernameLabel = nil;
    
    else if ([button isEqual:self.successButtonForPassword])
        self.errorMessageForPasswordLabel = nil;
}


-(void)showFailedButton:(UIButton *)button
{
    [button setImage:[UIImage imageNamed:@"X-mark-filled-pink"]
            forState:UIControlStateNormal];
    button.userInteractionEnabled = YES;
    button.hidden = NO;
}



-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.userPassword)
    {
        self.passwordIsValid = NO;

        NSString *concatedString = [NSString stringWithFormat:@"%@%@", self.userPassword.text, string];
        
        if ([concatedString length] <= 6 && [string isEqualToString:@""])
        {
            [self textFieldDidBeginEditing:textField];
        }
        else if ([concatedString length] > 5)
        {
            self.errorMessageForPasswordLabel = [NSString isPasswordValid:concatedString];
            if (self.errorMessageForPasswordLabel)
            {
                [self showFailedButton:self.successButtonForPassword];
            }
            else
            {
                self.passwordIsValid = YES;
                [self showSuccessfulButton:self.successButtonForPassword];
            }
        }
    }

    [self allRequiredTextFieldsAreFilled];
    return YES;
}



-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSLog(@"textFieldDidBeginEditing");
    if (textField == self.userName)
    {
        self.successButtonForUsername.hidden = YES;
        self.errorMessageForUsernameLabel = nil;
    }
    else if (textField == self.userPassword)
    {
        self.successButtonForPassword.hidden = YES;
        self.errorMessageForPasswordLabel = nil;
    }
}




// This method deals with the logic of what happens with the data
-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if (![textField.text length])
        return;
    
    if (textField == self.userName)
    {
        self.usernameIsValid = NO;

        self.errorMessageForUsernameLabel = [NSString isUsernameValid:self.userName.text];
        if (self.errorMessageForUsernameLabel)
        {
            [self showFailedButton:self.successButtonForUsername];
        }
        else
        {
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                
                [self showActivityIndicator:self.activityIndicatorForUsername];
                
                NSDictionary *info = [KwikcyAWSRequest getDetailsForUser:self.userName.text];
                
                [self hideActivityIndicator:self.activityIndicatorForUsername];
                
                
                dispatch_async(dispatch_get_main_queue(), ^{

                    if (!info) // i.e. No user found
                    {
                        [self showSuccessfulButton:self.successButtonForUsername];
                        self.usernameIsValid = YES;
                    }
                    else
                    {
                        self.errorMessageForUsernameLabel = @"Username already exists";
                        [self showFailedButton:self.successButtonForUsername];
                        
                    }
                    [self allRequiredTextFieldsAreFilled];

                });
                
            });
        }
    }
    
    else if (textField == self.userPassword)
    {
        self.passwordIsValid = NO;
        
        self.errorMessageForPasswordLabel = [NSString isPasswordValid:self.userPassword.text];
      
        if (self.errorMessageForPasswordLabel)
        {
            [self showFailedButton:self.successButtonForPassword];
        }
        else
        {
            self.passwordIsValid = YES;
            [self showSuccessfulButton:self.successButtonForPassword];
            [self allRequiredTextFieldsAreFilled];

        }
    }
}







//This part deals with the logic of switching fields
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.userRealName)
    {
        [textField resignFirstResponder];
        [self.userName becomeFirstResponder];
    }
    
    else if (textField == self.userName)
    {
        [textField resignFirstResponder];
        [self.userPassword becomeFirstResponder];
    }
    //password
    else
    {
        self.passwordIsValid = NO;

        self.errorMessageForPasswordLabel = [NSString isPasswordValid:self.userPassword.text];
        if (!self.errorMessageForPasswordLabel)
        {
            self.passwordIsValid = YES;
            [self showSuccessfulButton:self.successButtonForPassword];
            [self donePressed:nil];
        }
        else
        {
            [self showFailedButton:self.successButtonForPassword];
            self.userPassword.text = @"";
            return NO;
        }
    }
    return YES;
}



-(void)enableRegisterButton
{
    self.registerButton.enabled = YES;
    self.registerButton.tintColor = [UIColor redColor];
}

-(void)disableRegisterButton
{
    self.registerButton.enabled = NO;
    self.registerButton.tintColor = [UIColor grayColor];
}


-(BOOL)allRequiredTextFieldsAreFilled
{
    
//    NSLog(@"isPasswordValid : %@", self.isPasswordValid?@"YES":@"NO");
//    NSLog(@"isUsernameValid : %@", self.isUsernameValid?@"YES":@"NO");
   
    if (self.isPasswordValid && self.isUsernameValid )
    {
//        NSLog(@"registerButton enabled = YES");
        [self enableRegisterButton];
        return YES;
    }
    else
    {
//        NSLog(@"username error: %@", [NSString isUsernameValid:self.userName.text]);
//        NSLog(@"password error: %@", [NSString isPasswordValid:self.userPassword.text]);
//        NSLog(@"registerButton enabled = NO");
        [self disableRegisterButton];
        return NO;
    }
}


-(NSString *)getMessageForMissingTextField
{
    NSString *error = [NSString isUsernameValid:self.userName.text];
        
    if (!error)
        error = [NSString isPasswordValid:self.userPassword.text];

    return error;
}





-(IBAction)donePressed:(id)sender
{    
    [self clearKeyBoard];
    

    if (![self allRequiredTextFieldsAreFilled])
    {
        [[Constants alertWithTitle:@"Error" andMessage:[self getMessageForMissingTextField]] show];
        return;
    }
    
    [self disableRegisterButton];

    RegisterRequest* registerRequest = [[RegisterRequest alloc] initWithEndpoint:[RegisterRequest endpoint]
                                                                     andUsername:[self.userName.text lowercaseString]
                                                                     andPassword:self.userPassword.text
                                                                     andRealName:[self.userRealName.text lowercaseString]
                                                                        andEmail:[self.userEmail.text lowercaseString]
                                                                       andMobile:self.userMobileNumber.text
                                                                      andAppName:[RegisterRequest appName]
                                                                        usingSSL:[RegisterRequest useSSL]];

    self.handler = [[LoginResponseHandler alloc] initWithKey:registerRequest.decryptionKey];
    
    
    
    NSURL *url = [NSURL URLWithString:[registerRequest getUrl]];
    
    // set up the request
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                          timeoutInterval:20.0];
    
    NSString *usersRequestString = [registerRequest buildRequestUrl];
    NSData *usersEncodedData = [usersRequestString dataUsingEncoding:NSUTF8StringEncoding];
    
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [theRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[usersEncodedData length]] forHTTPHeaderField:@"Content-Length"];
    [theRequest setHTTPBody:usersEncodedData];
    
    
    
    
    // create the connection with the target request and this class as the delegate
    self.conn = [NSURLConnection connectionWithRequest:theRequest
                                              delegate:self];
    // start the connection
    [self.conn start];
    
    [[QPNetworkActivity sharedInstance] increaseActivity];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self showHUDWithMessage:@"Registering"];
    });
}





-(void)storeUserInformationInAmazonKeyChainWrapper:(Response *)response andUsername:(NSString *)username
{
    [AmazonKeyChainWrapper registerKey:((LoginResponse *)response).key];
    [AmazonKeyChainWrapper storeUsername:username];
    
    [AmazonKeyChainWrapper storeCredentialsInKeyChain:((LoginResponse *)response).accessKey
                                            secretKey:((LoginResponse *)response).secretKey
                                        securityToken:((LoginResponse *)response).securityToken
                                           expiration:((LoginResponse *)response).expirationDate];
}







/**
 * This delegate method is called when the NSURLConnection connects to the server.  It contains the
 * NSURLResponse object with the headers returned by the server.  This method may be called multiple times.
 * Therefore, it is important to reset the data on each call.  Do not assume that it is the first call
 * of this method.
 **/
#pragma mark - NSURLConnection Delegates
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.responseData = [[NSMutableData alloc] init];

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    self.statusCode = httpResponse.statusCode;
    
    
    if (httpResponse.statusCode != 200)
    { // something went wrong, abort the whole thing
        NSLog(@"statusCode != 200, status = %ld", (long)httpResponse.statusCode);
//        [connection cancel];
//        return;
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.hud hideProgressHUD];

    [[QPNetworkActivity sharedInstance] decreaseActivity];

    
    self.response = [self.handler handleResponse:(int)self.statusCode
                                            body:self.responseData];

    if ( [self.response wasSuccessful])
    {
        [self storeUserInformationInAmazonKeyChainWrapper:self.response andUsername:self.userName.text];
        
        [KwikcyAWSRequest userIsActive:[AmazonKeyChainWrapper username]];
        
        
//        NSString *launchedForUser = [NSString stringWithFormat:@"%@%@",
//                                     @"HasLaunchedOnceForUser", [AmazonKeyChainWrapper username]];
//        if (![[NSUserDefaults standardUserDefaults] boolForKey:launchedForUser])
//            
//        {
//            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:launchedForUser];
//            [[NSUserDefaults standardUserDefaults] synchronize];
//        
//        }
        
        [self performSegueWithIdentifier:@"Take Profile Photo" sender:self];
        //[self performSegueWithIdentifier:@"Register and go to Main Page" sender:self];
    

    // authentication failed
    }
    else
    {
        
//        NSLog(@"error: response was not Successful");
//        NSLog(@"code = %d, message = %@", self.response.code, self.response.message);
    
        if (self.response.message == nil)
            self.response.message = @"Try again later";

        dispatch_async(dispatch_get_main_queue(), ^{

            [[Constants alertWithTitle:@"Registration Error" andMessage:self.response.message] show];

            self.userPassword.text = @"";
            self.successButtonForPassword.hidden = YES;
            self.errorMessageForPasswordLabel = @"Password missing";
            [self enableRegisterButton];

        });
    }
}








/**
 * This delegate methodis called if the connection cannot be established to the server.
 * The error object will have a description of the error
 **/
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // post notification
    NSLog(@"Load failed with error %@", [error localizedDescription]);
    self.response =  [[Response alloc] initWithCode:500 andMessage:nil];
    
    [self.hud hideProgressHUD];
    [[QPNetworkActivity sharedInstance] decreaseActivity];
    
    if (self.response.message == nil)
        self.response.message = [NSString stringWithFormat:@"Registration may or may not have worked. Try logging in with username: %@", self.userName.text] ;

    [[Constants alertWithTitle:@"Timed out" andMessage:self.response.message] show];


    self.userPassword.text = @"";
    self.successButtonForPassword.hidden = YES;
    self.errorMessageForPasswordLabel = @"Password missing";
    [self enableRegisterButton];

}


-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSURLProtectionSpace *challengeProtectionSpace = [challenge protectionSpace];
    
    
    NSURLProtectionSpace *safeServerSpace = [[NSURLProtectionSpace alloc] initWithHost:KWIKCY_ENDPOINT
                                                                                  port:443
                                                                              protocol:NSURLProtectionSpaceHTTPS
                                                                                 realm:nil
                                                                  authenticationMethod:NSURLAuthenticationMethodServerTrust];
    
    
    
    NSArray *validSpaces = [NSArray arrayWithObject:safeServerSpace];
    
    if (![validSpaces containsObject:challengeProtectionSpace])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [Constants alertWithTitle:@"Unsecure Connection" andMessage:@"We are unable to establish a secure connection"];
        });
        
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        
    }
    
    
    else if ([challengeProtectionSpace authenticationMethod] == NSURLAuthenticationMethodServerTrust)
    {
        SecTrustRef trust = [challengeProtectionSpace serverTrust];
        
        /***** Make specific changes to the trust policy here. *****/
        
        /* Re-evaluate the trust policy. */
        
        SecTrustResultType secresult = kSecTrustResultInvalid;
        
        
        if (SecTrustEvaluate(trust, &secresult) != errSecSuccess)
        {
            /* Trust evaluation failed. */
            [connection cancel];
            
            // Perform other cleanup here, as needed.
            return;
        }
        
        
        
        switch (secresult)
        {
                
            case kSecTrustResultUnspecified: // The OS trusts this certificate implicitly.
            case kSecTrustResultProceed: // The user explicitly told the OS to trust it.
            {
                NSURLCredential *credential = [NSURLCredential credentialForTrust:[[challenge protectionSpace] serverTrust]];
                [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
                return;
            }
            default:  ;
                //TODO: NOT SECURE
                /* It's somebody else's key. Fall through. */
//                NSLog(@"Not seure");
//                [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
//                
//                [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
//                return;
        }
        
        /* The server sent a key other than the trusted key. */
        [connection cancel];
        
        // Perform other cleanup here, as needed.
        
    }
}





@end
