//
//  QPAppDelegate.h
//  Quickpeck
//
//  Created by Hanny Aly on 6/24/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QPAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end
