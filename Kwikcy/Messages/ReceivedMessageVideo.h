//
//  ReceivedMessageVideo.h
//  Quickpeck
//
//  Created by Hanny Aly on 7/18/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReceivedMessage.h"

@interface ReceivedMessageVideo : ReceivedMessage

@property (nonatomic)         BOOL              imageIsStillOnScreen;

-(ReceivedMessageVideo *)initWithReceived_message:(Received_message *)message;
@end