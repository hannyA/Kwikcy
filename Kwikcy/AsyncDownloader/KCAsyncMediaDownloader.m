//
//  KCAsyncMediaDownloader.m
//  Quickpeck
//
//  Created by Hanny Aly on 1/30/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCAsyncMediaDownloader.h"
#import "AmazonKeyChainWrapper.h"
#import "MBProgressHUD.h"
#import "QPNetworkActivity.h"


@interface KCAsyncMediaDownloader ()
@property (nonatomic, strong) NSNumber *expectedContentLength;
@property (nonatomic, strong) NSNumber *currentTotal;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation KCAsyncMediaDownloader


-(id)initWithFilepathOfMessage:(ReceivedMessageImage *)recvMessage andProgressView:(UIProgressView *)downloaderProgressView
{
    self = [super init];
    if (self)
    {
        isExecuting  = NO;
        isFinished   = NO;
        
        self.recvMessage  = recvMessage;
        self.filepath     = [recvMessage getFilePath];
        self.progressView = downloaderProgressView;
        self.timer = [NSTimer timerWithTimeInterval:0.1
                                             target:self
                                           selector:@selector(updateTimerArtificially)
                                           userInfo:nil
                                            repeats:YES];
    }
    return self;
}


-(id)initWithFilepath:(NSString *)filepath
{
    self = [super init];
    if (self)
    {
        isExecuting  = NO;
        isFinished   = NO;
        
        self.filepath = filepath;
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
    
    if (self.progressView)
        [self performSelectorOnMainThread:@selector(initialize) withObject:nil waitUntilDone:NO];
    
    
    NSLog(@"Filepath is %@", self.filepath);
    
    // Puts the file as an object in the bucket.
    S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc] initWithKey:self.filepath withBucket:BUCKET_NAME];
    getObjectRequest.delegate = self ;
    //getObjectRequest.responseHeaderOverrides.cacheControl = @"No-cache";
    
    [[QPNetworkActivity sharedInstance] increaseActivity];
    [[AmazonClientManager s3] getObject:getObjectRequest];
    
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:self.timer forMode:NSDefaultRunLoopMode];
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
    if (response.expectedContentLength == NSURLResponseUnknownLength){
        //TODO: add artifiacl update up to 0.8
        NSLog(@"NSURLResponse UnknownLength for progress update artificially");
        [self hideProgressView];
   
    }
    else
    {
        self.expectedContentLength = [NSNumber numberWithLongLong:response.expectedContentLength];
        NSLog(@"expectedContentLength for progress = %@", self.expectedContentLength);
    }
}



-(void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data
{
    // The progress bar for downlaod is just an estimate. In order to accurately reflect the progress bar, you need to first retrieve the file size.
    
    if (self.expectedContentLength)
    {
        long expectedTotal = [self.expectedContentLength longValue];
        
        long current = [self.currentTotal longValue];
        
        current += [data length];
        self.currentTotal = [NSNumber numberWithLong:current];
        
        float percent = (float)current/ expectedTotal;
        
        if (self.progressView)
            [self performSelectorOnMainThread:@selector(updateProgressView:) withObject:[NSNumber numberWithFloat:percent] waitUntilDone:NO];
        
    }
}



-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    NSLog(@"KCAsyncMediaDownloader didCompleteWithResponse: %@", response);
    
    NSLog(@"KCAsyncMediaDownloader didCompleteWithResponse error : %@", response.error);

    
    [self finish];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"KCAsyncMediaDownloader didFailWithError %@", error);
    [self finish];
}



#pragma mark - Helper Methods



-(void)initialize
{
    NSLog(@"init progress view");
    self.progressView.hidden   = NO;
    self.progressView.progress = 0.0;
}


-(void)updateProgressView:(NSNumber *)theProgress
{
    NSLog(@"update progress view %f", [theProgress floatValue]);
    self.progressView.progress = [theProgress floatValue];
}

-(void)finish
{
    [[QPNetworkActivity sharedInstance] decreaseActivity];

    if([self.timer isValid])
        [self.timer invalidate];

    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    isExecuting = NO;
    isFinished  = YES;
    
    [self hideProgressView];
    [self removeHUD];
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

-(void)hideProgressView
{
    self.progressView.hidden = YES;
}


// Performed in QPAsyncImageDownloader
//-(void)updateTimerArtificially
//{
//    NSLog(@"updateTimerArtificially 1");
//    if (self.progressView.progress < 0.5)
//        self.progressView.progress += 0.05;
//
//}

//Used by subclass QPAsyncImageDownloader
-(void)removeHUD
{
    
}



-(void)deleteDynamoDBMessageAndImageFromS3Bucket
{
    NSLog(@"deleteDynamoDBMessageAndImageFromS3Bucket");
    
    NSString *hashKey = [AmazonKeyChainWrapper username];
    NSString *rangeKey = [self.recvMessage getDateSender];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
        attributeDictionary[INBOX_HASH_KEY_RECEIVER]  = [[DynamoDBAttributeValue alloc] initWithS:hashKey];
        attributeDictionary[INBOX_RANGE_KEY_FILEPATH] = [[DynamoDBAttributeValue alloc] initWithS:rangeKey];
        
        DynamoDBDeleteItemRequest * dynamoDBDeleteRequest = [[DynamoDBDeleteItemRequest alloc] initWithTableName:INBOX_TABLE
                                                                                                          andKey:attributeDictionary];
        
        [[QPNetworkActivity sharedInstance] increaseActivity];
        DynamoDBDeleteItemResponse * dynamoDBDeleteResponse = [[AmazonClientManager ddb] deleteItem:dynamoDBDeleteRequest];
        [[QPNetworkActivity sharedInstance] decreaseActivity];

        if (dynamoDBDeleteResponse.error)
        {
            NSLog(@"KCAsyncMediaDownloader.m deleteDynamoDBMessageAndImageFromS3Bucket Error: %@", dynamoDBDeleteResponse.error);
        }
    });
    
    
        /* Delete objects from S3 next */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *filepath = self.filepath;
        
        [[QPNetworkActivity sharedInstance] increaseActivity];
        S3DeleteObjectResponse *s3DeleteResponse = [[AmazonClientManager s3] deleteObjectWithKey:filepath withBucket:BUCKET_NAME];
        [[QPNetworkActivity sharedInstance] decreaseActivity];

        if (s3DeleteResponse.error)
        {
            NSLog(@"Error deleteDynamoDBMessageAndImageFromS3Bucket deleteing objects");
        }
        
    });
}



@end


