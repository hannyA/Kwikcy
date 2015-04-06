//
//  FYESendingViewController.h
//  For Your Eyes
//
//  Created by Hanny Aly on 7/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "QPContactsViewController.h"
#import "JSTokenField.h"


@protocol QPSendingDelegate <NSObject>
-(void)messageWasSent:(BOOL)sent withProgressBar:(UIProgressView *)progressBar;
@end


@interface FYESendingViewController : UIViewController <UIPickerViewDelegate, UIActionSheetDelegate, JSTokenFieldDelegate>

/* mediaInfo is set from MainPage after ImagePicker */
@property (nonatomic, strong) NSDictionary *mediaInfo;
@property (nonatomic, strong) NSMutableArray * contactsList;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSOperationQueue *operationQueue;


@property (nonatomic, weak) id <QPSendingDelegate> delegate;

@end
