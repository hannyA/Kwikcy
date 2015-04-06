//
//  DLCImagePickerController.m
//  DLCImagePickerController
//
//  Created by Dmitri Cherniak on 8/14/12.
//  Copyright (c) 2012 Dmitri Cherniak. All rights reserved.
//

#import <AWSDynamoDB/AWSDynamoDB.h>
#import "AmazonKeyChainWrapper.h"
#import "AmazonClientManager.h"

#import "DLCImagePickerController.h"
#import "GrayscaleContrastFilter.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "Constants.h"
#import "MBProgressHUD.h"
#import "BlockAlertView.h"
#import "BlockActionSheet.h"

#import "QPNetworkActivity.h"

#import "User+methods.h"

#import "QPCoreDataManager.h"

#import "QPProfileMethods.h"

#import "UIImage+Resize.h"
#import "KCCameraShutter.h"

#import "KwikcyClientManager.h"
#import "KCServerResponse.h"


#import "RegistrationTableViewController.h"
#import "QPLoginViewController.h"
#import "KCProfileVC.h"

#define kStaticBlurSize 2.0f

#define kStaticBlurZeroSize 0.0f

#define SEGMENT_CAMERA 0
#define SEGMENT_VIDEO 1

#define USERS_PROFILE_CONTROLLER @"KCProfileVC"



//
//enum FilterShowing:NSUInteger {
//    CameraButton,
//    DoneButton
//};


enum FilterIsShowing:NSUInteger {
    FilterIsHidden,
    FilterIsLow,
    FilterIsHigh
};




@interface DLCImagePickerController()<UIScrollViewDelegate>
@property (nonatomic, strong)        MBProgressHUD           *hud;
@property (strong, nonatomic)        NSArray                 *mediaTypes;
@property (nonatomic)                BOOL                     videoCameraIsAvailable;
@property (strong, nonatomic)        NSMutableDictionary     *mediaInfo;
@property (nonatomic, strong)        NSTimer                 *HUDalarm;
@property (nonatomic)                BOOL                     cameraIsReady;

@property (weak, nonatomic) IBOutlet UIButton *chooseCameraTypeButton;
@property (weak, nonatomic) IBOutlet UIButton *videoCaptureButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;



@property (nonatomic) BOOL hasPhotoCamera;
@property (nonatomic) BOOL hasVideoCamera;
@property (nonatomic, getter = isViewStatic) BOOL viewStatic;

@property (nonatomic) BOOL statusBarIsNotHidden;



@property (nonatomic) NSUInteger filterPosition;

@property (nonatomic, strong) UIImage * currentFilterKwikcyImage;


@property (nonatomic, strong) UIImageView *whiteScreen;

//@property (nonatomic, strong) KCCameraShutter *shutter;

@end

    
@implementation DLCImagePickerController {
    BOOL isVideoRecorded;
    
    GPUImageStillCamera *stillCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageOutput<GPUImageInput> *blurFilter;
    GPUImagePicture *staticPicture;
    UIImageOrientation staticPictureOriginalOrientation;

    dispatch_once_t showLibraryOnceToken;
    GPUImageVideoCamera           *videoCamera;
    GPUImageOutput<GPUImageInput> *vidfilter;

}


-(UIImageView *)whiteScreen
{
    if (!_whiteScreen)
    {
        CGRect rect = CGRectMake(self.imageView.frame.origin.x,
                                 self.imageView.frame.origin.y,
                                 self.imageView.frame.size.width,
                                 self.imageView.frame.size.height);
        
        _whiteScreen = [[UIImageView alloc] initWithFrame:rect];
        _whiteScreen.backgroundColor = [UIColor whiteColor];
    }
    return _whiteScreen;
}





-(void)showWhiteScreen
{
    self.whiteScreen.hidden = NO;
}


-(void)hideWhiteScreenWithDuration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:(duration > 0) ? duration:1.0
                     animations:^{
                         self.whiteScreen.alpha = 0;
                     }
                     completion:^(BOOL finished)
                    {
                         self.whiteScreen.hidden = YES;
                         self.whiteScreen.alpha = 1.0;
                     }];
}





//-(void)closeShutter
//{
//    self.whiteScreen.hidden = NO;
//    [self.shutter closeShutter];
//}
//
//-(void)openShutter
//{
//    NSLog(@"hide white screen");
//    self.whiteScreen.hidden = YES;
//    
//    [self.shutter openShutter];
//}




-(BOOL)prefersStatusBarHidden
{
//    NSLog(@"camera statusBarIsNotHidden = %@", self.statusBarIsNotHidden ? @"YES": @"NO");
    
    if (!self.statusBarIsNotHidden)
    {
//        NSLog(@"return yes");
        return YES;
    }
    else
    {
//        NSLog(@"return no");
        return NO;
    }
}


-(NSMutableDictionary *)mediaInfo
{
    if (!_mediaInfo)
        _mediaInfo = [NSMutableDictionary dictionary];
    return _mediaInfo;
}




-(void)showHUDWithMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hud = [MBProgressHUD getAndShowUniversalHUD:self.view withText:message animated:YES];
    });
}

-(void)hideHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.hud hideProgressHUD];
    });
}



-(void)showHUDWithMessageSynch:(NSString *)message
{
    self.hud = [MBProgressHUD getAndShowUniversalHUD:self.view withText:message animated:YES];
}

-(void)hideHUDSynch
{
    [self.hud hideProgressHUD];
}











//    // Device's screen size (ignoring rotation intentionally):
//    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
//
//    // iOS is going to calculate a size which constrains the 4:3 aspect ratio
//    // to the screen size. We're basically mimicking that here to determine
//    // what size the system will likely display the image at on screen.
//    // NOTE: screenSize.width may seem odd in this calculation - but, remember,
//    // the devices only take 4:3 images when they are oriented *sideways*.
//    float cameraAspectRatio = 4.0 / 3.0;
//    float imageWidth = floorf(screenSize.width * cameraAspectRatio);
//    float scale = ceilf((screenSize.height / imageWidth) * 10.0) / 10.0;
//
//    self.imageView.transform = CGAffineTransformMakeScale(scale, scale);






//    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
//    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
//
//    GPUImageFilter *filter1 = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"Shader1"];
//
//    [videoCamera addTarget:filter1];
//    [filter1 addTarget:imageView];
//
//    [videoCamera startCameraCapture];


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.filtersToggleButton.hidden = YES;

    self.outputJPEGQuality = 0.4;
    staticPictureOriginalOrientation = UIImageOrientationUp;

    [self.view addSubview:self.whiteScreen];
    
    
