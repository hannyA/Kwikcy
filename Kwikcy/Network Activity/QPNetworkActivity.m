//
//  QPNetworkActivity.m
//  Quickpeck
//
//  Created by Hanny Aly on 8/18/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "QPNetworkActivity.h"


@interface QPNetworkActivity()

@property (nonatomic) NSInteger count;

@end

@implementation QPNetworkActivity


+ (QPNetworkActivity *)sharedInstance
{

    static QPNetworkActivity *sharedInstance;

    @synchronized(self)
    {
        if(!sharedInstance)
        {
            sharedInstance = [QPNetworkActivity new];
        }
    }
    return sharedInstance;
}

-(void)increaseActivity
{
    @synchronized([self class])
    {
        self.count++;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

//        
//        if (![[UIApplication sharedApplication] isNetworkActivityIndicatorVisible])
//            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
//    NSLog(@"QPNetworkActivity increaseActivity count is %d", self.count);

}

-(void)decreaseActivity
{
    @synchronized([self class])
    {
        self.count--;
//        self.count = (self.count < 0) ? 0: self.count;
        if (self.count < 0)
            self.count = 0;
        
        if (self.count == 0)
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    }
//    NSLog(@"QPNetworkActivity decreaseActivity count is %d", self.count);
}


@end
