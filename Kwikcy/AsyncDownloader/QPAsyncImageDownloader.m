//
//  QPAsyncImageDownloader.m
//  Quickpeck
//
//  Created by Hanny Aly on 7/20/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "QPAsyncImageDownloader.h"

@interface QPAsyncImageDownloader ()

//@property (nonatomic, strong) NSTimer *timer;
@end
@implementation QPAsyncImageDownloader


-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    NSLog(@"QPAsyncImageDownloader.h didCompleteWithResponse");
        
    if (!response.error)
    {
        NSLog(@"QPAsyncImageDownloader no error");

        [self deleteDynamoDBMessageAndImageFromS3Bucket];
        NSData *data = response.body;
        [self.asyncImageDelegate performSelector:@selector(setImagesData:forReceivedMessage:) withObject:data withObject:self.recvMessage];
    }
    else
    {
        NSLog(@"QPAsyncImageDownloader error: error");
    }
    
    [self finish];
}

-(void)updateTimerArtificially
{
    if (self.progressView.progress < 0.5)
        self.progressView.progress += 0.05;
}



-(void)removeHUD
{ 
    [self.asyncImageDelegate performSelector:@selector(hideProgressHUD) withObject:nil];
}

@end