//    CGRect rect =  CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    
//    self.shutter = [[KCCameraShutter alloc] initWithFrame:rect];
//    [self.view addSubview:self.shutter];
//    [self.view bringSubviewToFront:self.shutter];

    
    self.filterScrollView.delegate = self;
    
    
    
    
    // Setup camera the flip between photo and video button
    [self.chooseCameraTypeButton setImage:[UIImage imageNamed:@"camera-buttonA"] forState:UIControlStateSelected];
    [self.chooseCameraTypeButton setImage:[UIImage imageNamed:@"video-buttonA"]  forState:UIControlStateNormal];
    
    
    //TODO: fix this
    self.chooseCameraTypeButton.enabled = NO; // and currently hidden
    self.chooseCameraTypeButton.hidden = YES;

    
    self.hasVideoCamera = NO;
    self.hasPhotoCamera = NO;
    self.viewStatic     = NO;
    

    // Phone has camera
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera])
    {
        self.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];

        
        if ([self.mediaTypes containsObject:(NSString *)kUTTypeImage] &&
            ( [self.mediaTypes containsObject:(NSString *)kUTTypeMovie] ||
            [self.mediaTypes containsObject:(NSString *)kUTTypeVideo]) )
        {
            self.chooseCameraTypeButton.hidden = NO;
            self.hasVideoCamera = YES;
            self.hasPhotoCamera = YES;
        }
        else if ([self.mediaTypes containsObject:(NSString *)kUTTypeMovie] ||
            [self.mediaTypes containsObject:(NSString *)kUTTypeVideo])
        {
            self.hasVideoCamera = YES;
        }
        
        else if ([self.mediaTypes containsObject:(NSString *)kUTTypeImage])
        {
            self.hasPhotoCamera = YES;
        }
        // Some how we came to this
        else
            self.viewStatic = YES;

    }
    else
    {
        self.viewStatic = YES;

        // No camera
        runOnMainQueueWithoutDeadlocking(^{
            [self prepareFilter];
        });
    }
}





-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSLog(@"Photo Camera: viewWillAppear");
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.statusBarIsNotHidden = NO;

    
    if (!stillCamera && !staticPicture)
    {
        NSLog(@"Photo Camera: viewWillAppear reset camera");

        //reset camera
        
//        [self closeShutter];
        [self showWhiteScreen];
        
        [self disableCameraButton];
        [self setUpCameras];
    }
    else if (!staticPicture)
    {
        NSLog(@"!staticPicture");

        // no static picture but have stillcamera  camera will be either shutdown or paused
        
        [self showWhiteScreen];

        [self prepareFilter];
        
        [stillCamera.inputCamera lockForConfiguration:nil];
        [stillCamera resumeCameraCapture];
        [stillCamera.inputCamera unlockForConfiguration];
        
        
        [self hideWhiteScreenWithDuration:0.6];


    }
    else if (!stillCamera)
    {
        NSLog(@"!stillCamera");

        // no still camera but have still image, from Sent View Controller
    }
    
    
    // If view is not static
    if (!self.isViewStatic)
    {
        NSLog(@"!isViewStatic");

//        NSLog(@"!self.isViewStatic");
        
        if (!self.chooseCameraTypeButton.isHidden && self.chooseCameraTypeButton.isSelected)
            [self showVideoCameraButton];
        else if (!self.chooseCameraTypeButton.isHidden)
            [self showStillCameraButton];
    }
    else
    {
        NSLog(@"ViewStatic");

//        NSLog(@"We have no camera");
        // No camera
        runOnMainQueueWithoutDeadlocking(^{
            [self prepareFilter];
        });
    }
}





















-(void)enableButtons
{
//    [self.photoCaptureButton setEnabled:YES];
    [self enablePhotoCameraButton];
    [self.reverseCameraToggleButton setEnabled:YES];
    [self.blurToggleButton setEnabled:YES];
    [self.libraryToggleButton setEnabled:YES];
    [self.flashToggleButton setHidden:YES];
    [self.chooseCameraTypeButton setEnabled:YES];
}


-(void)disableButtons
{
//    [self.photoCaptureButton setEnabled:NO];
    [self disableCameraButton];
    [self.reverseCameraToggleButton setEnabled:NO];
    [self.blurToggleButton setEnabled:NO];
    [self.libraryToggleButton setEnabled:NO];
    [self.flashToggleButton setHidden:NO];
    [self.chooseCameraTypeButton setEnabled:NO];
}


-(void)showStillCameraButton
{
    self.videoCaptureButton.hidden = YES;
    self.doneButton.hidden         = YES;
    self.photoCaptureButton.hidden = NO;
}

-(void)showVideoCameraButton
{
    self.doneButton.hidden         = YES;
    self.photoCaptureButton.hidden = YES;
    self.videoCaptureButton.hidden = NO;
}

-(void)showDoneButton
{
    self.videoCaptureButton.hidden = YES;
    self.photoCaptureButton.hidden = YES;
    self.doneButton.hidden         = NO;
    
//    self.filtersToggleButton.hidden = NO;

}






-(void) setUpCameras
{
    [self resetFocusAndBlurViews];
    [self loadFilters];
    
    if (self.hasPhotoCamera)
        [self setUpPhotoCamera];
    else if (self.hasVideoCamera)
        [self setupVideoCamera];
}









- (IBAction)userDidChooseVideoStillCamera:(UIButton *)sender
{
//    NSLog(@"userDidChooseVideoStillCamera");
//    sender.enabled = NO;
    [self disableButtons];
//    self.cameraIsReady = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if (!sender.isSelected){ //if sender is not video, then setup video

//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.filtersToggleButton.hidden = YES;
//            });
            
            [self clearPhotoCamera];
            [self startVideo];
            if (self.cameraIsReady){ // Setup for video for video
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showVideoCameraButton];
                    [self enableButtons];
                    sender.selected = !sender.isSelected;
                    sender.enabled = YES;
                });
            }
        }
        else {
            [self clearVideoCamera];
            [self retakePhoto];
            if (self.cameraIsReady){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showStillCameraButton];
                    [self enableButtons];
//                    self.filtersToggleButton.hidden = YES;
                    sender.selected = !sender.isSelected;
                    sender.enabled = YES;
                });
                
            }
        }
    });
}

-(void) setupVideoCamera
{
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    // AVCaptureDevicePositionBack automatically set for init
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
}



