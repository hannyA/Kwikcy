//
//  ReceivedMessageVideo.m
//  Quickpeck
//
//  Created by Hanny Aly on 7/18/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "ReceivedMessageVideo.h"

@interface ReceivedMessageVideo ()
@property (nonatomic, strong) Received_message *message;

@end

@implementation ReceivedMessageVideo

-(ReceivedMessageVideo *)initWithReceived_message:(Received_message *)message
{
    self = [super init];
    if (self)
    {
        self.message = message;
    }
    return self;
}
@end
