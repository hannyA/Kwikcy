//
//  KCImageVC.h
//  Kwikcy
//
//  Created by Hanny Aly on 8/22/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReceivedMessage.h"

#import "ReceivedMessageImage.h"


@interface KCImageVC : UIViewController


@property (nonatomic, strong) NSString *count;

//Set image
@property (nonatomic, strong) UIImage *image;
//@property (nonatomic, strong) NSString *filepath;
@property (nonatomic, strong) ReceivedMessageImage *receivedMessage;

//@property (strong, nonatomic) NSTimer *timer;
//@property (nonatomic)         BOOL     timerStarted;



@property (strong, nonatomic) NSString * theTimeReceivedFromSegue;


/* Sets the countDownLabel.text to the timer */
//-(void)setTimerForCountDownLabel:(NSNumber *)time;
//-(void)updateCount:(NSNotification *)notification;
//
//-(void)timerDidStart:(NSDictionary *)dictionary forRow:(NSNumber *)row;

-(void)animateSpinningWheelForFirstTime;
@end
