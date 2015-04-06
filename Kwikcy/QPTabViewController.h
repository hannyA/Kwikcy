//
//  QPTabViewController.h
//  Quickpeck
//
//  Created by Hanny Aly on 7/31/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DLCImagePickerController.h"

@interface QPTabViewController : UITabBarController< UITabBarControllerDelegate, QPTabBarDelegate>

@property (nonatomic) BOOL disableTabBarButtons;

@end
