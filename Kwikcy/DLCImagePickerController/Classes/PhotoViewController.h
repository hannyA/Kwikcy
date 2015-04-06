//
//  PhotoViewController.h
//  DLCImagePickerController
//
//  Created by Dmitri Cherniak on 8/18/12.
//  Copyright (c) 2012 Backspaces Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DLCImagePickerController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface PhotoViewController : UIViewController<DLCImagePickerDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

-(void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end