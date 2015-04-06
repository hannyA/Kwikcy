//
//  KCCameraShutter.h
//  KCCaptureSession
//
//  Created by Hanny Aly on 6/14/14.
//  Copyright (c) 2014 Aly LLC. All rights reserved.
//

//TODO: DELETE:

#import <UIKit/UIKit.h>


//@protocol CameraShutterDelegate <NSObject>
//@optional
//- (void)selectTabBarForSentMessage:(BOOL)sendMessage;
//@end



@interface KCCameraShutter : UIView

//@property (nonatomic, weak) id <CameraShutterDelegate> QPtabBarDelegate;

@property (nonatomic, getter = isOpened) BOOL openStatus;

-(void)closeShutter;
-(void)openShutter;

@end
