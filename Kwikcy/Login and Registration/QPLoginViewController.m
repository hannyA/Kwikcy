//
//  QPLoginViewController.m
//  For Your Eyes
//
//  Created by Hanny Aly on 7/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QPLoginViewController.h"
#import "Constants.h"
#import "MBProgressHUD.h"
#import "Response.h"
#import "AmazonClientManager.h"
#import "AmazonKeyChainWrapper.h"

#import <CommonCrypto/CommonDigest.h>
#import <QuartzCore/QuartzCore.h>

#import "QPNetworkActivity.h"
#import "NSString+validate.h"

#import "LoginRequest.h"
#import "LoginResponseHandler.h"
#import "LoginResponse.h"
#import "QPCoreDataManager.h"
#import "User+methods.h"

#import "KwikcyAWSRequest.h"

@interface QPLoginViewController ()<UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *userName;
@property (nonatomic, weak) IBOutlet UITextField *userPassword;
@property (nonatomic, strong) MBProgressHUD *hud;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *allButtons;

@property(nonatomic,strong) ResponseHandler   *handler;

@property (strong, nonatomic) NSURLConnection *conn;
@property (strong, nonatomic) Response *response;

@property(nonatomic) NSInteger       statusCode;
@property(nonatomic,strong) NSMutableData   *responseData;

@end



@implementation QPLoginViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
//    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    for (UIButton *button in self.allButtons) {
         [button setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    }

    [self.navigationController.navigationBar setHidden:YES];
    
    //Indent the left side. adds a clear View in text field
    self.userName.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
    self.userName.leftViewMode = UITextFieldViewModeAlways;
    
    self.userPassword.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
    self.userPassword.leftViewMode = UITextFieldViewModeAlways;
}

-(BOOL)prefersStatusBarHidden
{
    return NO;
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];

    [AmazonClientManager wipeAllCredentials];
    [AmazonKeyChainWrapper wipeKeyChain];
    
    [self clearTextFields];
    
   
    //Add to other tabbar controllers
    if ([AmazonClientManager isLoggedIn]) {
        NSLog(@"AmazonClientManager isLoggedIn");
        Response *response = [AmazonClientManager validateCredentials];
        if (![response wasSuccessful]) {
            [[Constants errorAlert:response.message] show];
             
            // clear Key Chain Wrraper credentials?
            
        }
        else{
            [self performSegueWithIdentifier:@"Login to Main Page" sender:nil];
            return;
        }
    }
    else {
        [AmazonClientManager wipeAllCredentials];
        [AmazonKeyChainWrapper wipeKeyChain];
    }
}


-(void)viewDidDisappear:(BOOL)animated
{
    [self.hud hideProgressHUD];
}

-(void)showHUDWithMessageSynch:(NSString *)message
{
    self.hud = [MBProgressHUD getAndShowUniversalHUD:self.view withText:message animated:YES];
}

-(void)showHUDWithMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hud = [MBProgressHUD getAndShowUniversalHUD:self.view withText:message animated:YES];
    });
}



-(void)clearTextFields
{
    self.userName.text = @"";
    self.userPassword.text = @"";
}

- (IBAction)removeKeyboard
{
    [self.userName resignFirstResponder];
    [self.userPassword resignFirstResponder];
}



-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([self.userPassword isEqual:textField])
        textField.text = @"";
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if( [textField isEqual:self.userName])
    {
        [self.userPassword becomeFirstResponder];
    }
    else
    {
        [self.userPassword resignFirstResponder];
        [self login:nil];
    }
    return YES;
}



-(BOOL)userNameAndPasswordIsValid
{

    if (self.userName.text.length < 1){
        [self.userName becomeFirstResponder];
        self.userPassword.text = @"";
        [[Constants alertWithTitle:nil andMessage:@"Enter your username"] show];
        return NO;
    }
    if (self.userPassword.text.length < 1){
        [self.userPassword becomeFirstResponder];
        self.userPassword.text = @"";
        [[Constants alertWithTitle:nil andMessage:@"Enter your password"] show];
        return NO;
    }
    if (self.userName.text.length < 3 || self.userName.text.length > 32 || self.userPassword.text.length < 6 || self.userPassword.text.length > 32 ){
        [[Constants errorAlert:@"Incorrect Username/Password combination "] show];
        [self.userName becomeFirstResponder];
        self.userPassword.text = @"";
        return NO;
    }
    if (![NSString validateUserName:self.userName.text])
    {
        [[Constants errorAlert:@"Incorrect Username/Password combination "] show];
        [self.userName becomeFirstResponder];
        self.userPassword.text = @"";
        return NO;
    }
    return YES;
}



