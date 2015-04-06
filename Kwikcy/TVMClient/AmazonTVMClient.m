/*
 * Copyright 2010-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "AmazonTVMClient.h"
#import "AmazonKeyChainWrapper.h"
#import <AWSRuntime/AWSRuntime.h>

#import "RequestDelegate.h"

#import "GetTokenResponseHandler.h"
#import "GetTokenRequest.h"
#import "GetTokenResponse.h"

#import "LoginResponseHandler.h"
#import "LoginRequest.h"
#import "LoginResponse.h"

#import "RegisterRequest.h"

#import "LogoutRequest.h"

#import "Crypto.h"



@interface AmazonTVMClient ()

@property (strong) NSURLConnection *conn;

@end
@implementation AmazonTVMClient

@synthesize endpoint = _endpoint;
@synthesize appName = _appName;
@synthesize useSSL = _useSSL;


/* The endpoint here is the TOKEN_VENDING_MACHINE URL */
-(id)initWithEndpoint:(NSString *)theEndpoint andAppName:(NSString *)theAppName useSSL:(bool)usingSSL;
{
    self = [super init];
    if (self) {
        self.endpoint = [self getEndpointDomain:[theEndpoint lowercaseString]];
        self.appName  = [theAppName lowercaseString];
        self.useSSL   = usingSSL;
    }

    return self;
}



-(Response *)getToken
{
    NSLog(@"getToken request called");
    NSString  *username = [AmazonKeyChainWrapper username];
//    NSString       *uid = [AmazonKeyChainWrapper getUidForDevice];
    NSString       *key = [AmazonKeyChainWrapper getKeyForDevice];

//    if (!username || !uid || !key)
//            return [[GetTokenResponse alloc] initWithCode:401 andMessage:@"Logged out"];
    if (!username || !key)
        return [[GetTokenResponse alloc] initWithCode:401 andMessage:@"Logged out"];
    
//    Request          *request = [[GetTokenRequest alloc] initWithEndpoint:self.endpoint andUsername:username andUid:uid andKey:key usingSSL:self.useSSL];

    Request          *request = [[GetTokenRequest alloc] initWithEndpoint:self.endpoint andUsername:username andKey:key usingSSL:self.useSSL];
    ResponseHandler  *handler = [[GetTokenResponseHandler alloc] initWithKey:key];

    GetTokenResponse *response = (GetTokenResponse *)[self processRequest:request responseHandler:handler];

    if ( [response wasSuccessful])
    {
        NSLog(@"getToken request called %@", response);

        NSLog(@"getToken accessKey      : %@", response.accessKey);
        NSLog(@"getToken secretKey      : %@", response.secretKey);
        NSLog(@"getToken securityToken  : %@", response.securityToken);
        NSLog(@"getToken expirationDate : %@", response.expirationDate);

        [AmazonKeyChainWrapper storeCredentialsInKeyChain:response.accessKey
                                                secretKey:response.secretKey
                                            securityToken:response.securityToken
                                               expiration:response.expirationDate];
    }
    else {
        AMZLogDebug(@"Token Vending Machine responded with Code: [%d] and Messgae: [%@]", response.code, response.message);
    }

    return response;
}





-(Response *)logoutDevice:(NSString *)deviceID withUserName:(NSString *)username andPassword:(NSString *)thePassword
{
    Response *response = [[Response alloc] initWithCode:200 andMessage:@"OK"];

    LogoutRequest    *request = [[LogoutRequest alloc] initWithEndpoint:self.endpoint andUsername:username andPassword:thePassword andAppName:self.appName usingSSL:self.useSSL];
    
                                 
    ResponseHandler *handler = [[ResponseHandler alloc] init];
    
    response = [self processRequest:request responseHandler:handler];
    
    
    if ( [response wasSuccessful]) {
        
        NSLog(@"\n AmazonTVMClient logoutDevice success" );
        
    }
    else {
        NSLog(@"AmazonTVMClient logoutDevice  failed: Token Vending Machine responded with Code: [%d] and Message: [%@]", response.code, response.message);
    }
    
    return response;    
}







