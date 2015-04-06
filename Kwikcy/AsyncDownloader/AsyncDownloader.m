//
//  AsyncDownloader.m
//  Quickpeck
//
//  Created by Hanny Aly on 7/20/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "AsyncDownloader.h"
#import "QPNetworkActivity.h"


@interface AsyncDownloader ()

@property (nonatomic, strong) NSString *bucket;
@property(nonatomic,strong) NSMutableData   *responseData;

@end

@implementation AsyncDownloader



-(id)initWithFilepath:(NSString *)filepath
{
    self = [super init];
    if (self)
    {
        isExecuting  = NO;
        isFinished   = NO;
        
        self.bucket     = BUCKET_NAME;
        self.filepath   = filepath;
    }
    return self;
}

-(id)initWithBucket:(NSString *)bucket andFilepath:(NSString *)filepath
{
    self = [super init];
    if (self)
    {
        isExecuting  = NO;
        isFinished   = NO;
        
        self.bucket     = bucket;
        self.filepath   = filepath;
    }
    return self;
}


#pragma mark - Overwriding NSOperation Methods

/*
 * For concurrent operations, you need to override the following methods:
 * start, isConcurrent, isExecuting and isFinished.
 *didFailWithServiceException
 * Please refer to the NSOperation documentation for more details.
 * http://developer.apple.com/library/ios/#documentation/Cocoa/Reference/NSOperation_class/Reference/Reference.html
 */


-(void)start
{
    // Makes sure that start method always runs on the main thread.
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }

    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    // Puts the file as an object in the bucket.
    S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc] initWithKey:self.filepath withBucket:self.bucket];
    getObjectRequest.delegate = self ;
    //getObjectRequest.responseHeaderOverrides.cacheControl = @"No-cache";
   
    [[QPNetworkActivity sharedInstance] increaseActivity];
    [[AmazonClientManager s3] getObject:getObjectRequest];
}





-(BOOL)isConcurrent
{
    return YES;
}

-(BOOL)isExecuting
{
    return isExecuting;
}

-(BOOL)isFinished
{
    return isFinished;
}


#pragma mark - AmazonServiceRequestDelegate Implementations



-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"photo profile didReceiveResponse");
    self.responseData = [[NSMutableData alloc] init];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    if (httpResponse.statusCode != 200) { // something went wrong, abort the whole thing
        NSLog(@"profile statusCode != 200, %@", response.description);
    }
}



-(void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data
{
    NSLog(@"photo profile didReceiveData");
    [self.responseData appendData:data];

}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    NSLog(@"photo profile didCompleteWithResponse");
    NSLog(@"profile error: %@", response.error);
    [self finish];
}


-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"photo profile didFailWithError: %@", error);
    [self finish];
}






#pragma mark - Helper Methods



-(void)finish
{
    [[QPNetworkActivity sharedInstance] decreaseActivity];

    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    isExecuting = NO;
    isFinished  = YES;
        
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}





@end