-(IBAction)login:(id)sender
{
    [self removeKeyboard];
  
    if (![self userNameAndPasswordIsValid])
        return;
    
    
    LoginRequest * loginRequest = [[LoginRequest alloc] initWithEndpoint:[LoginRequest endpoint] andUsername:[self.userName.text lowercaseString] andPassword:self.userPassword.text andAppName:[LoginRequest appName] usingSSL:[LoginRequest useSSL]];
                       
                                     
    
    
    self.handler = [[LoginResponseHandler alloc] initWithKey:loginRequest.decryptionKey];
    
    
    
    NSURL *url = [NSURL URLWithString:[loginRequest getUrl]];
    
    // set up the request
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                          timeoutInterval:20.0];
    
    NSString *usersRequestString = [loginRequest buildRequestUrl];
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

    [self showHUDWithMessageSynch:@"Signing in"];

    
    
//    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
//        [self showHUDWithMessage:@"Signing in"];
//    });

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
    
    
    if (httpResponse.statusCode != 200) { // something went wrong, abort the whole thing
        NSLog(@"statusCode != 200");
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
        [self storeUserInformationInAmazonKeyChainWrapper:self.response
                                              andUsername:self.userName.text];
        
        [KwikcyAWSRequest userIsActive:[AmazonKeyChainWrapper username]];
        
        
        if ( ((LoginResponse *)self.response).hasProfilePhoto)
        {
            [self performSegueWithIdentifier:@"Login to Main Page" sender:self];
        }
        else
        {
            [self performSegueWithIdentifier:@"Take Profile Photo" sender:self];
        }
        
        
        
    // authentication failed
    }
    else
    {
        if (self.response.message == nil)
        {
            self.response.message = @"Please try again later";
        }
        else
        {
            NSLog(@"message is %@", self.response.message);
            NSLog(@"error 2");
        }
        
        [[Constants alertWithTitle:@"Login failed" andMessage:self.response.message] show];
        self.userPassword.text = @"";
        [self.userPassword becomeFirstResponder];
    }
}