-(Response *)login:(NSString *)username password:(NSString *)password
{
    Response *response = [[Response alloc] initWithCode:200 andMessage:@"OK"];
        
    LoginRequest    *request = [[LoginRequest alloc] initWithEndpoint:self.endpoint andUsername:username andPassword:password andAppName:self.appName usingSSL:self.useSSL];
    
    ResponseHandler *handler = [[LoginResponseHandler alloc] initWithKey:request.decryptionKey];
    
    response = [self processRequest:request responseHandler:handler];
    
    
    NSLog(@"\n\nAmazonTVMCLient.m login: response code = %d\n\n", response.code);
    

    if ( [response wasSuccessful]) {
        [self storeUserInformationInAmazonKeyChainWrapper:response andUsername:username];
    }
    else {
        NSLog(@"Token Vending Machine responded with Code: [%d] and Message: [%@]", response.code, response.message);
    }
    

    return response;
}



//should be register and login
// 1) Lets register from here, then 2) we'll try register and login? then 3) post the register and login

-(Response *)registerWithUsername:(NSString *)username password:(NSString *)password realName:(NSString *)realName email:(NSString *)email mobile:(NSString *)mobile
{
    Response *response = [[Response alloc] initWithCode:200 andMessage:@"OK"];
    
    RegisterRequest *request = [[RegisterRequest alloc] initWithEndpoint:self.endpoint andUsername:username andPassword:password andRealName:realName andEmail:email andMobile:mobile andAppName:self.appName usingSSL:self.useSSL];
    ResponseHandler *handler = [[LoginResponseHandler alloc] initWithKey:request.decryptionKey];
   
    response = [self processRequest:request responseHandler:handler];
    
    
    NSLog(@"\n\nAmazonTVMCLient.m HAC_Register: Respose code = %d\n\n", response.code);


    if ( [response wasSuccessful]) {
        [self storeUserInformationInAmazonKeyChainWrapper:response andUsername:username];
    }
    else {
        NSLog(@"Token Vending Machine responded with Code: [%d] and Messgae: [%@]", response.code, response.message);
    }
    
    return response;
}



-(void)storeUserInformationInAmazonKeyChainWrapper:(Response *)response andUsername:(NSString *)username
{
    [AmazonKeyChainWrapper registerKey:((LoginResponse *)response).key];
//    [AmazonKeyChainWrapper registerDeviceId:((LoginResponse *)response).uid andKey:((LoginResponse *)response).key];
    [AmazonKeyChainWrapper storeUsername:username];
    [AmazonKeyChainWrapper storeCredentialsInKeyChain:((LoginResponse *)response).accessKey
                                            secretKey:((LoginResponse *)response).secretKey
                                        securityToken:((LoginResponse *)response).securityToken
                                           expiration:((LoginResponse *)response).expirationDate];
}



//
//
//- (void) startWithRequest:(NSMutableURLRequest*)request
//{
//    NSLog(@"Starting to download %@");
//    
//    // create the URL
//    NSURL *url = [NSURL URLWithString:srcURL];
//    
//    // Create the request
//    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    
//    // create the connection with the target request and this class as the delegate
//    self.conn =
//    [NSURLConnection connectionWithRequest:request
//                                  delegate:self];
//    
//    // start the connection
//    [self.conn start];
//}
//






// Not usng this I believe
-(Response *)processRequest:(Request *)request responseHandler:(ResponseHandler *)handler
{
    NSLog(@"\n\nAmazonTVMCLient.m processRequest:\n\n");
    
//    RequestDelegate   *delegate = [[RequestDelegate alloc] init];


    NSURL *url = [NSURL URLWithString:[request getUrl]];

    NSLog(@"url is %@ ", [url absoluteString]);
    // set up the request
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                          timeoutInterval:20.0];
    
    NSString *usersRequestString = [request buildRequestPostString];
    NSData *usersEncodedData = [usersRequestString dataUsingEncoding:NSUTF8StringEncoding];
    
    [theRequest setHTTPMethod:@"POST"];
    
    [theRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[usersEncodedData length]]
      forHTTPHeaderField:@"Content-Length"];
    
    [theRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
   
    [theRequest setHTTPBody:usersEncodedData];
    
    
    
    
    // create the connection with the target request and this class as the delegate
    self.conn = [NSURLConnection connectionWithRequest:theRequest
                                              delegate:self];
    // start the connection
    [self.conn start];
    
    return  nil;
    
    
    
    
//    NSError           *error    = nil;
//    NSHTTPURLResponse *response = nil;
//    NSData *data = [NSURLConnection sendSynchronousRequest:theRequest
//                                         returningResponse:&response
//                                                     error:&error];
//    
//    NSLog(@"Response http headers = %@\n\n", [response allHeaderFields]);
//    
//    if (!error)
//        return [handler handleResponse:response.statusCode body:[[NSString alloc] initWithData:data
//                                                                                       encoding:NSUTF8StringEncoding]];
//    
//   
//    NSLog(@"\nAmazonTVMCLient.m processRequest: Error exists\n\n");
//    return [[Response alloc] initWithCode:500
//                                andMessage:delegate.responseBody];
}



