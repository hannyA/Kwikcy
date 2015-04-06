//
//  KCCameraVC.m
//  Kwikcy
//
//  Created by Hanny Aly on 6/2/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCCameraVC.h"

@interface KCCameraVC ()
@property (nonatomic, strong)  UIImagePickerController  *imagePickerController;
@property (strong, nonatomic)        NSMutableDictionary     *mediaInfo;

@end

@implementation KCCameraVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
   

}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.delegate = self;
    
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    
    self.imagePickerController.cameraDevice= UIImagePickerControllerCameraDeviceRear;
    
    self.imagePickerController.showsCameraControls = YES;
    self.imagePickerController.navigationBarHidden = NO;
    
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(BOOL)prefersStatusBarHidden
{
    return YES;
}




-(NSMutableDictionary *)mediaInfo
{
    if (!_mediaInfo)
        _mediaInfo = [NSMutableDictionary dictionary];
    return _mediaInfo;
}


-(void)messageWasSentForImagePicker:(NSNumber *)sent
{
    if ([sent boolValue]){
        [self.QPtabBarDelegate selectSentMessagesTabBar];
    }
    else
        [self imagePickerControllerDidCancel];
}

-(void)messageWasSent:(NSNumber *)yes
{
    if ([yes integerValue] > 0){
        [self.QPtabBarDelegate selectSentMessagesTabBar];
//        [self retakePhoto:nil];
    }
    else
        [self imagePickerControllerDidCancel];
}




- (void)imagePickerControllerDidCancel
{
    
}


//Called by library cancel button
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    NSLog(@"imagePickerControllerDidCancel picker");
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.delegate imagePickerControllerDidCancel:self];
    
    
//    if (isStatic) { //Should never occur
//        // TODO: fix this hack
//        [self dismissViewControllerAnimated:YES completion:nil];
//        [self.delegate imagePickerControllerDidCancel:self];
//    } else {
//        [self dismissViewControllerAnimated:YES completion:nil];
//        [self retakePhoto:nil];
//    }
}





/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end









