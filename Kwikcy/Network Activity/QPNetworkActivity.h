//
//  QPNetworkActivity.h
//  Quickpeck
//
//  Created by Hanny Aly on 8/18/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QPNetworkActivity : NSObject

+ (QPNetworkActivity *)sharedInstance;


- (void)increaseActivity;
- (void)decreaseActivity;


@end


