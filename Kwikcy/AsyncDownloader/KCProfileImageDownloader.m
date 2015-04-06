//
//  KCProfileImageDownloader.m
//  Quickpeck
//
//  Created by Hanny Aly on 1/30/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCProfileImageDownloader.h"

@implementation KCProfileImageDownloader

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    NSData *data;
    NSLog(@"KCProfileImageDownloader.h didCompleteWithResponse");
    if (!response.error)
    {
        data = response.body;
    }
    [self.asyncImageDelegate performSelector:@selector(setImagesData:) withObject:data];

    [self finish];
}

@end
