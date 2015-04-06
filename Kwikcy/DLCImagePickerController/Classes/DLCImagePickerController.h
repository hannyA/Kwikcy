//
//  DLCImagePickerController.h
//  DLCImagePickerController
//
//  Created by Dmitri Cherniak on 8/14/12.
//  Copyright (c) 2012 Dmitri Cherniak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"
#import "BlurOverlayView.h"
#import "QPContactsViewController.h"

//@class DLCImagePickerController;
//
//@protocol DLCImagePickerDelegate <NSObject>
//@optional
//- (void)imagePickerController:(DLCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
//- (void)imagePickerControllerDidCancel:(DLCImagePickerController *)picker;
//- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender mediaDictionary:(NSDictionary *)mediaInfo;
//@end


@protocol ProfilePhotoDelegate <NSObject>
@optional
-(void)saveCameraPhoto:(UIImage*)image;
@end


@protocol QPTabBarDelegate <NSObject>
@optional
- (void)selectTabBarForSentMessage:(BOOL)sendMessage withProgressBar:(UIProgressView *)progressBar;
@end


@interface DLCImagePickerController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, QPCameraDelegate>



@property (nonatomic, weak) IBOutlet GPUImageView *imageView;

@property (nonatomic, weak) id<ProfilePhotoDelegate> profileDelegate;

//@property (nonatomic, weak) id <DLCImagePickerDelegate> delegate;
@property (nonatomic, weak) id <QPTabBarDelegate> QPtabBarDelegate;


@property (nonatomic, weak) IBOutlet UIButton *photoCaptureButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;

@property (nonatomic, weak) IBOutlet UIButton *reverseCameraToggleButton;
@property (nonatomic, weak) IBOutlet UIButton *blurToggleButton;
@property (nonatomic, weak) IBOutlet UIButton *filtersToggleButton;
@property (nonatomic, weak) IBOutlet UIButton *libraryToggleButton;
@property (nonatomic, weak) IBOutlet UIButton *flashToggleButton;
//@property (nonatomic, weak) IBOutlet UIButton *retakeButton;

@property (nonatomic, weak) IBOutlet UIScrollView *filterScrollView;
//@property (nonatomic, weak) IBOutlet UIImageView *filtersBackgroundImageView;
@property (nonatomic, weak) IBOutlet UIView *photoBar;
//@property (nonatomic, weak) IBOutlet UIView *topBar;
@property (nonatomic, strong) BlurOverlayView *blurOverlayView;
@property (nonatomic, strong) UIImageView *focusView;

@property (nonatomic, assign) CGFloat outputJPEGQuality;


@property (nonatomic, strong) NSNumber *previousViewControllerValue;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSOperationQueue *operationQueue;


@property (nonatomic, strong) UIProgressView *progressView;



@end
