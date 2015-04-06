//
//  KCCameraVC.h
//  Kwikcy
//
//  Created by Hanny Aly on 6/2/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FYESendingViewController.h"

@class KCCameraVC;

@protocol KCCameraVCDelegate <NSObject>
@optional
- (void)imagePickerController:(KCCameraVC *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)imagePickerControllerDidCancel:(KCCameraVC *)picker;

-(void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender mediaDictionary:(NSDictionary *)mediaInfo;
@end


@protocol QPTabBarDelegate <NSObject>
@optional
- (void)selectSentMessagesTabBar;
@end




@interface KCCameraVC : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, FYESendingViewControllerDelegate>


@property (nonatomic, weak) id <KCCameraVCDelegate> delegate;
@property (nonatomic, weak) id <QPTabBarDelegate> QPtabBarDelegate;


@property (nonatomic, strong) NSNumber *previousViewControllerValue;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@property (nonatomic, strong) NSString *parentController;




@end