/**
 * This delegate methodis called if the connection cannot be established to the server.
 * The error object will have a description of the error
 **/
- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    NSLog(@"Load failed with error %@", [error localizedDescription]);
    NSLog(@"\nAmazonTVMCLient.m processRequest: Error exists\n\n");
}



/**
 * This delegate method is called when the NSURLConnection connects to the server.  It contains the
 * NSURLResponse object with the headers returned by the server.  This method may be called multiple times.
 * Therefore, it is important to reset the data on each call.  Do not assume that it is the first call
 * of this method.
 **/
- (void) connection:(NSURLConnection *)connection
 didReceiveResponse:(NSURLResponse *)response {
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    if (httpResponse.statusCode != 200) { // something went wrong, abort the whole thing
        [connection cancel];
        return;
    }
}


-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge

{
   // NSLog(@"willSendRequestForAuthenticationChallenge called");
}




/*


-(Response *)processRequest:(Request *)request responseHandler:(ResponseHandler *)handler
{
    NSLog(@"\n\nAmazonTVMCLient.m processRequest:\n\n");
    
    RequestDelegate   *delegate = [[RequestDelegate alloc] init];
    
    
    // Set up the NSUrl and post data
    //    NSURL *url = [[NSURL alloc] initWithString:[request buildRequestUrl]];
    
    NSURL *url = [NSURL URLWithString:[request getUrl]];
    
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                          timeoutInterval:20.0];
    
    NSString *usersRequestString = [request buildRequestPostString];
    NSData *usersEncodedData = [usersRequestString dataUsingEncoding:NSUTF8StringEncoding];
    
    [theRequest setHTTPMethod:@"POST"];
    
    [theRequest setValue:[NSString stringWithFormat:@"%d", [usersEncodedData length]]
      forHTTPHeaderField:@"Content-Length"];
    
    [theRequest setValue:@"application/x-www-form-urlencoded"
      forHTTPHeaderField:@"Content-Type"];
    
    [theRequest setHTTPBody:usersEncodedData];
    
    
    NSError           *error    = nil;
    NSHTTPURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:theRequest
                                         returningResponse:&response
                                                     error:&error];
    
    NSLog(@"Response http headers = %@\n\n", [response allHeaderFields]);
    
    if (!error)
        return [handler handleResponse:response.statusCode body:[[NSString alloc] initWithData:data
                                                                                      encoding:NSUTF8StringEncoding]];
    
    
    NSLog(@"\nAmazonTVMCLient.m processRequest: Error exists\n\n");
    return [[Response alloc] initWithCode:500
                               andMessage:delegate.responseBody];
}
*/
-(NSString *)getEndpointDomain:(NSString *)originalEndpoint
{
    NSRange endpointRange;

    if ( [originalEndpoint hasPrefix:@"http://"] || [originalEndpoint hasPrefix:@"https://"]) {
        NSRange startOfDomain = [originalEndpoint rangeOfString:@"://"];
        endpointRange.location = startOfDomain.location + 3;
    }
    else {
        endpointRange.location = 0;
    }

    if ( [originalEndpoint hasSuffix:@"/"]) {
        endpointRange.length = ([originalEndpoint length] - 1) - endpointRange.location;
    }
    else {
        endpointRange.length = [originalEndpoint length] - endpointRange.location;
    }

    return [originalEndpoint substringWithRange:endpointRange];
}

@end
