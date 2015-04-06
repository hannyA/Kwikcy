//
//  ImageViewController.m
//  Shutterbug
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "ImageViewController.h"
#import "Constants.h"

@interface ImageViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *countDownLabel;

@property (strong, nonatomic) NSNumber *countDown;
@property (nonatomic) BOOL imagePresented;

@property (nonatomic) NSInteger row;
@end

@implementation ImageViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self resetImage];
    self.countDownLabel.text = self.theTimeReceivedFromSegue;
    self.countDownLabel.textColor = [Constants getStrawberryColor];
}

-(void)viewWillAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:(@selector(updateCount:))
                                                 name:@"countDown"
                                               object:nil];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"BOOL"];
    [self.imageViewDelegate performSelector:@selector(imageViewIsOnScreen:) withObject:dictionary];
   
    /*Start timer */
    if (!self.timerStarted)
    {
        NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
        [runLoop addTimer:self.alarm forMode:NSDefaultRunLoopMode];
        
    }
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    NSLog(@"Touches cancelled with event: %@", event.description);

} 

-(void)timerDidStart:(NSDictionary *)dictionary forRow:(NSNumber *)row
{
    NSNumber *hasTimerDidStart = [dictionary objectForKey:@"BOOL"];
    self.timerStarted = [hasTimerDidStart boolValue];
    
    self.row = [row integerValue];
    NSLog(@"Showing for current row: %ld", (long)self.row);


}


-(void)updateCount:(NSNotification *)notification
{
    NSDictionary * dictionary = [notification userInfo];
    NSNumber *timeLeft = [dictionary objectForKey:@"count"];
    NSNumber *row = [dictionary objectForKey:@"row"];
    
    if ([row integerValue] == self.row){
        self.countDownLabel.text = [timeLeft stringValue];
        NSLog(@"Row for image is : %ld", (long)self.row);
    }
}


-(void)setTimerForCountDownLabel:(NSNumber *)time
{  
    NSString * t = [time stringValue];
    self.countDownLabel.text = t;
}




-(void)viewWillDisappear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [super viewWillDisappear:YES];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"BOOL"];
    [self.imageViewDelegate performSelector:@selector(imageViewIsOnScreen:) withObject:dictionary];
    

    [super viewDidDisappear:YES];
}



-(void)setQPimage:(UIImage *)QPimage
{
    _QPimage = QPimage;
}

- (void)resetImage
{    
    if (self.QPimage){        
        self.imageView.image = self.QPimage;
    }
    else
        self.imageView.image = nil;
}


@end
