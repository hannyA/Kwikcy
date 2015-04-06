//
//  QPTouchCell.m
//  Quickpeck
//
//  Created by Hanny Aly on 12/31/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "QPTableViewTouchCell.h"

@implementation QPTableViewTouchCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}


//- (void)setSelected:(BOOL)selected animated:(BOOL)animated
//{
//    [super setSelected:selected animated:animated];
//    // Configure the view for the selected state
//    NSLog(@"QPTableViewTouchCell setSelected");
//}
//
//-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
//{
//    [super setHighlighted:highlighted animated:animated];
//    NSLog(@"QPTableViewTouchCell setHighlighted");
//}




/* User either tapped, tapped twice, etc, TODO: Look up if this includes swiping */
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
//    [super touchesBegan:touches withEvent:event];
    [self setHighlighted:NO animated:YES];
    //self.selectionStyle = UITableViewCellSelectionStyleNone;
    NSLog(@"QPTableViewTouchCell touchesBegan");

    [self.delegate thisTableViewCellIsHeldDownWithIndexpath:self.indexPath];
}



/* Phone call interruption or screen shot taken */

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"QPTableViewTouchCell touchesCancelled");

//    [super touchesCancelled:touches withEvent:event];
    
//    NSLog(@"Special event\n%@", event.description);
//    
//    NSLog(@"touchesCancelled touchcell");
//
//    for (UITouch *touch in touches)
//    {
//        NSLog(@"%@", touch.description);
//    }
//    NSLog(@"touchesCancelled events");
//    
//    
    NSSet *allTouches = [event allTouches];
    for (UITouch *touch in allTouches)
    {
        NSLog(@"%@", touch.description);
    }
    NSLog(@"touchesCancelled end");
    
    
//    [self.delegate thisTableViewCellIsCanceledWithIndexpath:self.indexPath];
}


/* Finger may have been released */
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
//    [super touchesEnded:touches withEvent:event];
    NSLog(@"QPTableViewTouchCell touchesEnded");

    [self.delegate thisTableViewCellIsReleasedWithIndexpath:self.indexPath];
}


//-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
//{
////    [super touchesMoved:touches withEvent:event];
//    NSLog(@"touchesMoved touchcell");
//    
//    [self.delegate thisTableViewCellIsMovedWithIndexpath:self.indexPath];
//
//}
//
//-(void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
//{
//    NSLog(@"motionBegan");
//}
//-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
//{
//    NSLog(@"motionEnded");
//
//}
//-(void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
//{
//    NSLog(@"motionCancelled");
//
//}




@end
