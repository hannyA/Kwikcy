//
//  QPAppDelegate.m
//  Quickpeck
//
//  Created by Hanny Aly on 6/24/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//


#import "QPAppDelegate.h"
#import "QPCoreDataManager.h"
#import "Constants.h"
#import "Received_message+methods.h"
#import "Sent_message+methods.h"

#import "AmazonKeyChainWrapper.h"

#import <AWSRuntime/AmazonErrorHandler.h>


#import "KwikcyAWSRequest.h"



@implementation QPAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;



-(void)setupNavigationBar
{
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = nil;
    
    // Customize the title text for *all* UINavigationBars
    [[UINavigationBar appearance] setTitleTextAttributes:
                                        @{
                                          NSForegroundColorAttributeName: [UIColor redColor],
                                          NSShadowAttributeName: shadow,
                                          NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:22.0]
                                          }];

    [[UINavigationBar appearance] setTintColor:[UIColor redColor]];
    
    [[UINavigationBar appearance] setBarStyle:UIBarStyleDefault];
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
//    [[UINavigationBar appearance] setBackgroundColor:[UIColor whiteColor]];
    
    
//    [[UINavigationBar appearance] setBackgroundImage:[UIImage new]
//                                       forBarMetrics:UIBarMetricsDefault];
    
//    [[UINavigationBar appearance] setShadowImage:[UIImage new]];
    

//    [[UINavigationBar appearance] setTranslucent:YES];

//    
//    [self.navigationBar setBackgroundImage:[UIImage new]
//                                                  forBarMetrics:UIBarMetricsDefault];
//    
//    self.navigationController.navigationBar.shadowImage = [UIImage new];
//    self.navigationController.navigationBar.translucent = YES;
//    
//    
    
    
    
    
//    [[UINavigationBar appearance] setBackIndicatorImage:<#(UIImage *)#>];

    
//    [[UINavigationBar appearance] setTranslucent:YES];
        
    
    
//    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
//                                                  forBarMetrics:UIBarMetricsDefault];
//
//    [[UINavigationBar appearance] setShadowImage:[UIImage new]];
//    self.navigationController.navigationBar.shadowImage = [UIImage new];
//    self.navigationController.navigationBar.translucent = YES;
//    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];

    
}



-(void)setupBarButtons
{
    [[UIBarButtonItem appearance] setTintColor:[UIColor redColor]];
    
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = nil;

    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName: [UIColor redColor],
                                                           NSShadowAttributeName: shadow,
                                                           NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:20.0]
                                                           }
                                                forState:UIControlStateNormal
     ];
}


-(void)setupTabbar
{
    [[UITabBar appearance] setBarTintColor:[UIColor whiteColor]]; // Background color
    [[UITabBar appearance] setTintColor:[UIColor redColor]];  // Selected Item
    [[UITabBar appearance] setBackgroundColor:[UIColor blackColor]];
    
    
    // set color of selected icons and text to red
//    self.tabBar.tintColor = [UIColor redColor];
//    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor redColor], UITextAttributeTextColor, nil] forState:UIControlStateSelected];
//    
//    
//    // set color of unselected text to green
//    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor greenColor], UITextAttributeTextColor, nil]
//                                             forState:UIControlStateNormal];
//    
//    // set selected and unselected icons
//    UITabBarItem *item0 = [self.tabBar.items objectAtIndex:0];
//    
//    // this way, the icon gets rendered as it is (thus, it needs to be green in this example)
//    item0.image = [[UIImage imageNamed:@"unselected-icon.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    
//    // this icon is used for selected tab and it will get tinted as defined in self.tabBar.tintColor
//    item0.selectedImage = [UIImage imageNamed:@"selected-icon.png"];
    
    
    
    
}


-(NSString *)current_month
{
    NSArray *months = @[@"JAN",@"FEB", @"MAR",
                       @"APR", @"MAY", @"JUN",
                       @"JUL", @"AUG", @"SEP",
                       @"OCT", @"NOV", @"DEC"];
    
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
        
    NSDateComponents *components = [gregorian components:NSMonthCalendarUnit
                                                                   fromDate:[NSDate date]];
    return months[[components month]];
}






- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [AmazonErrorHandler shouldNotThrowExceptions];
    
    BOOL ok = [Constants setupKwikcyUrl];
    
    if (!ok){
        NSLog(@"not ok, could not get setupKwikcyUrl because it is set to private");
    }
    
    
//    dispatch_async(queue, ^{
    
        [self setupNavigationBar];
        [self setupTabbar];
//        [self setupBackButtons];
//        [self setupBarButtons];
    
        _managedObjectModel = nil;
        _managedObjectContext = nil;
        _persistentStoreCoordinator = nil;
        
        NSManagedObjectContext *context = [self managedObjectContext];
        if (!context) {
            // Handle the error.
            NSLog(@"Unable to create context");
            return NO;
        }
        else
            [QPCoreDataManager sharedInstance].managedObjectContext = context;

        NSString *launched = @"HasLaunchedOnce";
        if (![[NSUserDefaults standardUserDefaults] boolForKey:launched])
        {
            // app never launched
            // This is the first launch ever
       
            // Add GCD dispatch once
            if (self.managedObjectContext)
            {
                [self.managedObjectContext performBlockAndWait:^{
                    
                    BOOL addedEmptyCellForInbox  = [Received_message addEmptyStringInManagedObjectContext:self.managedObjectContext];
                    BOOL addedEmptyCellForOutbox  = [Sent_message addEmptyStringInManagedObjectContext:self.managedObjectContext];
                    
                    if (addedEmptyCellForInbox && addedEmptyCellForOutbox)
                    {                                      
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:launched];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                }];
            }
        }
        // App has been launched before, and we are setting the inbox month
        //Setup inbox table title and synchronizes

        [Constants InboxTableForMonth];

        
        // Override point for customization after application launch.
        return YES;
//    });
    
                   
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground");

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    
    NSString *username = [AmazonKeyChainWrapper username];
    
    if (username)
    {
        [KwikcyAWSRequest sendScreenShotNotificationToServer:username inManagedObjectContext:self.managedObjectContext];
       
        [KwikcyAWSRequest userIsActive:username];
    }
}




- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self saveContext];
}


- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext == nil) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil) {
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        }
    }
    return _managedObjectContext;
}





// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (!_managedObjectModel) {

//        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"delete_delete" withExtension:@"momd"];
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];

       // _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"delete_delete.sqlite"];
    
    NSError *error = nil;

    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
 
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {

        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

//Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
