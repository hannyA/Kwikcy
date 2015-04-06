//
//  KCKwikcyClient.m
//  Quickpeck
//
//  Created by Hanny Aly on 3/25/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCKwikcyClient.h"
#import "Response.h"
#import "KCServerRequest.h"
#import "KCServerResponseHandler.h"
#import "Constants.h"

#import "QPNetworkActivity.h"

@interface KCKwikcyClient ()


@property (strong, nonatomic) NSURLConnection *conn;
@property (strong, nonatomic) Response *response;

@property(nonatomic) NSInteger       statusCode;
@property(nonatomic,strong) NSMutableData   *responseData;
@property(nonatomic,strong) KCServerResponseHandler   *handler;

@property (nonatomic, strong) void(^completionHandler)(BOOL success, Response* response, NSError *error);

@end
@implementation KCKwikcyClient

//void(^_completionHandler)(BOOL success, Response* response, NSError *error);

/*
 * KCCompletionBlock = void(^)(BOOL, Response*, NSError*)
 */
-(void)sendRequestWithParameters:(NSMutableDictionary *)parameters withCompletionHandler:(KCCompletionBlock)handlerBlock
{
    NSLog(@"sendRequestWithParameters called for command: %@", parameters[COMMAND]);
    
    self.completionHandler = handlerBlock;
    
    self.conn = nil;
    self.response = nil;
    self.statusCode = 0;
    self.responseData = nil;
    self.handler = nil;

    
    KCServerRequest *request = [[KCServerRequest alloc] initWithParameters:parameters];
    
    self.handler = [[KCServerResponseHandler alloc] initWithKey:request.decryptionKey
                                                      andComand:parameters[COMMAND]];
    
        
    NSURL *url = [NSURL URLWithString:[request getUrl]];
        
    // set up the request
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                          timeoutInterval:20.0];
    

    
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [theRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [theRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[request.finalBody length]]
      forHTTPHeaderField:@"Content-Length"];
    [theRequest setHTTPBody:request.finalBody];
    
    
    // create the connection with the target request and this class as the delegate
    self.conn = [NSURLConnection  connectionWithRequest:theRequest
                                              delegate:self];
    // start the connection
    [[QPNetworkActivity sharedInstance] increaseActivity];

    [self.conn start];
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
//    NSLog(@"All headers = %@", [httpResponse allHeaderFields]);
    
    self.statusCode = httpResponse.statusCode;
//    NSLog(@"statusCode = %d", self.statusCode);

    // something went wrong, abort the whole thing
    if (httpResponse.statusCode != 200)
    {
        [connection cancel];
        [[QPNetworkActivity sharedInstance] decreaseActivity];

        self.response = [self.handler handleResponse:self.statusCode
                                                body:self.responseData];
        [self callbackWithFailedResponse:self.response];
    }    
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[QPNetworkActivity sharedInstance] decreaseActivity];

    self.response = [self.handler handleResponse:self.statusCode
                                            body:self.responseData];
    
    if ( [self.response wasSuccessful])
    {
        [self callbackWithSuccessfulResponse:self.response];
        
        // authentication failed
    }
    else
    {        
        [self callbackWithFailedResponse:self.response];
    }
}






/**
 * This delegate methodis called if the connection cannot be established to the server.
 * The error object will have a description of the error
 **/
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{    
    [[QPNetworkActivity sharedInstance] decreaseActivity];

    
//    NSLog(@"Load failed with error %@", [error localizedDescription]);
    self.response =  [[Response alloc] initWithCode:500 andMessage:nil];
    
    if (self.response.message == nil)
        self.response.message = @"Please try again later";
    
    [self callbackWithError:error];
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
//                NSLog(@"credentialForTrust:challenge.protectionSpace.serverTrust");
                
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



// If an actual error occured in network
-(void)callbackWithError:(NSError *)error
{
//    NSLog(@"callbackWithError");
    BOOL success = YES;
    Response* response;
    
    self.completionHandler(success, response, error);
}

// Responds with non 200 reponse
-(void)callbackWithFailedResponse:(Response *)response
{
//    NSLog(@"callbackWithFailedResponse");
    BOOL success = NO;
    NSError *error;
    
    self.completionHandler(success, response, error);
}

// Responds with 200 reponse
-(void)callbackWithSuccessfulResponse:(Response *)response
{
//    NSLog(@"callbackWithSuccessfulResponse");
    BOOL success = YES;
    NSError *error;
    
    self.completionHandler(success, response, error);
}



@end
