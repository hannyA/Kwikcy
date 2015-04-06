//
//  ReceivedMessageTimer.m
//  Quickpeck
//
//  Created by Hanny Aly on 7/17/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "ReceivedMessageImage.h"

@interface ReceivedMessageImage ()
@property (nonatomic, strong) Received_message *message;

@end

@implementation ReceivedMessageImage



-(NSString *)getStatus
{
    return self.message.view_status;
}

-(ReceivedMessageImage *)initWithReceived_message:(Received_message *)message
{
    self = [super init];
    if (self)
    {
        self.message = message;
        if ([self.message.view_status isEqualToString:@"YES"])
            self.timeLeft = [NSNumber numberWithInt:0];
        else
        {
            self.timeLeft = [NSNumber numberWithInt:11]; // [self randomNumber]; //[NSNumber numberWithInt:5];
            
            self.timerStarted = NO;
            self.timer = [NSTimer timerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(updateCountDown)
                                           userInfo:nil
                                            repeats:YES];
        }
    }
    return self;
}



 
-(void)updateCountDown
{    
    self.timeLeft = [NSNumber numberWithInt:[self.timeLeft integerValue] - self.timer.timeInterval];

    NSDictionary *timeInfo = @{@"count":self.timeLeft,
                               @"receivedMessage": self
                               };
    
    if ([self.timeLeft isEqualToNumber:[NSNumber numberWithInt:0]])
    {
        /* Invalidate selecting cell */
        [self clearProperties];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"countDown" object:self userInfo:timeInfo];
}


-(void)clearProperties
{
    if ([self.timer isValid])
        [self.timer invalidate];
    self.timer    = nil;
    self.timeLeft = [NSNumber numberWithInt:0];
    self.image    = nil;
}



-(BOOL)equalsMessage:(Received_message*) message
{
    return [self.message.from isEqualToString:message.from] && [self.message.filepath isEqualToString:message.filepath];
}



-(BOOL)isEqualToMessage:(ReceivedMessageImage*)receivedMessage
{
    return [self.message.from isEqualToString:receivedMessage.message.from] && [self.message.filepath isEqualToString:receivedMessage.message.filepath];
}



-(NSNumber *)randomNumber
{
    NSNumber *random;
    int ran  = arc4random_uniform(11) + 3;
    random = [NSNumber numberWithInt:ran];
    return random;
}
   
   

@end