/**
 * This delegate methodis called if the connection cannot be established to the server.
 * The error object will have a description of the error
 **/
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // post notification
    NSLog(@"didFailWithError");
    NSLog(@"Load failed with error %@", [error localizedDescription]);
    self.response =  [[Response alloc] initWithCode:500 andMessage:nil];
    
    [self.hud hideProgressHUD];
    [[QPNetworkActivity sharedInstance] decreaseActivity];
    
    if (self.response.message == nil)
        self.response.message = @"Try again later";
    
    self.userPassword.text = @"";
    [[Constants alertWithTitle:@"Connection Error" andMessage:self.response.message] show];
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
                NSLog(@"kSecTrustResultUnspecified");

            case kSecTrustResultProceed: // The user explicitly told the OS to trust it.
            {
                NSLog(@"credentialForTrust:challenge.protectionSpace.serverTrust");
                
                NSURLCredential *credential = [NSURLCredential credentialForTrust:[[challenge protectionSpace] serverTrust]];
                [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
                return;
            }
            default: ;
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






























//-(UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier
//{
//    NSLog(@"This is called");
//}

-(IBAction)logOutFromTC:(UIStoryboardSegue *)segue
{
//    [segue  ];
    NSLog(@"logOutFromTC");

    OSStatus keychainWipeSuccess = [AmazonClientManager wipeAllCredentials];
    
    [AmazonKeyChainWrapper wipeKeyChain];
    NSLog(@"logOutFromTC complete");

    
//    if (keychainWipeSuccess != errSecSuccess)
//    {
//        [[Constants alertWithTitle:@"Error" andMessage:@"Could not delete credentials from phone"] show];
//    }
//    else
//    {
//        [[Constants alertWithTitle:@"Logged out" andMessage:@"Good bye"] show];
//
//    }
}


//    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];


    //    NSString *deviceID = [AmazonKeyChainWrapper getUidForDevice];
    //    NSString *username = [AmazonKeyChainWrapper username];
    //    NSString *password = [AmazonKeyChainWrapper password];
    //
    //    OSStatus keychainWipeSuccess = [AmazonClientManager wipeAllCredentials];
    //    if (keychainWipeSuccess == errSecSuccess){
    //        Response *response = [AmazonClientManager logoutDevice:deviceID withUserName:username andPassword:thePassword];
    //    }

    //    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];




//-(void)logOutFromTC
//{
//    NSString *deviceID = [AmazonKeyChainWrapper getUidForDevice];
//    
////    [self deleteTokenFromDynamoDBForDevice:deviceID];
//    
//    [AmazonClientManager wipeAllCredentials];
//    [AmazonKeyChainWrapper wipeKeyChain];
//    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

    
    //    NSString *deviceID = [AmazonKeyChainWrapper getUidForDevice];
    //    NSString *username = [AmazonKeyChainWrapper username];
    //    NSString *password = [AmazonKeyChainWrapper password];
    //
    //    OSStatus keychainWipeSuccess = [AmazonClientManager wipeAllCredentials];
    //    if (keychainWipeSuccess == errSecSuccess){
    //        Response *response = [AmazonClientManager logoutDevice:deviceID withUserName:username andPassword:thePassword];
    //    }
    
    //    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
//}


//-(void)deleteTokenFromDynamoDBForDevice:(NSString *)deviceID
//{
//    NSString *hashKey = deviceID;
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        
//        
//        NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
//        
//        [attributeDictionary setObject:[[DynamoDBAttributeValue alloc] initWithS:hashKey] forKey:@"deviceid"];
//        
//        DynamoDBDeleteItemRequest * dynamoDBDeleteRequest = [[DynamoDBDeleteItemRequest alloc] initWithTableName:QPDEVICE_TABLE andKey:attributeDictionary];
//        
//        [[QPNetworkActivity sharedInstance] increaseActivity];
//        
//        DynamoDBDeleteItemResponse * dynamoDBDeleteResponse = [[AmazonClientManager ddb] deleteItem:dynamoDBDeleteRequest];
//        [[QPNetworkActivity sharedInstance] decreaseActivity];
//        
//        if (dynamoDBDeleteResponse.error || dynamoDBDeleteResponse.exception)
//        {
//            NSLog(@"AsyncDownloader.m deleteDynamoDBMessageAndImageFromS3Bucket Error: %@", dynamoDBDeleteResponse.error);
//        }
//    });
//}



//-(IBAction)loggedOut:(UIStoryboardSegue *)segue
//{
//    [AmazonClientManager wipeAllCredentials];
//    [AmazonKeyChainWrapper wipeKeyChain];
//}
//
//-(IBAction)logOutFromTC:(UIStoryboardSegue *)segue
//{
//    NSString *deviceID = [AmazonKeyChainWrapper getUidForDevice];
//    
//    [self deleteTokenFromDynamoDBForDevice:deviceID];
//    
//    [AmazonClientManager wipeAllCredentials];
//    [AmazonKeyChainWrapper wipeKeyChain];
//    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
//    
//    
//    //    NSString *deviceID = [AmazonKeyChainWrapper getUidForDevice];
//    //    NSString *username = [AmazonKeyChainWrapper username];
//    //    NSString *password = [AmazonKeyChainWrapper password];
//    //
//    //    OSStatus keychainWipeSuccess = [AmazonClientManager wipeAllCredentials];
//    //    if (keychainWipeSuccess == errSecSuccess){
//    //        Response *response = [AmazonClientManager logoutDevice:deviceID withUserName:username andPassword:thePassword];
//    //    }
//    
//    //    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
//}


//-(void)deleteTokenFromDynamoDBForDevice:(NSString *)deviceID
//{
//    NSString *hashKey = deviceID;
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        
//        @try {
//            [[QPNetworkActivity sharedInstance] increaseActivity];
//            
//            NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
//            
//            [attributeDictionary setObject:[[DynamoDBAttributeValue alloc] initWithS:hashKey] forKey:@"deviceid"];
//            
//            DynamoDBDeleteItemRequest * dynamoDBDeleteRequest = [[DynamoDBDeleteItemRequest alloc] initWithTableName:QPDEVICE_TABLE andKey:attributeDictionary];
//            DynamoDBDeleteItemResponse * dynamoDBDeleteResponse = [[AmazonClientManager ddb] deleteItem:dynamoDBDeleteRequest];
//            
//            if (dynamoDBDeleteResponse.error || dynamoDBDeleteResponse.exception)
//            {
//                NSLog(@"AsyncDownloader.m deleteDynamoDBMessageAndImageFromS3Bucket Error: %@", dynamoDBDeleteResponse.error);
//            }
//        }
//        @catch (NSException *exception) {
//            NSLog(@"AsyncDownloader.m deleteDynamoDBMessageAndImageFromS3Bucket exception");
//        }
//        @finally {
//            [[QPNetworkActivity sharedInstance] increaseActivity];
//            
//        }
//    });
//}



@end
