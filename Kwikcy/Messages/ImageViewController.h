//
//  ImageViewController.h
//  Shutterbug
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ImageViewControllerProtocolDelegate <NSObject>
@required
- (void) imageViewIsOnScreen:(NSDictionary *)boolDictionary;
@end


@interface ImageViewController : UIViewController

@property (nonatomic, weak) id <ImageViewControllerProtocolDelegate> imageViewDelegate;
@property (nonatomic, strong) UIImage *QPimage;
@property (strong, nonatomic) NSTimer *alarm;

@property (strong, nonatomic) NSString * theTimeReceivedFromSegue;
@property (nonatomic)         BOOL       timerStarted;


/* Sets the countDownLabel.text to the timer */
-(void)setTimerForCountDownLabel:(NSNumber *)time;
-(void)updateCount:(NSNotification *)notification;

-(void)timerDidStart:(NSDictionary *)dictionary forRow:(NSNumber *)row;
@end