-(void)startVideo
{
    if (!videoCamera)
    {
        [self setupVideoCamera];
    }
    
    
    //  Multivalue color
  //  GPUImageFilter *filter1 = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"Shader1"];
    GPUImageFilter *filter1 = [[GPUImageSepiaFilter alloc] init];

    [videoCamera addTarget:filter1];
    [filter1 addTarget:self.imageView];

    
    
    
//    vidfilter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"Shader2"];
//
//    [videoCamera addTarget:vidfilter];
//    [vidfilter addTarget:imageView];
    
    
    
//    vidfilter = [[GPUImageSepiaFilter alloc] init];
//    
//    [videoCamera addTarget:vidfilter];


    //    GPUImageFilter *customFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"Shader2"];
//    [videoCamera addTarget:customFilter];
//    [customFilter addTarget:imageView];
    
    
    
    // use above or below
//    vidfilter = [[GPUImageSepiaFilter alloc] init];
//    [videoCamera addTarget:vidfilter];

    
//
//    GPUImageFilter *customFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"CustomShader"];
//   
//    GPUImageView *filteredVideoView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, viewWidth, viewHeight)];
//    
//    // Add the view somewhere so it's visible
//    
//    [videoCamera addTarget:customFilter];
//    [customFilter addTarget:filteredVideoView];
//    
//    [videoCamera startCameraCapture];
    
        
    runOnMainQueueWithoutDeadlocking(^{
        
        [stillCamera.inputCamera lockForConfiguration:nil];
        [videoCamera startCameraCapture];
        [stillCamera.inputCamera unlockForConfiguration];

        if([videoCamera.inputCamera hasTorch]){
            [self.flashToggleButton setEnabled:YES];
        }else{
            [self.flashToggleButton setEnabled:NO];
        }
       // [self prepareFilter];
        
//        self.cameraIsReady = YES;
//        if (self.cameraIsReady) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.videoCaptureButton.enabled = YES;
//                self.chooseCameraTypeButton.enabled = YES;
//            });
//        }
    });
}









-(void)resetCameraButtonsForOriginalView
{
    
    if ((self.hasPhotoCamera || self.hasVideoCamera) && [stillCamera.inputCamera hasTorch])
        self.flashToggleButton.enabled = YES;
    else
        self.flashToggleButton.enabled = NO;
   
    self.libraryToggleButton.hidden = NO;

    
//    if ([self.parentController isEqualToString:USERS_PROFILE_CONTROLLER])
//    {
//        self.libraryToggleButton.hidden = YES;
//    }
//    else
//    {
//        self.libraryToggleButton.hidden = NO;
//    }

    
    if (self.filtersToggleButton.isSelected)
        [self hideFilters];
   
    
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] )
    {
        self.reverseCameraToggleButton.enabled = YES;
        self.reverseCameraToggleButton.hidden = NO;
    
    }
    else
        self.reverseCameraToggleButton.hidden = YES;

    
    [self showStillCameraButton];
}


-(void)setUpPhotoCamera
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        dispatch_sync(dispatch_get_main_queue(), ^{

            stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
        
            stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

            
            [self resetCameraButtonsForOriginalView];
            
            [self prepareFilter];
        
//            self.cameraIsReady = YES;
        

            [stillCamera.inputCamera lockForConfiguration:nil];
            [stillCamera startCameraCapture];
            [stillCamera.inputCamera unlockForConfiguration];
            

            [self enablePhotoCameraButton];
            [self hideWhiteScreenWithDuration:0.3];

            self.chooseCameraTypeButton.enabled = YES;
        });
    });
}



-(void)enablePhotoCameraButton
{
//    if (!self.shutter.isOpened) {
//        NSLog(@"open shutter");
//        [self openShutter];
//    }
    
//    [self hideWhiteScreenWithDuration:0.3];
    

    self.photoCaptureButton.enabled = YES;
}


-(void)disableCameraButton
{
    self.photoCaptureButton.enabled = NO;
}






-(void)resetFocusAndBlurViews
{
    self.focusView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"focus-crosshair"]];
    [self.view addSubview:self.focusView];
    self.focusView.alpha = 0;
    
    
    self.blurOverlayView = [[BlurOverlayView alloc] initWithFrame:CGRectMake(0, 0,
                                                                             self.imageView.frame.size.width,
                                                                             self.imageView.frame.size.height)];
    self.blurOverlayView.alpha = 0;
    [self.imageView addSubview:self.blurOverlayView];
}




/* 
 ************************  Chnage loadfilters images *************************
 */

-(void) loadFilters
{
    for(int i = 0; i < 10; i++) {
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
       
        [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", i + 1]] forState:UIControlStateNormal];
               
        button.frame = CGRectMake(10+i*(60+10), 5.0f, 60.0f, 60.0f);
        button.layer.cornerRadius = 7.0f;
        
        
        //use bezier path instead of maskToBounds on button.layer
        UIBezierPath *bi = [UIBezierPath bezierPathWithRoundedRect:button.bounds
                                                 byRoundingCorners:UIRectCornerAllCorners
                                                       cornerRadii:CGSizeMake(7.0,7.0)];
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = button.bounds;
        maskLayer.path = bi.CGPath;
        button.layer.mask = maskLayer;
        
        button.layer.borderWidth = 5;
        button.layer.borderColor = [[UIColor whiteColor] CGColor];
           
        [button addTarget:self
                   action:@selector(filterClicked:)
         forControlEvents:UIControlEventTouchUpInside];
        button.tag = i;
        
        
        if(i == 0){
            [button setSelected:YES];
            button.layer.borderColor = [[Constants getStrawberryColor] CGColor];
        }
		[self.filterScrollView addSubview:button];
	}
	[self.filterScrollView setContentSize:CGSizeMake(10 + 10*(60+10), 75.0)];
 
    [self setFilterButtonToFirstFilter];
}




-(void)setFilterButtonToFirstFilter
{
    [self.filterScrollView setContentOffset:CGPointMake(0, 0) animated:YES];

    for(UIView *view in self.filterScrollView.subviews){
        if([view isKindOfClass:[UIButton class]]){
            UIButton *filterButton = (UIButton *)view;
            [filterButton setSelected:NO];
            view.layer.borderColor = [[UIColor whiteColor] CGColor];
         
            if (filterButton.tag == 0)
            {
                [self highlightClickedFilter:filterButton];
            }
        }
    }
}



/* This function is called from filter buttons and used to set up the first time */
-(void)highlightClickedFilter:(UIButton *) button
{
//    NSLog(@"filter clicked");
    for(UIView *view in self.filterScrollView.subviews){
        if([view isKindOfClass:[UIButton class]]){
            [(UIButton *)view setSelected:NO];
            view.layer.borderColor = [[UIColor whiteColor] CGColor];
        }
    }
    
    button.layer.borderColor = [[Constants getStrawberryColor] CGColor];
    
    [button setSelected:YES];
    [self removeAllTargets];
    
//    selectedFilter = (int)button.tag;
    [self setFilter:(int)button.tag];
}



/* This function is called only with actual filter button clicks */
-(void) filterClicked:(UIButton *) sender
{
    [self highlightClickedFilter:sender];
    [self prepareFilter];
}









-(void) setFilter:(int) index
{
    switch (index)
    {
        case 1:
                filter = [[GPUImageContrastFilter alloc] init];
                [(GPUImageContrastFilter *) filter setContrast:1.75];
                break;
        case 2:
                filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"crossprocess"];
                break;
        case 3:
                filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"02"];
                break;
        case 4:
                filter = [[GrayscaleContrastFilter alloc] init];
                break;
        case 5:
                filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"17"];
                break;
        case 6:
                filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"aqua"];
                break;
        case 7:
                filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"yellow-red"];
                break;
        case 8:
                filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"06"];
                break;
        case 9:
                filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"purple-green"];
                break;
        default:
                filter = [[GPUImageFilter alloc] init];
                break;
    }
}


