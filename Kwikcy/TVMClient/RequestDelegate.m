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

#import "RequestDelegate.h"
#import <AWSRuntime/AWSRuntime.h>

@implementation RequestDelegate



-(id)init
{
    if ((self = [super init])) {
        self.failed       = NO;
        self.done         = NO;
        self.receivedData = [NSMutableData data];
        self.responseBody = nil;
    }
    
    return self;
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"\n\nRequest Delegate ->connection:didReceiveReponse:\n\n");
    [self.receivedData setLength:0];
    NSHTTPURLResponse *httpUrlResponse = (NSHTTPURLResponse *)response;
    if ( [httpUrlResponse statusCode] != 200) {
        self.failed = YES;
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"\n\nRequest Delegate ->connection:didReceiveData:\n\n");

    [self.receivedData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"\n\nRequest Delegate ->connection:didFailWithError:\n\n");
    
    connection = nil;
    
    self.responseBody = [error localizedDescription];
    self.receivedData = nil;
    
    self.failed = YES;
    self.done   = YES;
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"\n\nRequest Delegate ->connectionDidFinishLoading:\n\n");

    connection = nil;
    
    self.responseBody = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
    self.receivedData = nil;
    self.done         = YES;
}


@end

