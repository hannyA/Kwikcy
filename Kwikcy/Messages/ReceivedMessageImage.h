//
//  ReceivedMessageTimer.h
//  Quickpeck
//
//  Created by Hanny Aly on 7/17/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReceivedMessage.h"

@interface ReceivedMessageImage : ReceivedMessage

/*
 * We should not have imageIsStillOnScreen, row, indexPath
 */

@property (nonatomic, strong) NSTimer          *timer;
@property (nonatomic)         BOOL             timerStarted;

@property (nonatomic, strong) UIImage          *image;
@property (nonatomic, strong) NSNumber         *timeLeft;
@property (nonatomic)         BOOL              imageIsStillOnScreen;

@property (nonatomic, strong) NSString         *loadingStatus;

@property (nonatomic, getter = isScreenShotSafe)         BOOL              screenShotSafe;


/*
 * message is a NSManagedObject from core data containing only data
 */

-(ReceivedMessageImage *)initWithReceived_message:(Received_message *)message;
-(void)clearProperties;

-(BOOL)equalsMessage:(Received_message*) message;
-(BOOL)isEqualToMessage:(ReceivedMessageImage*)receivedMessage;
@end
