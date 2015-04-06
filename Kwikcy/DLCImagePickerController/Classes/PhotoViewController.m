//
//  PhotoViewController.m
//  DLCImagePickerController
//
//  Created by Dmitri Cherniak on 8/18/12.
//  Copyright (c) 2012 Backspaces Inc. All rights reserved.
//

#import "PhotoViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "Constants.h"

@interface PhotoViewController ()

@property (nonatomic, strong) DLCImagePickerController *picker;
@property (nonatomic, strong) NSMutableDictionary *mediaInfo;
@end

@implementation PhotoViewController


-(void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
}

-(void)viewDidLoad
{
    NSLog(@"PhotoViewController viewDidLoad");
    self.picker = [[DLCImagePickerController alloc] init];
    self.picker.delegate = self;
    [self presentViewController:self.picker animated:NO completion:nil];

}



-(void) imagePickerControllerDidCancel:(DLCImagePickerController *)picker
{
    NSLog(@"PhotoViewController imagePickerControllerDidCancel");
    [self dismissViewControllerAnimated:NO completion:nil];
}


-(void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender mediaDictionary:(NSMutableDictionary *)media
{
    [self dismissViewControllerAnimated:NO completion:nil];
    NSLog(@"Perform segue with SendMedia");
    self.mediaInfo = media;
    if ([identifier isEqualToString:@"SendMedia"])
        [self performSegueWithIdentifier:identifier sender:sender];
    
}


/* Prepare to segue to other views */
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"Prepare for segue");
    if ([segue.identifier isEqual:@"SendMedia"])
    {
        if ([self.mediaInfo[MEDIATYPE] isEqualToString:(NSString *)kUTTypeImage])
            self.mediaInfo[MEDIATYPE] = IMAGE;
        else if ([self.mediaInfo[MEDIATYPE] isEqualToString:(NSString *)kUTTypeMovie] || [self.mediaInfo[MEDIATYPE] isEqualToString:(NSString *)kUTTypeVideo]){
            self.mediaInfo[MEDIATYPE] = VIDEO;
        }
        
        [segue.destinationViewController performSelector:@selector(setMediaInfo:)
                                              withObject:self.mediaInfo];
//        [segue.destinationViewController performSelector:@selector(setManagedObjectContext:)
//                                              withObject:self.managedObjectContext];
    }
    
    
}















////From PhotoViewController.m not needed here
//-(void) takePhoto:(id)sender{
//    NSLog(@"PhotoViewController takePhoto");
//    DLCImagePickerController *picker = [[DLCImagePickerController alloc] init];
//    picker.delegate = self;
//    [self presentViewController:picker animated:YES completion:nil];
//}
//
//
//-(void) imagePickerControllerDidCancel:(DLCImagePickerController *)picker
//{
//    NSLog(@"PhotoViewController imagePickerControllerDidCancel");
//    [self dismissViewControllerAnimated:YES completion:nil];
//}
//
//-(void) imagePickerController:(DLCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//{
//    NSLog(@"PhotoViewController imagePickerController:didFinishPickingMediaWithInfo:");
//
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
//    [self dismissViewControllerAnimated:YES completion:nil];
//    
//    if (info) {
//        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//        [library writeImageDataToSavedPhotosAlbum:[info objectForKey:@"data"] metadata:nil completionBlock:^(NSURL *assetURL, NSError *error)
//         {
//             if (error) {
//                 NSLog(@"PhotoViewController.m ERROR: the image failed to be written");
//             }
//             else {
//                 NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
//             }
//         }];
//    }
//}
//
//-(void) viewDidUnload
//{
//    [super viewDidUnload];
//    showPickerButton = nil;
//}
@end
