//
//  KCCameraShutter.m
//  KCCaptureSession
//
//  Created by Hanny Aly on 6/14/14.
//  Copyright (c) 2014 Aly LLC. All rights reserved.
//

#import "KCCameraShutter.h"

// natural state is open
#define OPENED  YES
#define CLOSED  NO

@interface KCCameraShutter ()
@property (nonatomic) CGRect top;
@property (nonatomic) CGRect topHalf;

@property (nonatomic) CGRect top5;
@property (nonatomic) CGRect top5Half;

@property (nonatomic) CGRect left;
@property (nonatomic) CGRect leftHalf;

@property (nonatomic) CGRect right;
@property (nonatomic) CGRect rightHalf;

@property (nonatomic) CGRect bottom;
@property (nonatomic) CGRect bottomHalf;


@property (nonatomic, strong) UIImageView *imageView1Black;

@property (nonatomic, strong) UIImageView *imageView2Red;

@property (nonatomic, strong) UIImageView *imageView3Gray;

@property (nonatomic, strong) UIImageView *imageView4Blue;

@property (nonatomic, strong) UIImageView *imageView5Black;

@end
@implementation KCCameraShutter

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
         _openStatus = OPENED;
        
        self.top = CGRectMake( frame.origin.x,
                              frame.origin.y - frame.size.height,
                              frame.size.width,
                              frame.size.height);
        
        
        self.top5 = CGRectMake(frame.origin.x + ( frame.size.width /2),
                               frame.origin.y - frame.size.height,
                               frame.size.width,
                               frame.size.height);
        
        
        
        self.left = CGRectMake(frame.origin.x - frame.size.width,
                               frame.origin.y,
                               frame.size.width,
                               frame.size.height);
        
        
        self.right = CGRectMake(  frame.origin.x + frame.size.width,
                                frame.origin.y,
                                frame.size.width,
                                frame.size.height);
        
        
        self.bottom = CGRectMake( frame.origin.x,
                                 frame.origin.y + frame.size.height,
                                 frame.size.width,
                                 frame.size.height);
        
        
        
        
        
        
        
        self.topHalf = CGRectMake(frame.origin.x,
                                  frame.origin.y - (frame.size.height /2),
                                  frame.size.width,
                                  frame.size.height);
        
        self.top5Half = CGRectMake(    frame.origin.x + ( frame.size.width /2),
                                   frame.origin.y - (frame.size.height /2),
                                   frame.size.width,
                                   frame.size.height);
        
        
        self.leftHalf = CGRectMake(frame.origin.x - (frame.size.width /2),
                                   frame.origin.y,
                                   frame.size.width,
                                   frame.size.height);
        
        
        self.rightHalf = CGRectMake(frame.origin.x + (frame.size.width /2),
                                    frame.origin.y,
                                    frame.size.width,
                                    frame.size.height);
        
        
        self.bottomHalf = CGRectMake(frame.origin.x,
                                     frame.origin.y + (frame.size.height /2),
                                     frame.size.width,
                                     frame.size.height);
        
        
        
        
        UIColor *topLeftColor = [UIColor whiteColor];
        UIColor *topRightColor = [UIColor redColor];
        UIColor *bottomLeftColor = [UIColor redColor];
        UIColor *bottomRightColor = [UIColor whiteColor];
        
        
        self.imageView1Black = [[UIImageView alloc] initWithFrame:self.top];
        self.imageView1Black.backgroundColor = topLeftColor;
        
        self.imageView5Black = [[UIImageView alloc] initWithFrame:self.top5];
        self.imageView5Black.backgroundColor = topLeftColor;
        
        
        self.imageView2Red = [[UIImageView alloc] initWithFrame:self.left];
        self.imageView2Red.backgroundColor = topRightColor;
        
        
        self.imageView3Gray = [[UIImageView alloc] initWithFrame:self.bottom];
        self.imageView3Gray.backgroundColor = bottomRightColor;
        
        
        self.imageView4Blue = [[UIImageView alloc] initWithFrame:self.right];
        self.imageView4Blue.backgroundColor = bottomLeftColor;
        
        
        
        [self addSubview:self.imageView1Black];
        [self addSubview:self.imageView2Red];
        [self addSubview:self.imageView3Gray];
        [self addSubview:self.imageView4Blue];
        [self addSubview:self.imageView5Black];
    
    }
    return self;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/



-(void)closeShutter
{
    [self willCloseShutter];

    [UIView animateWithDuration:0.3
                          delay:0
                        options: UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.imageView1Black.frame = self.topHalf;
                         self.imageView2Red.frame = self.leftHalf;
                         self.imageView3Gray.frame = self.bottomHalf;
                         self.imageView4Blue.frame = self.rightHalf;
                         
                         self.imageView5Black.frame = self.top5Half;
                         
                     }
                     completion:^(BOOL finished){
                         [self didCloseShutter];
                     }];
    
}


-(void)openShutter
{
    [self willOpenShutter];
    
    [UIView animateWithDuration:.3
                          delay:0
                        options: UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.imageView1Black.frame = self.top;
                         self.imageView2Red.frame = self.left;
                         self.imageView3Gray.frame = self.bottom;
                         self.imageView4Blue.frame = self.right;
                         
                         self.imageView5Black.frame = self.top5;
                     }
                     completion:^(BOOL finished){
                         [self didOpenShutter];
                     }];
    
}

-(void)willCloseShutter
{
    NSLog(@"Will close shutter");
    self.hidden = NO;
    self.openStatus = CLOSED;
}

-(void)didCloseShutter
{
    NSLog(@"In closeShutter set openstatus to Closed");
}

-(void)willOpenShutter
{
    NSLog(@"Will Open Shutter");
    self.openStatus = OPENED;
}

-(void)didOpenShutter
{
    NSLog(@"didOpenShutter");
    self.hidden = YES;
}





-(void)setOpenStatus:(BOOL)openStatus
{
    
    _openStatus = openStatus;
//    if (_openStatus == OPENED)
//    {
//        NSLog(@"set status to open");
//        [self didOpenShutter];
//    }
}

//-(BOOL)isOpened
//{
//    
//}

//-(BOOL)isOpened
//{
//    return self.isOpened;
//}


//-(BOOL)isOpen
//{
//    if (self.open == OPENED)
//        return YES;
//    else
//        return NO;
//}

@end
