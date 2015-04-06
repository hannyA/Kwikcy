//
//  iCarouselExampleViewController.m
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "CarouselExampleViewController.h"


@interface CarouselExampleViewController () <UIActionSheetDelegate>

@property (nonatomic, assign) BOOL wrap;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) NSMutableArray *itemCount;

@end


@implementation CarouselExampleViewController



-(NSArray *)getImages
{
    return [NSArray array];
}


-(NSMutableArray *)items
{
    if (!_items)
        _items = [NSMutableArray array];
    return _items;
}

- (void)setUp
{
    //set up data
    self.wrap = YES;
    
    [self.items addObject:[UIImage imageNamed:@"image-1.jpg"]];
    [self.items addObject:[UIImage imageNamed:@"image-2.jpg"]];
    
    [self.items addObject:[UIImage imageNamed:@"image-3.jpg"]];
    [self.items addObject:[UIImage imageNamed:@"image-4.jpg"]];
    [self.items addObject:[UIImage imageNamed:@"image-5.jpg"]];
    [self.items addObject:[UIImage imageNamed:@"image-6.jpg"]];
    
    
    self.itemCount = [NSMutableArray array];
    for (int i = 0; i < [self.items count]; i++)
    {
        [self.itemCount addObject:@(i)];
    }
    
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSLog(@"initWithCoder");

    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setUp];
    }
    
    return self;
}


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    //    navItem.title = @"CoverFlow2";
    
    //configure carousel
    self.carousel.type = iCarouselTypeLinear;
    [self.carousel setScrollEnabled:NO];

}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.carousel setAutoscroll:-0.5];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [self.carousel setAutoscroll:0];
    
    [super viewDidDisappear:animated];
}

-(BOOL)shouldAutorotate
{
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

//- (IBAction)switchCarouselType
//{
//    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select Carousel Type"
//                                                       delegate:self
//                                              cancelButtonTitle:nil
//                                         destructiveButtonTitle:nil
//                                              otherButtonTitles:@"Linear", @"Rotary", @"Inverted Rotary", @"Cylinder", @"Inverted Cylinder", @"Wheel", @"Inverted Wheel", @"CoverFlow", @"CoverFlow2", @"Time Machine", @"Inverted Time Machine", @"Custom", nil];
//    [sheet showInView:self.view];
//}


//- (IBAction)toggleOrientation
//{
//    //carousel orientation can be animated
//    [UIView beginAnimations:nil context:nil];
//    carousel.vertical = !carousel.vertical;
//    [UIView commitAnimations];
//    
//    //update button
//    orientationBarItem.title = carousel.vertical? @"Vertical": @"Horizontal";
//}

//- (IBAction)toggleWrap
//{
//    self.wrap = !self.wrap;
//    self.wrapBarItem.title = self.wrap? @"Wrap: ON": @"Wrap: OFF";
//    [carousel reloadData];
//}
//
//- (IBAction)insertItem
//{
//    NSInteger index = MAX(0, carousel.currentItemIndex);
//    [self.items insertObject:@(carousel.numberOfItems) atIndex:index];
//    [carousel insertItemAtIndex:index animated:YES];
//}
//
//- (IBAction)removeItem
//{
//    if (carousel.numberOfItems > 0)
//    {
//        NSInteger index = carousel.currentItemIndex;
//        [self.items removeObjectAtIndex:index];
//        [carousel removeItemAtIndex:index animated:YES];
//    }
//}

//- (void)removeItem
//{
//    if (self.carousel.numberOfItems > 0)
//    {
//        NSInteger index = self.carousel.currentItemIndex;
//        [self.items removeObjectAtIndex:index];
//        [self.carousel removeItemAtIndex:index animated:YES];
//    }
//}





#pragma mark -
#pragma mark UIActionSheet methods

//- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
//{
//    NSLog(@"didDismissWithButtonIndex");
//    
//    if (buttonIndex >= 0)
//    {
//        //map button index to carousel type
//        iCarouselType type = buttonIndex;
//        
//        //carousel can smoothly animate between types
//        [UIView beginAnimations:nil context:nil];
//        self.carousel.type = type;
//        [UIView commitAnimations];
//        
//        //update title
//        self.navItem.title = [actionSheet buttonTitleAtIndex:buttonIndex];
//    }
//}

#pragma mark -
#pragma mark iCarousel methods

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    NSLog(@"numberOfItemsInCarousel = %lu", (unsigned long)[self.items count]);
    return [self.items count];
}


