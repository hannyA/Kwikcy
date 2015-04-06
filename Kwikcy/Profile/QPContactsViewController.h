//
//  QPContactsViewController.h
//  Quickpeck
//
//  Created by Hanny Aly on 6/27/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//



#import <UIKit/UIKit.h>
#import "FYESendingViewController.h"

@protocol QPCameraDelegate
@optional
-(void)messageWasSent:(BOOL)sent withProgressBar:(UIProgressView *)progressBar;
@end



@interface QPContactsViewController : UITableViewController<QPSendingDelegate>


@property (nonatomic, weak) id <QPCameraDelegate> cameraDelegate;


@property (nonatomic, strong) NSDictionary *mediaInfo;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSOperationQueue *operationQueue;


@end


