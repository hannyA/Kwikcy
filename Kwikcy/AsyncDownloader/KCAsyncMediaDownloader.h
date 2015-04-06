//
//  KCAsyncMediaDownloader.h
//  Quickpeck
//
//  Created by Hanny Aly on 1/30/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSRuntime/AWSRuntime.h>

#import "AmazonClientManager.h"
#import "ReceivedMessageImage.h"
#import "AsyncDownloader.h"

@interface KCAsyncMediaDownloader : AsyncDownloader

@property (nonatomic, weak) UIProgressView *progressView;
@property (nonatomic, strong) ReceivedMessageImage *recvMessage;

-(void)updateProgressView:(NSNumber *)theProgress;
-(void)hideProgressView;
-(id)initWithFilepathOfMessage:(ReceivedMessageImage *)recvMessage andProgressView:(UIProgressView *)downloaderProgressView;
-(void)deleteDynamoDBMessageAndImageFromS3Bucket;

@end

