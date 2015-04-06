//
//  QPTableTouchVC.m
//  Quickpeck
//
//  Created by Hanny Aly on 12/31/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "QPTableTouchVC.h"

@interface QPTableTouchVC ()

@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation QPTableTouchVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.canCancelContentTouches = NO;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    QPTableViewTouchCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    
    cell.indexPath = indexPath;
    
    // Configure the cell...
    
    return cell;
}
















-(void)thisTableViewCellIsHeldDownWithIndexpath:(NSIndexPath *)indexPath
{
//    NSLog(@"QPtableView thisTableViewCellIsHeldDown");

    UIImage *image = [UIImage imageNamed:@"launch-image-large"];
    self.imageView =  [[UIImageView alloc] initWithImage:image];

    self.imageView.alpha = 1.0f;
    self.imageView.backgroundColor = [UIColor clearColor];
    
    //Show image
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.parentViewController.view addSubview:self.imageView];
}

-(void)thisTableViewCellIsReleasedWithIndexpath:(NSIndexPath *)indexPath
{
//    NSLog(@"QPtableView thisTableViewCellIsReleased");
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self removeImage];
}

//Screenshot
-(void)thisTableViewCellIsCanceledWithIndexpath:(NSIndexPath *)indexPath
{
//    NSLog(@"QPtableView thisTableViewCellIsCanceled");

    [self removeImage];
}

-(void)thisTableViewCellIsMovedWithIndexpath:(NSIndexPath *)indexPath;

{
//    NSLog(@"QPtableView thisTableViewCellIsMovedWithIndexpath");

}

-(void)removeImage
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.imageView removeFromSuperview];
}





- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    NSLog(@"didselectRowAtIndexPath");
}




@end
