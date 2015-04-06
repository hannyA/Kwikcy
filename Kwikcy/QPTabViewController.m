//
//  QPTabViewController.m
//  Quickpeck
//
//  Created by Hanny Aly on 7/31/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "QPTabViewController.h"
#import "DLCImagePickerController.h"

#import "QPMailboxCDTVM.h"

#import "QPCoreDataManager.h"
#import "AmazonClientManager.h"
#import "AmazonKeyChainWrapper.h"

#import "QPNetworkActivity.h"

#import "KCSearchTVC.h"
#import "KCProfileVC.h"

#import "KwikcyClientManager.h"
#import "KCServerResponse.h"

#import "User+methods.h"
#import "Constants.h"

#import "KwikcyAWSRequest.h"

//These are tags from the UI Storyboard


typedef enum : NSUInteger {
    QPTabBarHome          = 1,
    QPTabBarMessages      = 2,
    QPTabBarCamera        = 3,
    QPTabBarNotifications = 4,
    QPTabBarSettings      = 5
} QPTabBarType;



@interface QPTabViewController ()
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSUInteger previousViewController;
@property (nonatomic, strong) NSOperationQueue * operationQueue;

@end


@implementation QPTabViewController


-(NSOperationQueue *)operationQueue
{
    if(!_operationQueue){
        _operationQueue = [NSOperationQueue new];
        _operationQueue.maxConcurrentOperationCount = 3;
    }
    return _operationQueue;
}


-(BOOL)prefersStatusBarHidden
{
    NSLog(@"tab bar prefersStatusBarHidden");
    return NO;
}


-(void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;

    self.managedObjectContext = [QPCoreDataManager sharedInstance].managedObjectContext;
    
    self.previousViewController = QPTabBarHome;

//    KCSearchTVC *searchContoller = [[[self.viewControllers objectAtIndex:0] viewControllers] objectAtIndex:0] ;

//    [searchContoller performSelector:@selector(setOperationQueue:) withObject:self.operationQueue];
    
}







-(NSUInteger)getTabBarIndex:(NSUInteger)tabbar
{
    return tabbar -1;
}



-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
}



-(void)selectTabBarForSentMessage:(BOOL)sentMessage withProgressBar:(UIProgressView *)progressBar
{
    NSLog(@"sendSentMessageToDelegate       TabBar Controller 4");

    NSLog(@"selectTabBarForSentMessage sentMessage");
    
    if(sentMessage)
    {
       
        NSUInteger indexViewController =  [self getTabBarIndex:QPTabBarMessages];
        
        UIViewController * viewController = [self.viewControllers objectAtIndex:indexViewController];

        NSArray *arrayOfViewControllers = [viewController childViewControllers];

        UIViewController * controller = [arrayOfViewControllers firstObject];

        ((QPMailboxCDTVM *)controller).mailBoxOutBoxShowing = YES;

        [self tabBarController:self.tabBarController shouldSelectViewController:viewController];
        
        
        self.selectedIndex = indexViewController;

        //        UIViewController * viewController = [self.viewControllers objectAtIndex:self.selectedIndex];
//      
//        NSArray *arrayOfViewControllers = [viewController childViewControllers];
//        
//        UIViewController * controller = [arrayOfViewControllers firstObject];
//        
//        ((QPMailboxCDTVM *)controller).mailBoxOutBoxShowing = YES;
//        
//        [self tabBarController:self.tabBarController shouldSelectViewController:viewController];
        
//        [self.navigationController popToRootViewControllerAnimated:NO];


    }
    else
    {
        [self setSelectedIndex:[self getTabBarIndex:self.previousViewController]];
    }
}



#define FIRST_VIEW_CONTROLLER_IN_TABBAR_SELECTION 0

-(BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    NSLog(@"TAB BAR shouldSelectViewController");
    if (self.disableTabBarButtons)
        return NO;
    
    
    if (viewController.tabBarItem.tag == QPTabBarHome)
    {
        //KCSearchTVC *searchContoller =  [[(UINavigationController *)viewController viewControllers] objectAtIndex:FIRST_VIEW_CONTROLLER_IN_TABBAR_SELECTION];
        //[searchContoller performSelector:@selector(setOperationQueue:) withObject:self.operationQueue];
        self.previousViewController = viewController.tabBarItem.tag;

    }
    
    else if (viewController.tabBarItem.tag == QPTabBarMessages)
    {
        self.previousViewController = viewController.tabBarItem.tag;
    }
    
    else if (viewController.tabBarItem.tag == QPTabBarCamera)
    {
        DLCImagePickerController *dlcIPVC = [[(UINavigationController *)viewController viewControllers] objectAtIndex:0];
        
        dlcIPVC.QPtabBarDelegate = self;
        
        [dlcIPVC performSelector:@selector(setPreviousViewControllerValue:) withObject:[NSNumber numberWithInteger:self.previousViewController]];
        [dlcIPVC performSelector:@selector(setOperationQueue:) withObject:self.operationQueue];
    }
    
    else if (viewController.tabBarItem.tag == QPTabBarNotifications)
    {
        NSLog(@"QPTabBarNotifications");

        self.previousViewController = viewController.tabBarItem.tag;
    }
    else
    {
        KCProfileVC *profileController =[[(UINavigationController *)viewController viewControllers] objectAtIndex:FIRST_VIEW_CONTROLLER_IN_TABBAR_SELECTION];
        [profileController performSelector:@selector(setOperationQueue:) withObject:self.operationQueue];
        self.previousViewController = viewController.tabBarItem.tag;
    }

    return YES;
    
}



@end