-(void) prepareFilter
{
    if (!self.isViewStatic) {
        [self prepareLiveFilter];
    } else {
        [self prepareStaticFilter];
    }
}


-(void) prepareLiveFilter
{
//    NSLog(@"prepare live fileter");
    
    [stillCamera addTarget:filter];

    // blur is terminal filter
    if (self.blurToggleButton.isSelected)
    {
        //regular filter is terminal
        [filter addTarget:blurFilter];
        [blurFilter addTarget:self.imageView];
    }
    else
    {
        [filter addTarget:self.imageView];
    }
}


-(void) prepareStaticFilter
{

    [staticPicture addTarget:filter];

    if (self.blurToggleButton.isSelected)
    {
        [filter addTarget:blurFilter];
        [blurFilter addTarget:self.imageView];
        
        [blurFilter useNextFrameForImageCapture];
        //regular filter is terminal
    }
    else
    {
        [filter addTarget:self.imageView];
        
        [filter useNextFrameForImageCapture];
    }

    
    
    GPUImageRotationMode imageViewRotationMode = kGPUImageNoRotation;
//    switch (staticPictureOriginalOrientation) {
//        case UIImageOrientationLeft:
//            imageViewRotationMode = kGPUImageRotateLeft;
//            break;
//        case UIImageOrientationRight:
//            imageViewRotationMode = kGPUImageRotateRight;
//            break;
//        case UIImageOrientationDown:
//            imageViewRotationMode = kGPUImageRotate180;
//            break;
//        default:
//            imageViewRotationMode = kGPUImageNoRotation;
//            break;
//    }
    
    // seems like atIndex is ignored by GPUImageView...
    [self.imageView setInputRotation:imageViewRotationMode atIndex:0];

    
    [staticPicture processImage];

    if (self.blurToggleButton.isSelected)
    {
        self.currentFilterKwikcyImage = [blurFilter imageFromCurrentFramebuffer];
    }
    else
    {
         self.currentFilterKwikcyImage = [filter imageFromCurrentFramebuffer];
    }
}







-(void)removeAllTargets
{
    [stillCamera removeAllTargets];
    [staticPicture removeAllTargets];
    
    //regular filter
    [filter removeAllTargets];
    
    [blurFilter removeAllTargets];
}


-(void) removeAllVideoTargets
{
//    [staticPicture removeAllTargets];
    [videoCamera removeAllTargets];
    [vidfilter removeAllTargets];

    [blurFilter removeAllTargets];
}



-(IBAction)switchToLibrary:(id)sender
{
    if (!self.isViewStatic)
    {
        // shut down camera
        
        [stillCamera.inputCamera lockForConfiguration:nil];
        [stillCamera pauseCameraCapture];
        [stillCamera.inputCamera unlockForConfiguration];
        
        [self removeAllTargets];
    }
    else if (!isVideoRecorded)
    {
        // shut down camera
        [videoCamera pauseCameraCapture];
        [self removeAllVideoTargets];

    }
    
    UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = NO;

    [self presentViewController:imagePickerController animated:YES completion:nil];
}




-(IBAction)toggleFlash:(UIButton *)button
{
    button.selected = !button.isSelected;
}


-(IBAction) toggleBlur:(UIButton*)blurButton
{
    [self.blurToggleButton setEnabled:NO];
    [self removeAllTargets];
    
    
    self.blurToggleButton.selected = !self.blurToggleButton.isSelected;
    
    if (!self.blurToggleButton.isSelected)
    {
        [self showBlurOverlay:NO];
    }
    else {
        if (!blurFilter) {
            blurFilter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
            [(GPUImageGaussianSelectiveBlurFilter*)blurFilter setExcludeCircleRadius:80.0/320.0];
            [(GPUImageGaussianSelectiveBlurFilter*)blurFilter setExcludeCirclePoint:CGPointMake(0.5f, 0.5f)];
           
            [(GPUImageGaussianSelectiveBlurFilter*)blurFilter setBlurRadiusInPixels:kStaticBlurSize];
            [(GPUImageGaussianSelectiveBlurFilter*)blurFilter setAspectRatio:1.0f];
        }
        CGPoint excludePoint = [(GPUImageGaussianSelectiveBlurFilter*)blurFilter excludeCirclePoint];
		CGSize frameSize = self.blurOverlayView.frame.size;
		self.blurOverlayView.circleCenter = CGPointMake(excludePoint.x * frameSize.width, excludePoint.y * frameSize.height);
        [self flashBlurOverlay];
    }
    
    [self prepareFilter];
    [self.blurToggleButton setEnabled:YES];
}

-(IBAction) switchCamera
{
    self.reverseCameraToggleButton.enabled = NO;
    [stillCamera rotateCamera];
    self.reverseCameraToggleButton.enabled = YES;
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera] && stillCamera)
    {
        if ([stillCamera.inputCamera hasFlash] && [stillCamera.inputCamera hasTorch])
        {
            [self.flashToggleButton setEnabled:YES];
        }
        else
        {
            [self.flashToggleButton setEnabled:NO];
        }
    }
}






//[stillCamera capturePhotoAsImageProcessedUpToFilter:filter withCompletionHandler:^(NSData *processedJPEG, NSError *error)