//carousel:viewForItemAtIndex:reusingView
//A. You're probably recycling views in your `carousel:viewForItemAtIndex:reusingView:` using the `reusingView` parameter without setting the view contents each time. Study the demo app more closely and make sure you aren't doing all your item view setup in the wrong place.


- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
  
    NSLog(@"viewForItemAtIndex for index = %lu", (unsigned long)index);

    
    
    UIImageView *imageView;
    
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        NSLog(@"view is nil");
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200.0f, 200.0f)];
        ((UIImageView *)view).image = [UIImage imageNamed:@"page.png"];
        view.contentMode = UIViewContentModeCenter;
        
        view.tintColor = [UIColor purpleColor];
        view.backgroundColor = [UIColor redColor];
        
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectInset(view.bounds, 10, 10)];
        imageView.tag = 1;
        [view addSubview:imageView];
        
        
//        imageView.image = self.items[index];
        
        
//        label = [[UILabel alloc] initWithFrame:view.bounds];
//        label.backgroundColor = [UIColor blueColor];
//        
//        label.textAlignment = NSTextAlignmentCenter;
//        label.font = [label.font fontWithSize:50];
//        label.tag = 1;
//        [view addSubview:label];
    }
    else
    {
        NSLog(@" view is not nil");
        //get a reference to the label in the recycled view
//        label = (UILabel *)[view viewWithTag:1];
        imageView = (UIImageView *)[view viewWithTag:1];
    }
    
    //set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
    
    imageView.image = self.items[index];
//  label.text = [self.items[index] stringValue];
    
    return view;
}



- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel
{
    NSLog(@"numberOfPlaceholdersInCarousel");

    //note: placeholder views are only displayed on some carousels if wrapping is disabled
    return 2;
}


- (UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    NSLog(@"placeholderViewAtIndex index = %d", index);
    UILabel *label = nil;
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        //don't do anything specific to the index within
        //this `if (view == nil) {...}` statement because the view will be
        //recycled and used with other index values later
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50.0f, 50.0f)];
        ((UIImageView *)view).image = [UIImage imageNamed:@"blue-green-square.jpg"];
        view.contentMode = UIViewContentModeCenter;
        view.backgroundColor = [UIColor blueColor];
        
        label = [[UILabel alloc] initWithFrame:view.bounds];
        label.backgroundColor = [UIColor redColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [label.font fontWithSize:50.0f];
        label.tag = 1;
        [view addSubview:label];
    }
    else
    {
        NSLog(@"view is not nil");
        //get a reference to the label in the recycled view
        label = (UILabel *)[view viewWithTag:1];
    }
    
    //set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
    label.text = (index == 0)? @"[": @"]";
    
    return view;
}



- (CATransform3D)carousel:(iCarousel *)_carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
{
    NSLog(@"itemTransformForOffset");

    //implement 'flip3D' style carousel
    transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
    return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * self.carousel.itemWidth);
}



- (CGFloat)carousel:(iCarousel *)_carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
//    NSLog(@"valueForOption");
    
    //customize carousel display
    switch (option)
    {
        case iCarouselOptionWrap:
        {
//            NSLog(@"iCarouselOptionWrap");

            //normally you would hard-code this to YES or NO
            return self.wrap;
        }
        case iCarouselOptionSpacing:
        {
//            NSLog(@"iCarouselOptionSpacing");

            //add a bit of spacing between the item views
            return value * 1.05f;
        }
        case iCarouselOptionFadeMax:
        {
//            NSLog(@"iCarouselOptionFadeMax");

            if (self.carousel.type == iCarouselTypeCustom)
            {
                //set opacity based on distance from camera
                return 0.0f;
            }
            return value;
        }
        default:
        {
//            NSLog(@"default");

            return value;
        }
    }
}

#pragma mark -
#pragma mark iCarousel taps

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
//    UIImage *image = self.items[index];
    
//    NSNumber *item = self.items[index];
    NSLog(@"Tapped view number: %ld", (long)index);
}

@end
