//
//  AsyncDownloader.h
//  Quickpeck
//
//  Created by Hanny Aly on 7/20/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//


/* 
 * This is more of an Abstract class
 * Subclasses return data through didCompleteWithResponse
 */

#import <Foundation/Foundation.h>
#import <AWSRuntime/AWSRuntime.h>

#import "AmazonClientManager.h"

@interface AsyncDownloader : NSOperation<AmazonServiceRequestDelegate>
{
    BOOL isExecuting;
    BOOL isFinished;
}
//@property (nonatomic, readonly)  BOOL           isExecuting;
//@property (nonatomic, readonly)  BOOL           isFinished;
@property (strong, nonatomic) NSString *filepath;

-(void)finish;
-(id)initWithBucket:(NSString *)bucket andFilepath:(NSString *)filepath;
-(id)initWithFilepath:(NSString *)filepath;


@end
 