-(void)captureImage
{
    void (^completion)(UIImage *, NSError *) = ^(UIImage *processedImage, NSError *error) {
        
        [stillCamera pauseCameraCapture];
        if ([stillCamera.inputCamera isTorchActive])
        {
            [stillCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
        }
        [stillCamera.inputCamera unlockForConfiguration];

        [self removeAllTargets];
        
        self.viewStatic = YES;
        
        staticPicture = [[GPUImagePicture alloc] initWithImage:processedImage];
        staticPictureOriginalOrientation = processedImage.imageOrientation;
        
        
        [self prepareFilter];
        
        [self showDoneButton];
        
        if(!self.filtersToggleButton.isSelected)
            [self showFilters];
    };
    
    
    [stillCamera capturePhotoAsImageProcessedUpToFilter:filter withCompletionHandler:completion];

}



- (IBAction)takeVideo:(UIButton *)sender
{
    
}



-(void)disableButtonsForTakePhoto
{
    self.libraryToggleButton.hidden     = YES;
    self.chooseCameraTypeButton.hidden  = YES;
    
    self.reverseCameraToggleButton.enabled = NO;
    self.flashToggleButton.enabled         = NO;
    
}

// This represents the done button when isStatic
-(IBAction) takePhoto:(id)sender
{
    [self disableCameraButton];
    [self disableButtonsForTakePhoto];

    [stillCamera.inputCamera lockForConfiguration:nil];
    
    if(self.flashToggleButton.isSelected && [stillCamera.inputCamera hasTorch])
    {
        [stillCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
        [self performSelector:@selector(captureImage)
                   withObject:nil
                   afterDelay:0.2];
    }
    else
    {
        [self captureImage];
    }
}




-(void)uploadProfilePhotoFromLogin
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    //Perhaps we should include photo dimensions so server can resize properly???
    
    parameters[COMMAND]   = UPDATE_PROFILE_PHOTO;
    parameters[ACTION]    = ADD;
    parameters[MEDIATYPE] = IMAGE;
    parameters[IMAGE]     = [self.mediaInfo[DATA] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    
    
    [KwikcyClientManager sendRequestWithParameters:parameters
                             withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
     {
         [self hideHUD];
         
         
         if (error)
         {
             [[Constants alertWithTitle:@"Connection Error"
                             andMessage:@"Could not send request due to a connection error"] show];
         }
         else
         {
             KCServerResponse *serverResponse = (KCServerResponse *)response;
             
             if (received200Response)
             {
                 if (serverResponse.successful)
                 {
                     [self performSegueWithIdentifier:@"Go To Main Page" sender:self];
                     [self performSelector:@selector(retakePhoto) withObject:nil afterDelay:2];
                 }
                 else
                 {
                     [[Constants alertWithTitle:@"Error" andMessage:serverResponse.message] show];
                     [self dismissCamera];
                 }
             }
         }
     }];
}

// xom
- (IBAction)donePressed
{
    self.mediaInfo[MEDIATYPE] = IMAGE;
    self.mediaInfo[IMAGE]     = self.currentFilterKwikcyImage;
    self.mediaInfo[DATA]      = UIImageJPEGRepresentation(self.currentFilterKwikcyImage, 1);
    
//
//    [self.parentViewController.childViewControllers count];
//    NSLog(@"parent class is NavigationController with %lu children", (unsigned long)[self.parentViewController.childViewControllers count]);
    
    Class parentVCClass = [self.parentViewController class];
    NSString *className = NSStringFromClass(parentVCClass);
   
//    NSLog(@"Parent class is = %@", className);
    
    // Prepare for Registration profile picture
    if ([self.parentViewController isKindOfClass:[UINavigationController class]])
    {
        
        UIViewController *parentController = self.parentViewController.childViewControllers[0];
        
        if ([parentController isKindOfClass:[RegistrationTableViewController class]] ||
             [parentController isKindOfClass:[QPLoginViewController class]])
        {
            
//            NSLog(@"Parent class is RegistrationTableViewController");
            BlockActionSheet *alert = [BlockActionSheet sheetWithTitle:nil];
            
            [alert addButtonWithTitle:@"Save" block:^{
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                  
                    [self showHUDWithMessage:@"Uploading photo"];
            
                    
                    
                
                    NSMutableDictionary *parameters = [NSMutableDictionary new];
                    
                    
                    //Perhaps we should include photo dimensions so server can resize properly???
                    
                    parameters[COMMAND]   = UPDATE_PROFILE_PHOTO;
                    parameters[ACTION]    = ADD;
                    parameters[MEDIATYPE] = IMAGE;
                    parameters[IMAGE]     = [self.mediaInfo[DATA] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                
                    dispatch_async(dispatch_get_main_queue(), ^{

                        [KwikcyClientManager sendRequestWithParameters:parameters
                                             withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
                        {
                            [self hideHUDSynch];

                         
                            if (error)
                            {
                                [[Constants alertWithTitle:@"Connection Error"
                                             andMessage:@"Could not send request due to a connection error"] show];
                            }
                            else
                            {
                                KCServerResponse *serverResponse = (KCServerResponse *)response;
                             
                                if (received200Response)
                                {
                                    if (serverResponse.successful)
                                    {
                                        [self performSegueWithIdentifier:@"Go To Main Page" sender:self];
                                        [self performSelector:@selector(retakePhoto) withObject:nil afterDelay:2];
                                    }
                                    else
                                    {
                                        [[Constants alertWithTitle:@"Error" andMessage:serverResponse.message] show];
                                        [self dismissCamera];
                                    }
                                }
                            }
                     
                        }];
                    
                    });
                });
                
            }];
            [alert addButtonWithTitle:@"Retake" block:^{
                [self retakePhoto];
            }];
            
            [alert addButtonWithTitle:@"Cancel" block:^{}];
            [alert addButtonWithTitle:@"" block:^{}];
            [alert addButtonWithTitle:@"" block:^{}];
            [alert addButtonWithTitle:@"" block:^{}];
            
            [alert showInView:self.view];
            return;
        }
        else if ([parentController isKindOfClass:[KCProfileVC class]])
        {
//            NSLog(@"Parent class is KCProfileVC");
        
        
            BlockActionSheet *alert = [BlockActionSheet  sheetWithTitle:nil];
            
            [alert addButtonWithTitle:@"Save" block:^{
                
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    
                    [self showHUDWithMessage:@"Uploading photo"];
                    
                    NSMutableDictionary *parameters = [NSMutableDictionary new];
                    
                    
                    //Perhaps we should include photo dimensions so server can resize properly???
                    
                    parameters[COMMAND]   = UPDATE_PROFILE_PHOTO;
                    parameters[ACTION]    = ADD;
                    parameters[MEDIATYPE] = IMAGE;
                    parameters[IMAGE]     = [self.mediaInfo[DATA] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [KwikcyClientManager sendRequestWithParameters:parameters
                                                 withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
                         {
                             [self hideHUDSynch];
                             
                             
                             if (error)
                             {
                                 [[Constants alertWithTitle:@"Connection Error"
                                                 andMessage:@"Could not send request due to a connection error"] show];
                             }
                             else
                             {
                                 KCServerResponse *serverResponse = (KCServerResponse *)response;
                                 
                                 if (received200Response)
                                 {
                                     if (serverResponse.successful)
                                     {
                                         [self dismissCamera];

//                                         [self performSelector:@selector(retakePhoto) withObject:nil afterDelay:2];
                                     }
                                     else
                                     {
                                         [[Constants alertWithTitle:@"Error" andMessage:serverResponse.message] show];
                                     }
                                 }
                             }
                             
                         }];
                        
                    });
                });
                
            }];
            [alert addButtonWithTitle:@"Retake" block:^{
                [self retakePhoto];
            }];
            
            [alert setCancelButtonWithTitle:@"Cancel" block:^{
//                [self dismissCamera];
            }];
            
            [alert addButtonWithTitle:@"" block:^{}];
            [alert addButtonWithTitle:@"" block:^{}];
            [alert addButtonWithTitle:@"" block:^{}];
            
            [alert showInView:self.view];
        }
        
        else
        {
//            NSLog(@"Parent class is MAIn camera");

            
        
            BlockActionSheet *alert = [BlockActionSheet sheetWithTitle:nil];
            
            [alert addButtonWithTitle:@"Send" block:^{
                [self sendMedia];
            }];
            [alert addButtonWithTitle:@"Save and Send" block:^{
                [self saveAndSendMedia];
            }];

            
            
            if (self.hasPhotoCamera) // && photo was taken
                [alert addButtonWithTitle:@"Retake" block:^{
                    [self retakePhoto];
                }];
    //        else if (self.hasVideoCamera ) //&& video was taken )
    //            [alert addButtonWithTitle:@"Retake" block:^{
    //                [self retakeVideoShot];
    //            }];
            
            [alert setCancelButtonWithTitle:@"Cancel" block:^{
                //            self.photoCaptureButton.hidden = NO;
            }];
            
            [alert addButtonWithTitle:@"" block:^{}];
            [alert addButtonWithTitle:@"" block:^{}];
            [alert addButtonWithTitle:@"" block:^{}];
            
            [alert showInView:self.imageView];
        }
    }
    else
    {
        
//        NSLog(@"ERROR: ");
//        NSLog(@"Parent class is = %@", className);

    }
}




