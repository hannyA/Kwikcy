//
//  QPAsyncVideoDownloader.m
//  Quickpeck
//
//  Created by Hanny Aly on 7/20/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "QPAsyncVideoDownloader.h"

@implementation QPAsyncVideoDownloader


-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    [self performSelectorOnMainThread:@selector(turnOffNetworkworkActivityIndicator) withObject:nil waitUntilDone:NO];
    
    if (!response.error && !response.exception)
    {
        NSLog(@"DATA is here ");
        NSData *data = response.body;
        NSString *path;
       // NSData *data = [NSData dataWithData:response.body];
        if (data)
        {
            NSLog(@"DATA does exist  ");

            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            path = [documentsDirectory stringByAppendingPathComponent:@"myMovie.mp4"];
            [data writeToFile:path atomically:YES];
            NSLog(@"path is %@", path);
        }
        [self.asyncVideoDelegate performSelector:@selector(setVideoForReceivedMessage:) withObject:path];
    }
    
    [self finish];
}



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
    
    [self performSelectorOnMainThread:@selector(initialize) withObject:nil waitUntilDone:NO];
    
    // Puts the file as an object in the bucket.
    S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc] initWithKey:self.filepath withBucket:BUCKET_NAME];
    getObjectRequest.responseHeaderOverrides.contentType =  @"video/quicktime";
    getObjectRequest.delegate = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    });
    
    [[AmazonClientManager s3] getObject:getObjectRequest];
}

@end
