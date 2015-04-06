//
//  QPCoreDataManager.m
//  Quickpeck
//
//  Created by Hanny Aly on 8/20/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "QPCoreDataManager.h"

@implementation QPCoreDataManager

@synthesize managedObjectContext = _managedObjectContext;

static QPCoreDataManager *_sharedInstance = nil;

+ (QPCoreDataManager *)sharedInstance
{
    @synchronized([self class])
    {
        if(_sharedInstance == nil)
        {
            _sharedInstance = [QPCoreDataManager new];
        }
    }
    
    return _sharedInstance;
}







@end