//[self setWhiteScreenToBlack];
//[self fadeInCameraScreenWithDuration:1.5];


-(void)shutDownCamera
{
    if (self.filtersToggleButton.isSelected)
        [self hideFilters];
    
    
    [stillCamera.inputCamera lockForConfiguration:nil];
    [stillCamera stopCameraCapture];
    [stillCamera.inputCamera unlockForConfiguration];

    [self removeAllTargets];

    
    staticPicture = nil;
    self.blurOverlayView = nil;
    self.focusView = nil;
    stillCamera = nil;
    filter      = nil;
    blurFilter  = nil;

    self.viewStatic = NO;
}





// called when we press the SEND BUTTON
-(void) retakePhoto
{
    [self showWhiteScreen];
    
    [self disableCameraButton];
    [self showStillCameraButton];
    
    
    [self resetCameraButtonsForOriginalView];
    
    
    
    staticPicture = nil;
    staticPictureOriginalOrientation = UIImageOrientationUp;
    self.viewStatic = NO;
    [self removeAllTargets];
    
    
    [self setFilterButtonToFirstFilter];
    [self prepareFilter];

    [stillCamera.inputCamera lockForConfiguration:nil];
    [stillCamera resumeCameraCapture];
    [stillCamera.inputCamera unlockForConfiguration];
    
    
//    self.cameraIsReady = YES;
    
    [self enablePhotoCameraButton];
    
    [self hideWhiteScreenWithDuration:1.5];


}


// * XOM  removes camera* by X button
- (IBAction)cancel:(id)sender
{
//    NSLog(@"X button pressed");
    
    Class parentVCClass = [self.parentViewController class];
    NSString *className = NSStringFromClass(parentVCClass);
    
//    NSLog(@"Parent class is = %@", className);
    
    
    
    // Prepare for Registration profile picture
    if ([self.parentViewController isKindOfClass:[UINavigationController class]] &&
        [self.parentViewController.childViewControllers[0] isKindOfClass:[KCProfileVC class]])
    {
        [self dismissCamera];
    }
    else
    {
        [self.QPtabBarDelegate selectTabBarForSentMessage:NO withProgressBar:nil];
        [self shutDownCamera];
    }
}





/*
 *
 * Ways of camera being removed
 *    1) User pressed cancel button
 -- We want to restart the camera
 
 viewwillapear
 if no static photo: set up camera and filters
 ELSE: show everything as is
 
 viewwilldisappear
 do nothing
 segue to Sending View: do nothing
 User pressed cancel button, shut down camera, and still photo, and filters
 
 
 
 *    2) User Pressed Send button
 -- We want to keep the photo and camera as is
 
 
 *    3) User pressed retake button
 reset the camera
 
 
 *    4) User pressed library button
 Camera is still moving, photo not taken
 If user selects library photo, select it
 If user cancels, continue with camera
 
 
 
  Take photo / RetakePhoto
 
 Go to library / cancel library
 
 X out camera / start camera
 
 *
 */






#pragma mark - Library call back functions


#pragma mark - UIImagePickerDelegate


//  *XOM Called when user picks a photo from the libarary
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
//    NSLog(@"imagePickerControllerDidCancel:didFinishPickingMediaWithInfo");

    //After photo is taken this is called, and filters and done button are presented
    
    [self showWhiteScreen];
    
    [self disableCameraButton];
    [self showDoneButton];
    [self disableButtonsForTakePhoto];
    self.libraryToggleButton.hidden = NO;
    
    
    UIImage* outputImage = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if (!outputImage)
    {
        outputImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    if (outputImage)
    {
        self.viewStatic = YES;
        staticPicture = [[GPUImagePicture alloc] initWithImage:outputImage smoothlyScaleOutput:NO];
        staticPictureOriginalOrientation = outputImage.imageOrientation;
       
        
        
//        self.imageView
        //imageView
        [self removeAllTargets];
        
        
        [self setFilterButtonToFirstFilter];
        
        // This will call viewWillAppera
        [self dismissViewControllerAnimated:YES
                                 completion:^{
                                     [self hideWhiteScreenWithDuration:0.5];
                                 }];
        

        /*  
         *  prepareFilter is called in viewwillAppear
         *  [self prepareFilter];
         */

        
        
        if(!self.filtersToggleButton.isSelected){
            [self showFilters];
        }
    }
}


// *XOM Called when user presses cancel button from library
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self showWhiteScreen];

    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 [self hideWhiteScreenWithDuration:0.5];
                             }];
}




