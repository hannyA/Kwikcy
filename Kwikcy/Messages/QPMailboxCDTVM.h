//
//  QPMailboxCDTVM.h
//  Quickpeck
//
//  Created by Hanny Aly on 7/12/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "CoreDataTableViewController.h"
#import <AWSRuntime/AWSRuntime.h>

@interface QPMailboxCDTVM : UITableViewController

@property (nonatomic, getter = isMailBoxOutboxShowing) BOOL mailBoxOutBoxShowing;

- (IBAction)userDidChangeMailbox:(UISegmentedControl *)sender;

@end
