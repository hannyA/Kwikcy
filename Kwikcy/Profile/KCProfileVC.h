//
//  KCProfileVC.h
//  Quickpeck
//
//  Created by Hanny Aly on 4/2/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//


/*
 *  Used for my own profile and settings
 */
#import <UIKit/UIKit.h>
#import "DLCImagePickerController.h"
#import "KCProfileImageDownloader.h"

@interface KCProfileVC : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate, ProfilePhotoDelegate>
//, AsyncProfileImageControllerProtocolDelegate>

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end