// XOM Called by X button
- (void)imagePickerControllerDidCancel
{
    
    NSLog(@"imagePickerControllerDidCancel");
    /* If camera is from preferences/profile, then we have
     * to dismiss the camera to get back to the parent screen
     * Else if camera is the main one from tab controller, then
     * we just need to change back the tab of the one we picked
     */
    
    
    
    Class parentVCClass = [self.parentViewController class];
    NSString *className = NSStringFromClass(parentVCClass);
    
//    NSLog(@"Parent class is = %@", className);
    
    // Prepare for Registration profile picture
    if ([self.parentViewController isKindOfClass:[UINavigationController class]] &&
        [self.parentViewController.childViewControllers[0] isKindOfClass:[KCProfileVC class]])
    {
        [self dismissViewControllerAnimated:YES completion:^{
            [self retakePhoto];
        }];
    }
    else
    {
        [self.QPtabBarDelegate selectTabBarForSentMessage:NO withProgressBar:nil];
        [self shutDownCamera];
    }
}



-(void)dismissCamera
{
    [self.navigationController popViewControllerAnimated:YES];
//    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [self retakePhoto];
}






































-(void)clearVideoCamera
{
    [videoCamera stopCameraCapture];
    
    if (!isVideoRecorded)
        // shut down camera
        [videoCamera stopCameraCapture];
    [self removeAllVideoTargets];
}

-(void)clearPhotoCamera
{
    // shut down camera
    if (!self.isViewStatic)
        [stillCamera stopCameraCapture];
    [self removeAllTargets];
    
}









- (IBAction)handlePan:(UIPanGestureRecognizer *)sender
{
    if (self.blurToggleButton.isSelected) {
        CGPoint tapPoint = [sender locationInView:self.imageView];
        GPUImageGaussianSelectiveBlurFilter* gpu =
        (GPUImageGaussianSelectiveBlurFilter*)blurFilter;
        
        if ([sender state] == UIGestureRecognizerStateBegan) {
            [self showBlurOverlay:YES];
            [gpu setBlurRadiusInPixels:kStaticBlurZeroSize];
//            [gpu setBlurSize:0.0f];
            if (self.isViewStatic) {
                [staticPicture processImage];
            }
        }
        
        if ([sender state] == UIGestureRecognizerStateBegan || [sender state] == UIGestureRecognizerStateChanged) {
            [gpu setBlurRadiusInPixels:0.0f];
            [self.blurOverlayView setCircleCenter:tapPoint];
            [gpu setExcludeCirclePoint:CGPointMake(tapPoint.x/320.0f, tapPoint.y/320.0f)];
        }
        
        if([sender state] == UIGestureRecognizerStateEnded){
            [gpu setBlurRadiusInPixels:kStaticBlurSize];

//            [gpu setBlurSize:kStaticBlurSize];
            
            [self showBlurOverlay:NO];
            if (self.isViewStatic) {
                [staticPicture processImage];
            }
        }
    }
}


- (IBAction)handleTapToFocus:(UITapGestureRecognizer *)tgr
{
    if (!self.isViewStatic && tgr.state == UIGestureRecognizerStateRecognized) {
		CGPoint location = [tgr locationInView:self.imageView];
		AVCaptureDevice *device = stillCamera.inputCamera;
		CGPoint pointOfInterest = CGPointMake(.5f, .5f);
		CGSize frameSize = [[self imageView] frame].size;
		if ([stillCamera cameraPosition] == AVCaptureDevicePositionFront) {
            location.x = frameSize.width - location.x;
		}
		pointOfInterest = CGPointMake(location.y / frameSize.height, 1.f - (location.x / frameSize.width));
		if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            NSError *error;
            if ([device lockForConfiguration:&error]) {
                [device setFocusPointOfInterest:pointOfInterest];
                
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
                
                if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                    [device setExposurePointOfInterest:pointOfInterest];
                    [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                }
                
                self.focusView.center = [tgr locationInView:self.view];
                self.focusView.alpha = 1;
                
                [UIView animateWithDuration:0.5 delay:0.5 options:0 animations:^{
                    self.focusView.alpha = 0;
                } completion:nil];
                
                [device unlockForConfiguration];
			} else {
                NSLog(@"ERROR = %@", error);
			}
		}
	}
}

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)sender
{
    if (self.blurToggleButton.isSelected) {
        CGPoint midpoint = [sender locationInView:self.imageView];
        GPUImageGaussianSelectiveBlurFilter* gpu =
        (GPUImageGaussianSelectiveBlurFilter*)blurFilter;
        
        if ([sender state] == UIGestureRecognizerStateBegan) {
            [self showBlurOverlay:YES];
            [gpu setBlurRadiusInPixels:kStaticBlurZeroSize];
//            [gpu setBlurSize:0.0f];
            if (self.isViewStatic) {
                [staticPicture processImage];
            }
        }
        
        if ([sender state] == UIGestureRecognizerStateBegan || [sender state] == UIGestureRecognizerStateChanged)
        {
            [gpu setBlurRadiusInPixels:kStaticBlurZeroSize];

//            [gpu setBlurSize:0.0f];
            [gpu setExcludeCirclePoint:CGPointMake(midpoint.x/320.0f, midpoint.y/320.0f)];
            self.blurOverlayView.circleCenter = CGPointMake(midpoint.x, midpoint.y);
            CGFloat radius = MAX(MIN(sender.scale*[gpu excludeCircleRadius], 0.6f), 0.15f);
            self.blurOverlayView.radius = radius*320.f;
            [gpu setExcludeCircleRadius:radius];
            sender.scale = 1.0f;
        }
        
        if ([sender state] == UIGestureRecognizerStateEnded) {
            [gpu setBlurRadiusInPixels:kStaticBlurSize];

//            [gpu setBlurSize:kStaticBlurSize];
            [self showBlurOverlay:NO];
            if (self.isViewStatic) {
                [staticPicture processImage];
            }
        }
    }
}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y > 0  ||  scrollView.contentOffset.y < 0 )
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
}



#define FilterHigh 2.5
#define FilterLow  1.9


-(void) showFilters
{
    [self.filtersToggleButton setSelected:YES];

    CGRect sliderScrollFrame = self.filterScrollView.frame;
    
    if (self.photoCaptureButton.isHidden) {
        self.filterPosition = FilterIsLow;
        sliderScrollFrame.origin.y -= (FilterLow *self.filterScrollView.frame.size.height);
    }
    else {
        self.filterPosition = FilterIsHigh;
        sliderScrollFrame.origin.y -= (FilterHigh *self.filterScrollView.frame.size.height);
    }
    
    self.filterScrollView.contentSize = CGSizeMake(self.filterScrollView.contentSize.width,self.filterScrollView.frame.size.height);

    [UIView animateWithDuration:0.10
                          delay:0.05
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.filterScrollView.frame = sliderScrollFrame;
                     }
                     completion:nil];
}

-(void) hideFilters
{
    [self.filtersToggleButton setSelected:NO];
    CGRect sliderScrollFrame = self.filterScrollView.frame;
    
    
    if (self.filterPosition == FilterIsLow)
        sliderScrollFrame.origin.y += ( FilterLow *self.filterScrollView.frame.size.height);
    else if (self.filterPosition == FilterIsHigh)
        sliderScrollFrame.origin.y += ( FilterHigh *self.filterScrollView.frame.size.height);
    
    self.filterPosition = FilterIsHidden;
    
    [UIView animateWithDuration:0.10
                          delay:0.05
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.filterScrollView.frame = sliderScrollFrame;
                     }
                     completion:^(BOOL finished){
                     }];
}

-(IBAction) toggleFilters:(UIButton *)sender
{
//    sender.enabled = NO;
    if (sender.isSelected){
        [self hideFilters];
    } else {
        [self showFilters];
    }
    
}

-(void) showBlurOverlay:(BOOL)show
{
    if(show){
        [UIView animateWithDuration:0.2 delay:0 options:0 animations:^{
            self.blurOverlayView.alpha = 0.7;
        } completion:^(BOOL finished) {
            
        }];
    }else{
        [UIView animateWithDuration:0.35 delay:0.2 options:0 animations:^{
            self.blurOverlayView.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
    }
}


-(void) flashBlurOverlay
{
    [UIView animateWithDuration:0.2 delay:0 options:0 animations:^{
        self.blurOverlayView.alpha = 0.7;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.35 delay:0.2 options:0 animations:^{
            self.blurOverlayView.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
    }];
}








// XOM called when we press DONE BUTTON


#pragma mark Methods that deal with what to do after taking video/image
/* This method returns all the information about the photo/video */
//Done button is pressed and this will be called from Method takePhoto()
//-(void)didFinishPickingMediaWithInfo
//{
//    NSLog(@"didFinishPickingMediaWithInfo");
//  
//    if ([self.parentController isEqualToString:@"QPPreferences"]){
//        BlockActionSheet *alert = [BlockActionSheet  sheetWithTitle:nil];
//        
//        [alert addButtonWithTitle:@"Save" block:^{
//            //[self saveImageForProfile];
//            [QPProfileMethods saveImageForProfile:self.mediaInfo[IMAGE]];
//        }];
//        [alert setCancelButtonWithTitle:@"Cancel" block:^{
//            [self dismissCamera];
//        }];
//
//        [alert showInView:self.view];
//
//    }
//    else {
//
//        BlockActionSheet *alert = [BlockActionSheet  sheetWithTitle:nil];
//        
//        [alert addButtonWithTitle:@"Send" block:^{
//            [self sendMedia];
//        }];
//        [alert addButtonWithTitle:@"Save and Send" block:^{
//            [self saveAndSendMedia];
//        }];
//        [alert addButtonWithTitle:@"Retake" block:^{
//            [self retakePhoto];
//        }];
//        [alert setCancelButtonWithTitle:@"Cancel" block:^{
////            self.photoCaptureButton.hidden = NO;
//        }];
//        
//        [alert addButtonWithTitle:@"" block:^{
//        }];
//        [alert addButtonWithTitle:@"" block:^{
//        }];
//        [alert addButtonWithTitle:@"" block:^{
//        }];
//        
//        [alert showInView:self.view];
//    }
//}

















                   
                     
                     
#pragma mark Methods that deal with saving and sending images, videos


-(void)sendMedia
{
    [self performSegueWithIdentifier:@"Go To Contacts" sender:self.mediaInfo];
}



-(void)saveAndSendMedia
{    
    [self showHUDWithMessageSynch:@"Saving"];

    if ([self.mediaInfo[MEDIATYPE] isEqualToString:IMAGE])
    {
        UIImageWriteToSavedPhotosAlbum(self.mediaInfo[IMAGE], self,
                                       @selector(image:finishedSavingWithError:contextInfo:),
                                       nil);
        
    }
    else
    {
        NSString *moviePath = [self.mediaInfo[MOVIEURL] path];
        if(moviePath){
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(moviePath)){
                UISaveVideoAtPathToSavedPhotosAlbum(moviePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
            }
        }
    }
    
    [self hideHUDSynch];
    
}


// CHANGE TO REMOVE ALERT VIDEO AND SHOW SPINNING PROGRESS BAR
-(void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo
{
    if (error)
        [[Constants alertWithTitle:@"Save failed" andMessage:@"Failed to save video"] show];
    else
        [self sendMedia];
}


-(void)image:(UIImage *)image finishedSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error)
    {
        ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
        
        if (status != ALAuthorizationStatusAuthorized) {
            NSString *message = [NSString stringWithFormat:@"%@ does not have permission to access your photo library.  To change this go to Settings -> Privacy -> Photos and select \"OK\" for %@", APP_NAME, APP_NAME];
            [[Constants alertWithTitle:nil andMessage:message] show];
        }
        else
            [[Constants alertWithTitle:@"Save failed" andMessage:@"Failed to save image"] show];
    }
    else
    {
        [self sendMedia];
    }
}








/* Prepare to segue to other views */
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

    if ([segue.identifier isEqual:@"Go To Contacts"])
    {
        if ([self.mediaInfo[MEDIATYPE] isEqualToString:(NSString *)kUTTypeMovie] ||
            [self.mediaInfo[MEDIATYPE] isEqualToString:(NSString *)kUTTypeVideo])
        {
            self.mediaInfo[MEDIATYPE] = VIDEO;
        }
        
        QPContactsViewController *contactsVC = (QPContactsViewController *)segue.destinationViewController;
        contactsVC.cameraDelegate = self;
        
        
        
        [segue.destinationViewController performSelector:@selector(setMediaInfo:)
                                              withObject:self.mediaInfo];
        
        [segue.destinationViewController performSelector:@selector(setManagedObjectContext:)
                                              withObject:self.managedObjectContext];
        
        [segue.destinationViewController performSelector:@selector(setOperationQueue:)
                                              withObject:self.operationQueue];
    }
}



-(void)messageWasSent:(BOOL)sent withProgressBar:(UIProgressView *)progressBar;
{
    NSLog(@"sendSentMessageToDelegate       Camera Controller 3");

    if (sent)
    {
        [self.QPtabBarDelegate selectTabBarForSentMessage:YES withProgressBar:progressBar];
        [self retakePhoto];
    }
    else
        [self imagePickerControllerDidCancel];
}




-(void) dealloc
{
    [self removeAllTargets];
    stillCamera = nil;

    filter = nil;
    blurFilter = nil;
    staticPicture = nil;
    self.blurOverlayView = nil;
    self.focusView = nil;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];

    [super viewWillDisappear:animated];
}


//TODO: remove this function?
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#endif

@end
