//
//  KCSearchTVC.m
//  Quickpeck
//
//  Created by Hanny Aly on 2/1/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//


/*
 * This class is used to search for users by their username 
 * and the mobile number, only if your mobile number is confirmed
 */

#import "KCSearchTVC.h"
#import <AWSDynamoDB/AWSDynamoDB.h>

#import "Constants.h"
#import "AmazonClientManager.h"

#import "User+methods.h"
#import "QPCoreDataManager.h"
#import "KCProfileImageDownloader.h"


#import "KCServerResponse.h"

#import "KwikcyClientManager.h"
#import "NSString+validate.h"

#import "QPNetworkActivity.h"

#import "AmazonKeyChainWrapper.h"



#import "KwikcyAWSRequest.h"

#import "iCarousel.h"


enum ActivityStatus:NSUInteger {
    UserIsNotTyping,
    UserWillTypeForUsername,
    UserWillTypeForMobile,
    UserIsTypingForUsername,
    UserIsTypingForMobile,
    SearchingIsNotBeingDone,
    SearchingForUsernameIsInProcess,
    SearchingForMobileIsInProcess
};





enum ScopeIndex:NSUInteger {
    UsernameScopeIndex,
    MobileScopeIndex
};




/* Caraousel options */

#define FriendsView @"FriendsView"
#define WorldView   @"WorldView"


#define STOP   0
#define START -0.5








@interface KCSearchTVC ()<iCarouselDataSource, iCarouselDelegate>

@property (nonatomic, getter = onMainScreen) BOOL mainScreen;

@property (nonatomic) NSUInteger activityStatus;


@property (nonatomic) BOOL showUsers;
@property (nonatomic) BOOL showMobileUsers;






@property (strong, nonatomic) UIActivityIndicatorView   *activityIndicator;
@property (nonatomic, strong) NSManagedObjectContext    *managedObjectContext;
@property (nonatomic, strong) NSMutableDictionary       *userInfo;

@property (nonatomic, strong) id keyboardInfo;
@property (strong, nonatomic) IBOutlet UITableView *mainScreenTableView;



@property (nonatomic, strong) NSString *usernameStorage;
@property (nonatomic, strong) NSString *mobileNumberStorage;

@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic, strong) NSMutableArray *mobileUsers;


@property (nonatomic, strong) UIActivityIndicatorView *spinningWheel;



        /* Carousel properties */
@property (nonatomic, strong) NSMutableArray *carouselPhotos;
@property (nonatomic, strong) NSMutableArray *carouselPrefetchInfo;
@property (atomic, getter = didStartPhotoRequest) BOOL                     startedPhotoRequest;



@property (strong, nonatomic) iCarousel *carousel;
@property (strong, nonatomic) UILabel *carouselLabel;
@property (nonatomic, strong) UIActivityIndicatorView *carouselSpinningWheel;



@property (nonatomic, assign) BOOL wrap;


@property (nonatomic) NSUInteger returnCount;

@end




@implementation KCSearchTVC






-(BOOL)prefersStatusBarHidden
{
    return NO;
}



-(void)viewWillDisappear:(BOOL)animated
{
    [self stopCarousel];
    
    [super viewWillDisappear:animated];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.managedObjectContext = [QPCoreDataManager sharedInstance].managedObjectContext;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.spinningWheel];
    
    self.tableView.tag = 2;
    self.mainScreen = YES;
    
    
    
    //configure carousel
//    self.wrap = YES;
//
//    self.carousel.type = iCarouselTypeLinear;
//    [self.carousel setScrollEnabled:NO];
    
    
    
//    self.carousel.gestureRecognizers = nil;

    
    
    //
    //    Class parentVCClass = [self.parentViewController class];
    //    NSString *className = NSStringFromClass(parentVCClass);
    //    NSLog(@"Parent class is = %@", className);
    //
    
    
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Sets the background view to the large blue eye image
    //    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]];
    //    [tempImageView setFrame:self.tableView.frame];
    //    self.tableView.backgroundView = tempImageView;
    
    
    //    self.searchBar.backgroundView = tempImageView;
    //    self.searchDisplayController.searchResultsTableView.backgroundView = tempImageView;
    
    
    
    //    self.scopeIndex = UsernameScopeIndex;
    //
    //    if ( [(NSString*)self.searchDisplayController.searchBar.scopeButtonTitles[0] isEqualToString:@"Mobile"])
    //    {
    //        NSLog(@"first");
    //        self.sco = 0;
    //        self.usernameScopeIndex = 1;
    //    }
    //    else
    //    {
    //        self.mobileScopeIndex = 1;
    //        self.usernameScopeIndex = 0;
    //    }
}





-(NSMutableArray *)users
{
    if (!_users)
        _users = [[NSMutableArray alloc] init];
    return _users;
}


-(UIActivityIndicatorView *)spinningWheel
{
    if (!_spinningWheel)
    {
        _spinningWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _spinningWheel.color = [UIColor redColor];
        _spinningWheel.hidesWhenStopped = YES;
    }
    return _spinningWheel;
}


-(void)setCarouselSpinningWheel:(UIActivityIndicatorView *)carouselSpinningWheel
{
    _carouselSpinningWheel = carouselSpinningWheel;
    _carouselSpinningWheel.color = [UIColor whiteColor];
    _carouselSpinningWheel.hidesWhenStopped = YES;
    [_carouselSpinningWheel startAnimating];
}




/*  Called only once in cellForRow  */

-(void)setCarousel:(iCarousel *)carousel
{
    _carousel = carousel;
    
    if (_carousel)
    {
        [self setupCarousel];
        [self startCarousel];
    }
    else
    {
        [self stopCarousel];
    }
}



#define PHOTOS_NEEDED_TO_AUTOSCROLL         5
#define MINIMUM_NUMBER_OF_PREFETCHED_INFO   10

#define NUMBER_OF_PHOTOS_TO_GET      5

#define PRESIGNED_INFO_CAPACITY      20


-(NSMutableArray *)carouselPhotos
{
    if (!_carouselPhotos)
        _carouselPhotos = [NSMutableArray new];
    
    
//    if ([_carouselPhotos count] == 0)
//    {
//        [self stopCarousel];
//    }
    
    
    return _carouselPhotos;
}


-(NSMutableArray *)carouselPrefetchInfo
{
    if (!_carouselPrefetchInfo)
        _carouselPrefetchInfo = [NSMutableArray new];
    return _carouselPrefetchInfo;
}





/*
 *  How it works
 *  1) We start carousel
 2) If photo array is empty or less than 5, go get 5 more
 3) Asynch get 5 photos and load them into photo array
 If photoInfo is 5 or less, go get 20 more filepaths, possibly more 40?
 
 
 4) Each time we have less than 5 photos go get more.
 */






-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if([self isCarouselSet])
    {
        [self setupCarousel];
        [self startCarousel];
    }
}


//configure carousel

-(void)setupCarousel
{
    self.wrap = YES;
    self.carousel.type = iCarouselTypeLinear;
}


// returns boolean value if the carousel has been set in cellForRow

-(BOOL)isCarouselSet
{
    if (self.carousel)
        return YES;
    return NO;
}


// hides carousel, hides the behaving label and stops the carousel
-(void)carouselWillStart
{
    if (!self.carousel.isHidden)
        self.carousel.hidden = YES;
    
    [self hideWellBehavingLabel];
    
    if ([self.carousel autoscroll])
        [self.carousel setAutoscroll:STOP];
}


-(BOOL)doesCarouselHaveEnoughPhotosToStart
{
    NSLog(@"doesCarouselHaveEnoughPhotosToStart > ? ");
    
    if ([self.carouselPhotos count] > PHOTOS_NEEDED_TO_AUTOSCROLL)
    {
        return YES;
    }
    return NO;
}




//Set atomic 
//-(void)setReturnCount:(NSUInteger)returnCount
//{
//    @synchronized(self)
//    {
//        _returnCount++;
//    }
//}


-(void)incrementReturnCount
{
    @synchronized(self)
    {
        self.returnCount++;
    }
}

-(BOOL)returnCountMatchesNumberOfPhotos:(NSInteger)photos
{
    if (self.returnCount == photos)
        return YES;
    return NO;
}



-(void)carouselStart
{
    NSLog(@"carousel started");

    if ([self.carouselSpinningWheel isAnimating])
    {
        [self.carouselSpinningWheel stopAnimating];
    }
    
    if (self.carousel.isHidden)
        self.carousel.hidden = NO;
    [self.carousel setAutoscroll:START];
    self.carouselLabel.hidden = YES;
    
}


-(void)carouselDidStart
{
    
}




-(void)carouselWillStop
{
    self.carousel.hidden = YES;
}



-(void)carouselDidStop
{
    if ([self.carousel autoscroll])
        [self.carousel setAutoscroll:STOP];
}



-(void)stopCarouselSpinningWheel
{
    if ([self.carouselSpinningWheel isAnimating])
    {
        [self.carouselSpinningWheel stopAnimating];
    }
}


-(void)hideWellBehavingLabel
{
    self.carouselLabel.hidden = YES;
}

-(void)showWellBehavingLabel
{
    self.carouselLabel.hidden = NO;
}



-(void)hideCarouselAndHideCarouselSpinningWheel
{
    [self carouselWillStop];
    [self carouselDidStop];
    
    if ([self.carouselSpinningWheel isAnimating])
    {
        [self.carouselSpinningWheel stopAnimating];
    }
    
    //Here show message that there are no photos
}





-(void)getNextPhotos
{
    
}




//                   Start here
//   1) Now for each filepath, do a batchgetItem from s3
//   2) Add images to an array
//   3) Turn off the spinning wheel
//   4) And start the carousel


#define DATA_FRIEND @"F" //TODO: next update of java code, we change this to DATA

/* Doesn't need to be asynch , Get's called once when we're below x=10 photos*/

-(void)getNextPreSignedPhotosInfo
{
    NSMutableDictionary *variables = [NSMutableDictionary new];
    
    variables[COMMAND]    = GET_CAROUSEL_PHOTOS;
    variables[ACTION]     = FriendsView;
    
    NSLog(@"startCarousel: carouselPhotos is emptty");
    
    [KwikcyClientManager sendRequestWithParameters:variables
                             withCompletionHandler:^(BOOL receieved200Response, Response *response, NSError *error)
     {
         
         NSLog(@"startCarousel: got info");
         
         [self stopCarouselSpinningWheel];

         
         if ( !error )
         {
             if (receieved200Response)
             {
                 KCServerResponse *serverResponse = (KCServerResponse *)response;
                 if (serverResponse.successful)
                 {
                     NSArray *serverList = serverResponse.info[DATA];
                     
                     NSLog(@"serverList count:%lu", (unsigned long)[serverList count]);
                     
                     NSMutableArray * newDataItems = [NSMutableArray arrayWithCapacity:PRESIGNED_INFO_CAPACITY];
                     
                     for (NSDictionary *item in serverList)
                     {
                         NSString *filepath = item[FILEPATH];
                         NSString *username = item[USERNAME];
                         NSLog(@"filepath is: %@", filepath);
                         NSLog(@"username is: %@", username);
                         [newDataItems addObject:[NSMutableDictionary dictionaryWithDictionary:item]];
                     }
                     
                     [self.carouselPrefetchInfo addObjectsFromArray:newDataItems];
                     
                     
                     NSMutableArray *firstItemsToGet = [NSMutableArray arrayWithCapacity:NUMBER_OF_PHOTOS_TO_GET];

                     int count = [self.carouselPrefetchInfo count];
                     for (int i = 0; ( i < count && i < NUMBER_OF_PHOTOS_TO_GET ); i++)
                     {
                         // NSMutableDictionary * info = [newDataItems objectAtIndex:i];
                         NSMutableDictionary * info = [self.carouselPrefetchInfo firstObject];

                         [firstItemsToGet addObject:info];
                         [self.carouselPrefetchInfo removeObject:info];
                     }
                     
                     
                     [self getPhotosInCarouselInfo:firstItemsToGet];
                     
                 }
                 else
                 {
                     NSLog(@"startCarousel unsuccessful is: %@", serverResponse.message);
                 }
             }
             else
             {
                 NSLog(@"startCarousel not 200 unsucess is: %@", response.message);
             }
         }
         else
         {
             NSLog(@"startCarousel Error: %@" ,error.description);
         }
     }];
}


-(void)starting
{
    if ([self doesCarouselHaveEnoughPhotosToStart])
    {
        [self carouselStart];
    }
    else
    {
        // let us sleep for a while ?? start a timer
    }
}
//
//
//-(void)runCarousel
//{
//    NSLog(@"runCarousel");
//    
//    [self carouselWillStart];
//    
//
//}
//



-(void)startCarousel
{
    NSLog(@"startCarousel");
    
    [self carouselWillStart];
    
    // if we have photos, start carousel
    if ([self.carouselPhotos count])
    {
        NSLog(@"startCarousel we have photos in array");

        [self carouselStart];
    }
    else if ([self.carouselPrefetchInfo count])
    {
        NSLog(@"startCarousel we dont have photos, but we have info");

        if ([self.carouselPrefetchInfo count] < MINIMUM_NUMBER_OF_PREFETCHED_INFO)
        {
            [self getNextPreSignedPhotosInfo];
        }
        
        // transfer photos Info to small array and go get photos
        NSMutableArray *newItemsToGet = [NSMutableArray arrayWithCapacity:MINIMUM_NUMBER_OF_PREFETCHED_INFO];
        
        for (int i = 0; i < [self.carouselPrefetchInfo count] && i < NUMBER_OF_PHOTOS_TO_GET; i++)
        {
            NSMutableDictionary * info = [self.carouselPrefetchInfo firstObject];
            
            [newItemsToGet addObject:info];
            [self.carouselPrefetchInfo removeObject:info];
        }
        
        [self getPhotosInCarouselInfo:newItemsToGet];
        
    }
    else
    {
        NSLog(@"startCarousel we dont have photos or any info, going to go get some");

        [self getNextPreSignedPhotosInfo];
    }
    
    
    
    return;
//    
//    
//    // If photo array is empty
//    if (![self.carouselPhotos count] && ![self.carouselPrefetchInfo count])
//    {
//        [self getNextPreSignedPhotosInfo];
//    }
//    else if (![self doesCarouselHaveEnoughPhotosToStart])
//    {
//        
//        if ([self.carouselPrefetchInfo count] < MINIMUM_NUMBER_OF_PREFETCHED_INFO)
//        {
//            if (![self.carouselPrefetchInfo count])
//            {
//                [self getNextPreSignedPhotosInfo];
//            }
//            else
//            {
//                NSMutableArray *newItemsToGet = [NSMutableArray arrayWithCapacity:[self.carouselPrefetchInfo count]];
//                
//                for (int i = 0; i < [self.carouselPrefetchInfo count]; i++)
//                {
//                    NSMutableDictionary * info = [self.carouselPrefetchInfo firstObject];
//                    
//                    [newItemsToGet addObject:info];
//                    [self.carouselPrefetchInfo removeObject:info];
//                }
//                
//                [self getPhotosInCarouselInfo:newItemsToGet];
//                
//                [self getNextPreSignedPhotosInfo];
//            }
//        }
//        else
//        {
//            NSMutableArray *newItemsToGet = [NSMutableArray arrayWithCapacity:MINIMUM_NUMBER_OF_PREFETCHED_INFO];
//            
//            for (int i = 0; i < [self.carouselPrefetchInfo count] && i < NUMBER_OF_PHOTOS_TO_GET; i++)
//            {
//                NSMutableDictionary * info = [self.carouselPrefetchInfo firstObject];
//                
//                [newItemsToGet addObject:info];
//                [self.carouselPrefetchInfo removeObject:info];
//            }
//            
//            [self getPhotosInCarouselInfo:newItemsToGet];
//        }
//    }
}


-(void)stopCarousel
{
    
    [self carouselWillStop];
    [self carouselDidStop];
}





- (void)setUp
{
    //set up data
    
//    [self.items addObject:[UIImage imageNamed:@"image-1.jpg"]];
//    [self.items addObject:[UIImage imageNamed:@"image-2.jpg"]];
//
//    [self.items addObject:[UIImage imageNamed:@"image-3.jpg"]];
//    [self.items addObject:[UIImage imageNamed:@"image-4.jpg"]];
//    [self.items addObject:[UIImage imageNamed:@"image-5.jpg"]];
//    [self.items addObject:[UIImage imageNamed:@"image-6.jpg"]];
//
//
//    self.itemCount = [NSMutableArray array];
//    for (int i = 0; i < [self.items count]; i++)
//    {
//        [self.itemCount addObject:@(i)];
//    }
    
}


/* 
 *      TODO: THIS ALL MUST BE CHANGED, 
 *      ALL PHOTOS MUST BE DOWNLOADED THROUGH ELASTIC BEANSTALK
 */

-(void)getPhotosInCarouselInfo:(NSMutableArray *)newInfo
{
    NSLog(@"getPhotosInCarouselInfo count = %lu", (unsigned long)[newInfo count]);
    
    NSUInteger photoCount = [newInfo count];
    for (int i = 0; i < photoCount; i++)
    {
        NSMutableDictionary * info = [newInfo objectAtIndex:i];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            // Puts the file as an object in the bucket.
            NSLog(@"info[FILEPATH = %@" ,info[FILEPATH]);
                                              
            S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc] initWithKey:info[FILEPATH]
                                                                                withBucket:BUCKET_NAME];
            
            [[QPNetworkActivity sharedInstance] increaseActivity];
            S3GetObjectResponse *response = [[AmazonClientManager s3] getObject:getObjectRequest];
            [[QPNetworkActivity sharedInstance] decreaseActivity];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSLog(@"Carousel dispatch_get_main_queue got photo");
                if (!response.error)
                {
                    
//                    Call another asynch function to delete photo from s3 and from dynamoDB
                    
                    
                    NSLog(@"Carousel large phtotofe no ERROR");
                    
                    NSData *data = response.body;
                    
                    if (data)
                    {
                        info[DATA] = data;
                        
                        [self.carouselPhotos addObject:info];
                    }
                }
                else
                    NSLog(@"Carousel large phtotofe ERROR %@", response.error);
                
                
                // Cuplprits
                [self incrementReturnCount];
                
                
                if ([self doesCarouselHaveEnoughPhotosToStart])
                {
                    [self carouselStart];
                }
                
                
                else if (self.returnCount == photoCount)
                {
                    [self carouselStart];
                }
                
            });
        });
    }
}


#pragma mark -
#pragma mark iCarousel methods

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    NSLog(@"numberOfItemsInCarousel = %lu", (unsigned long)[self.carouselPhotos count]);
    return [self.carouselPhotos count];
}


//carousel:viewForItemAtIndex:reusingView
//A. You're probably recycling views in your `carousel:viewForItemAtIndex:reusingView:` using the `reusingView` parameter without setting the view contents each time. Study the demo app more closely and make sure you aren't doing all your item view setup in the wrong place.



- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    NSLog(@"viewForItemAtIndex:reusingView:");
    UIImageView *imageView;
    
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        //        NSLog(@"view is nil");
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200.0f, 200.0f)];
        ((UIImageView *)view).image = [UIImage imageNamed:@"page.png"];
        view.contentMode = UIViewContentModeCenter;
        
        view.tintColor = [UIColor purpleColor];
        view.backgroundColor = [UIColor redColor];
        
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectInset(view.bounds, 10, 10)];
        imageView.tag = 1;
        [view addSubview:imageView];
    }
    else
    {
        //        NSLog(@" view is not nil");
        //get a reference to the label in the recycled view
        //        label = (UILabel *)[view viewWithTag:1];
        imageView = (UIImageView *)[view viewWithTag:1];
    }
    
    //set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
    
//    
//    allData[FILEPATH] = filepath;
//    allData[USERNAME] = username;
//    allData[DATA]     = data;
//    
//    [self.carouselPhotos addObject:allData];

    
    NSData * data = self.carouselPhotos[index][DATA];
    
    imageView.image = [UIImage imageWithData:data];
    
    //  label.text = [self.carouselItems[index] stringValue];
    
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
    NSLog(@"placeholderViewAtIndex index = %lu", (unsigned long)index);
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
    NSLog(@"valueForOption");
    
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






#pragma mark - iCarousel taps




- (void)removeItemAtIndex:(NSInteger)index animated:(BOOL)animated
{
    
}


- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel
{
    NSLog(@"carouselCurrentItemIndexDidChange");
    
    //
    //    NSUInteger *firstItem = [self.carouselItems firstObject];
    //    [self.carouselItems remove];
    //
    /*
     
     Remove item from data array
     
     and count number of items in array
     
     When we reach 3 images left , call for more images, reload data
     
     if no more images, pause the stream (autoscroll = 0)
     and show UIActivityIndicator
     
     
     loading still images vs carousel - purpose is to allow people a one time view vs.
     
     Med vs large
     if large one large image scrolls on screen?
     
     if medium
        -  we have to transfer two set of images. normal photo and scaled photo
        -  scroll an image one at a time. allow user to select and view full size
        -  scroll all images carousel style
        -
     
     */
}



#pragma mark -
#pragma mark iCarousel taps

-(BOOL)carousel:(iCarousel *)carousel shouldSelectItemAtIndex:(NSInteger)index
{
    NSLog(@"shouldSelectItemAtIndex");
    return YES;
}


- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
    NSLog(@"Carousel: didSelectItemAtIndex: Tapped view number: %ld", (long)index);
    
    NSDictionary * dictionary = self.carouselPhotos[index];
    
    [self performSegueWithIdentifier:@"ShowImage" sender:dictionary];
}



//-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    if ([segue.identifier isEqual:@"ShowImage"])
//    {
//        NSDictionary * dictionary = (NSDictionary *)sender;
//        NSString *key = [[dictionary allKeys] firstObject];
//        
//        UIImage *image = dictionary[key];
//        [((KCImageViewController *)segue.destinationViewController) startActivityIndicator];
//        
//        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//            
//            // simulate a network call
//            sleep(3);
//            
//            UIImage *bigImage = [self asynchronousCallToGetImageForKey:key];
//            
//            // TODO: change this for getting image for s3
//            if (!bigImage)
//                bigImage = image;
//            NSLog(@"setimage");
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [((KCImageViewController *)segue.destinationViewController) setImage:bigImage];
//            });
//        });
//    }
//}







//[self.carouselPrefetchInfo addObject:[NSMutableDictionary dictionaryWithDictionary:item]];

-(NSMutableArray *)goGetMorePhotosInfo
{
    
//    NSMutableDictionary *variables = [NSMutableDictionary new];
//    
//    variables[COMMAND]    = GET_CAROUSEL_PHOTOS;
//    variables[ACTION]     = WorldView;
//    
//    [KwikcyClientManager sendRequestWithParameters:variables
//                             withCompletionHandler:^(BOOL receieved200Response, Response *response, NSError *error)
//     {
//         if (!error)
//         {
//             if (receieved200Response)
//             {
//                 KCServerResponse *serverResponse = (KCServerResponse *)response;
//                 if (serverResponse.successful)
//                 {
//                     
//                     NSMutableArray *items = [NSMutableArray array];
//                     
//                     NSArray *serverList = serverResponse.info[DATA];
//                     
//                     for (NSDictionary *item in serverList)
//                     {
//                         NSString *filepath = item[FILEPATH];
//                         NSString *username = item[USERNAME];
//                         NSLog(@"filepath is: %@", filepath);
//                         NSLog(@"username is: %@", username);
//                         
//                         [items addObject:[NSMutableDictionary dictionaryWithDictionary:item]];
//                         
//                         for (int i = 0; i < [self.carouselPrefetchInfo count]; i++) {
//                             NSLog(@"index  %d filepath is: %@", i, filepath);
//                         }
//                     }
//                     return items;
//                 }
//                 else
//                 {
//                     NSLog(@"startCarousel unsuccessful is: %@", serverResponse.message);
//                 }
//             }
//             else
//             {
//                 NSLog(@"startCarousel not 200 unsucess is: %@", response.message);
//             }
//         }
//         else
//         {
//             NSLog(@"startCarousel Error: %@" ,error.description);
//         }
//         return  nil;
//     }];

}


-(NSDictionary *)goGetMorePhotos
{
    NSMutableDictionary *variables = [NSMutableDictionary new];
    
    variables[COMMAND]    = GET_CAROUSEL_PHOTOS;
    variables[ACTION]     = WorldView;
    
    
    [self.spinningWheel startAnimating];
    
    [KwikcyClientManager sendRequestWithParameters:variables
                             withCompletionHandler:^(BOOL receieved200Response, Response *response, NSError *error)
     {
         [self.spinningWheel stopAnimating];
         
         if (!error)
         {
             if (receieved200Response)
             {
                 KCServerResponse *serverResponse = (KCServerResponse *)response;
                 if (serverResponse.successful)
                 {
                     NSMutableDictionary *info = serverResponse.info;
                     
                     NSArray *objects = info[DATA];
                     
                     [self.spinningWheel startAnimating];
                     
                     for (NSDictionary *item in objects)
                     {
                         NSString *filepath = item[FILEPATH];
                         NSString *username = item[USERNAME];
                         
                         NSLog(@"filepath is: %@", filepath);
                         NSLog(@"username is: %@", username);
                         
                         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                             
                             
                             //                   Start here
                             //   1) Now for each filepath, do a batchgetItem from s3
                             //   2) Add images to an array
                             //   3) Turn off the spinning wheel
                             //   4) And start the carousel
                             
                             
                             // Puts the file as an object in the bucket.
                             S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc] initWithKey:filepath
                                                                                                 withBucket:KWIKCY_WORLD_BUCKET];
                             
                             [[QPNetworkActivity sharedInstance] increaseActivity];
                             S3GetObjectResponse *response = [[AmazonClientManager s3] getObject:getObjectRequest];
                             [[QPNetworkActivity sharedInstance] decreaseActivity];
                             
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 
                                 NSLog(@"Getting large phtotofe");
                                 if (!response.error)
                                 {
                                     NSLog(@"Getting large phtotofe no ERROR");
                                     
                                     NSData *data = response.body;
                                     
                                     if (data)
                                     {
                                         NSMutableDictionary *allData = [NSMutableDictionary new];
                                         
                                         allData[FILEPATH] = filepath;
                                         allData[USERNAME] = username;
                                         allData[DATA]     = data;
                                         
                                         [self.carouselPhotos addObject:allData];
                                     }
                                 }
                             });
                         });
                     }
                     
                 }
                 else
                 {
                     NSLog(@"startCarousel unsuccessful is: %@", serverResponse.message);
                     
                 }
             }
             else
             {
                 NSLog(@"startCarousel not 200 unsucess is: %@", response.message);
                 
             }
         }
         else
         {
             NSLog(@"startCarousel Error: %@" ,error.description);
             
         }
     }];

}














#pragma mark Set up keyboard methods


-(void)resetKeyBoardForSearchBar:(UISearchBar *)searchBar atIndex:(NSInteger)selectedScope
{
    if (selectedScope == MobileScopeIndex)
    {
        searchBar.keyboardType = UIKeyboardTypePhonePad;
    }
    else
    {
        searchBar.keyboardType = UIKeyboardTypeDefault;
    }
    
    [searchBar reloadInputViews];
    [searchBar becomeFirstResponder];
}







#pragma mark Search Display Delegate methods






// Called second
-(void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    for (UIView *view in controller.searchResultsTableView.subviews) {
        if ([[view class] isSubclassOfClass:[UIImageView class]]) {
            view.alpha = 0.f;
        }
    }
    
    if (controller.searchBar.selectedScopeButtonIndex == UsernameScopeIndex)
    {
        self.activityStatus = UserIsTypingForUsername;
    }
    else
    {
        self.activityStatus = UserIsTypingForMobile;
    }
    
    
    self.mainScreen = NO;
    
    NSArray *cells = [self.mainScreenTableView visibleCells];
    UITableViewCell *firstAndOnlyCell = [cells firstObject];
    firstAndOnlyCell.hidden = YES;
}


-(void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    NSLog(@"searchDisplayController didLoadSearchResultsTableView");

    for (UIView *view in controller.searchResultsTableView.subviews) {
        if ([[view class] isSubclassOfClass:[UIImageView class]]) {
            view.alpha = 0.f;
        }
    }
    for (UIView *view in tableView.subviews) {
        if ([[view class] isSubclassOfClass:[UIImageView class]]) {
            view.alpha = 0.f;
        }
    }
}


/* Shows main screen i.e. WOS */



//-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
//{
//    
//}

-(void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
//    NSLog(@"Canceled");
    self.activityStatus = UserIsNotTyping;
    self.mainScreen = YES;
    
    NSArray *cells = [self.mainScreenTableView visibleCells];
    UITableViewCell *firstAndOnlyCell = [cells firstObject];
    firstAndOnlyCell.hidden = NO;
}


//-(void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView
//{
//    NSLog(@"willUnloadSearchResultsTableView");
//}
//-(void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
//{
//    NSLog(@"willShowSearchResultsTableView");
//}
//-(void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView
//{
//    NSLog(@"didShowSearchResultsTableView");
//}
//-(void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView
//{
//    NSLog(@"willHideSearchResultsTableView");
//}
//-(void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView
//{
//    NSLog(@"didHideSearchResultsTableView");
//}


















#pragma mark Change of scope bars between mobile and username

-(void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    NSLog(@"selectedScopeButtonIndexDidChange");

    
    if (selectedScope == MobileScopeIndex)
    {
        // Save data for username search including results
        
        self.usernameStorage  = searchBar.text;
        
        self.activityStatus   = UserWillTypeForMobile;
        searchBar.text        = self.mobileNumberStorage;
        searchBar.placeholder = @"Search user by their mobile";
        
        self.activityStatus   = UserIsTypingForMobile;

    }
    else
    {
        // Save data for mobile search including results
        self.mobileNumberStorage = searchBar.text;
        self.activityStatus      = UserWillTypeForUsername;
        searchBar.text           = self.usernameStorage;
        searchBar.placeholder    = @"Search for user";

        self.activityStatus      = UserIsTypingForUsername;

    }

    [self resetKeyBoardForSearchBar:searchBar atIndex:selectedScope];
}





-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSLog(@"shouldReloadTableForSearchString");
    
    self.showUsers       = NO;
    self.showMobileUsers = NO;
 
    if (self.activityStatus == UserWillTypeForUsername || self.activityStatus == UserWillTypeForMobile )
    {
        NSLog(@"userIsTyping == UserWillTypeForUsername or UserWillTypeForMobile");

        return NO;
    }
    
    else if (self.activityStatus == SearchingForUsernameIsInProcess)
    {
        NSLog(@"shouldReloadTableForSearchString self.searching SearchingForUsernameIsInProcess +++++++++++++");

        [controller.searchResultsTableView reloadData];  // calls numberOfRowsInSection, cellForRowAtIndexPath
        [self searchForString:searchString forController:controller];
    }
    else if (self.activityStatus == SearchingForMobileIsInProcess)
    {
        NSLog(@"shouldReloadTableForSearchString self.searching SearchingForMobileIsInProcess +++++++++++++");
        
        [controller.searchResultsTableView reloadData];
        [self searchForString:searchString forController:controller];
    }
    
    //else // self.activityStatus == UserIsTypingForUsername || UserIsTypingForMobile
       
        NSLog(@"shouldReloadTableForSearchString through +++++++++++++");

    return YES;
}




/*
 *      Called after  searchBar: selectedScopeButtonIndexDidChange:
 *      
 *  Reloads table if any data still exists in array
 */

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    NSLog(@"shouldReloadTableForSearchScope");
    
    if (searchOption == MobileScopeIndex && [self.mobileUsers count] )
    {
        NSLog(@"shouldReloadTableForSearchScope MobileScopeIndex");
        self.showMobileUsers = YES;
    }
    else if (searchOption == UsernameScopeIndex && [self.users count] )
    {
        NSLog(@"shouldReloadTableForSearchScope UsernameScopeIndex");
        self.showUsers = YES;
    }
    
    return YES;
}








#pragma mark - Table view delegate





- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.activityStatus == UserIsTypingForUsername  && self.showUsers)
    {
        return [self.users count] > 0 ? [self.users count]:1 ;
    }
    else if (self.activityStatus == UserIsTypingForMobile  && self.showMobileUsers)
    {
        return [self.mobileUsers count] > 0 ? [self.mobileUsers count]:1;
    }
    else
        return 1;
}








//#define LabelString = @"Search for \"%@\"";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cellForRowAtIndexPath");
    // orginal tableview without any data.
    //Insert one plain cell, that is not allowed to be interacted with
    
    
    static NSString *SearchIdentifierCell = @"SearchButtonTableCell";
    static NSString *PlainCellIdentifier = @"PlainCell";
    
    static NSString *SearchCellIdentifier = @"KCSearchingTableCell";
    static NSString *UsernameOnlyEmptyCellIdentifier = @"KCUserNameOnlyTableCell";
    static NSString *FullUserCellIdentifier = @"KCUserTableCell";
    static NSString *NoUserFoundCellIdentifier = @"KCNoUserFoundTableCell";
    
    static NSString *KCStreamingCellIdentifier = @"KCStreamingCell";

    
    
    if ( self.showUsers || self.showMobileUsers )
    {
        NSDictionary *item;
        UITableViewCell *cell;

        if (self.showUsers)
        {
            if (![self.users count])
            {
                NSLog(@"cellForRowAtIndexPath !self.usersFound");
                cell = [self.mainScreenTableView dequeueReusableCellWithIdentifier:NoUserFoundCellIdentifier];
                return cell;
            }
            item = [self.users objectAtIndex:indexPath.row];
        }
        else //if (self.activityStatus == UserIsTypingForMobile)
        {
            if (![self.mobileUsers count])
            {
                NSLog(@"cellForRowAtIndexPath !self.usersFound");
                cell = [self.mainScreenTableView dequeueReusableCellWithIdentifier:NoUserFoundCellIdentifier];
                return cell;
            }
            item = [self.mobileUsers objectAtIndex:indexPath.row];
        }
        
        
        NSData   *data     = item[DATA];
        NSString *userName = item[USERNAME];
        NSString *realName = item[REALNAME];
        
        
        if (userName)
        {
            if (realName)
            {
                cell = [self.mainScreenTableView dequeueReusableCellWithIdentifier:FullUserCellIdentifier];
                
                UILabel *uName = (UILabel *)[cell viewWithTag:3];
                UILabel *rName = (UILabel *)[cell viewWithTag:4];
                
                uName.text = userName;
                rName.text = realName;
            }
            else //if no realname
            {
                cell = [self.mainScreenTableView dequeueReusableCellWithIdentifier:UsernameOnlyEmptyCellIdentifier];
                UILabel * uName = (UILabel *)[cell viewWithTag:1];
                uName.text = userName;
            }
            
            if (data)
            {
                UIImageView *imageView = (UIImageView *)[cell viewWithTag:2];
                
                [Constants makeImageRound:imageView];
                UIImage *image = [UIImage imageWithData:data scale:imageView.bounds.size.width];
                if(image)
                    imageView.image = image;
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
    }
    
        
    
    if (self.onMainScreen)
    {
        NSLog(@"cellForRowAtIndexPath self.onMainScreen");

        UITableViewCell *cell;
        if ([self.parentViewController isKindOfClass:[UINavigationController class]])
        {
            UIViewController *childController = self.parentViewController.childViewControllers[0];
            
            Class childVCClass = [childController class];
            NSString *className = NSStringFromClass(childVCClass);
            
            NSLog(@"Child class is = %@", className);
            
            if ([childController isKindOfClass:[KCSearchTVC class]])
            {
                cell = [self.mainScreenTableView dequeueReusableCellWithIdentifier:KCStreamingCellIdentifier];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
//                cell.userInteractionEnabled = NO;
                
                UILabel *title = (UILabel *)[cell viewWithTag:1];
               
                title.text = @"Friends View";
                
                self.carouselSpinningWheel = (UIActivityIndicatorView *)[cell viewWithTag:3];
                self.carousel = (iCarousel *)[cell viewWithTag:2];
                self.carouselLabel = (UILabel *)[cell viewWithTag:4];
                self.carouselLabel.text = @"Friends are well behaved";
                
            }
            else
            {
                cell = [self.mainScreenTableView dequeueReusableCellWithIdentifier:PlainCellIdentifier];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.userInteractionEnabled = NO;
             }
        }
        return cell;
    }
    
    
    if ( self.activityStatus == UserIsTypingForUsername ||
         self.activityStatus == UserIsTypingForMobile)
    {
        NSLog(@"cellForRowAtIndexPath self.userIsTyping");
        
        UITableViewCell *cell = [self.mainScreenTableView dequeueReusableCellWithIdentifier:SearchIdentifierCell];
        
        UILabel * searchingForLabel = (UILabel *)[cell viewWithTag:2];
        
        if (self.activityStatus == UserIsTypingForMobile)
        {
            NSString *formattedMobile = [self formatterMobileString:self.searchDisplayController.searchBar.text];
            searchingForLabel.text = [NSString stringWithFormat:@"Search for \"%@\"", formattedMobile];
        }
        else
            searchingForLabel.text = [NSString stringWithFormat:@"Search for \"%@\"",
                                              self.searchDisplayController.searchBar.text ];
        
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.userInteractionEnabled = YES;
        
        return cell;
    }
    else if( self.activityStatus == SearchingForUsernameIsInProcess ||
             self.activityStatus == SearchingForMobileIsInProcess)
    {
        
        NSLog(@"cellForRowAtIndexPath self.searching");
        UITableViewCell *cell;

        cell = [self.mainScreenTableView dequeueReusableCellWithIdentifier:SearchCellIdentifier];
        self.activityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:6];
        
        [self.activityIndicator startAnimating];
        return cell;
        
    }
    return nil;
}





- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath");
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ( self.showUsers || self.showMobileUsers)
    {
        NSDictionary *item = [self.users objectAtIndex:indexPath.row];
        
        NSString *username        = item[USERNAME];
        NSString *realname        = item[REALNAME];
        NSData   *smallImage      = item[DATA];
        
//        NSString *contact_allowed = item[ContactAllowed];
//        NSString *following       = item[FollowingAllowed];
        
        
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        if (username)
            userInfo[USERNAME] = username;
        if (realname)
            userInfo[REALNAME] = realname;
        if (smallImage)
            userInfo[DATA]     = smallImage;

        
//        if (contact_allowed)
//            userInfo[ContactAllowed] = contact_allowed;
//        if (following)
//            userInfo[FollowingAllowed] = following;

        
        self.userInfo = userInfo;
        
        [self performSegueWithIdentifier:@"GoToUsersProfile" sender:self];
    }
    
    else if (self.activityStatus == UserIsTypingForMobile)
    {
        NSLog(@"didSelectRowAtIndexPath UserIsTypingForMobile userIsTyping");
        [self searchButtonPressed:MobileScopeIndex];
    }
    else if (self.activityStatus == UserIsTypingForUsername)
    {
        NSLog(@"didSelectRowAtIndexPath userIsTyping");
        [self searchButtonPressed:UsernameScopeIndex];
    }
    
    else if (self.onMainScreen)
    {
        return;
    }
}





#pragma mark Search button pressed


// The UICell Seach button row
-(void)searchButtonPressed:(NSUInteger)selectedScope
{
    NSLog(@"searchButtonPressed");
    if (selectedScope == MobileScopeIndex)
    {
        NSLog(@"searchButtonPressedForMobileNumber");
        self.activityStatus = SearchingForMobileIsInProcess;
        [self searchDisplayController:self.searchDisplayController
     shouldReloadTableForSearchString:[NSString purifyMobileNumber:self.searchDisplayController.searchBar.text]];
    }
    else
    {
        [self searchBarSearchButtonClicked:self.searchDisplayController.searchBar];
    }
}


//Pressed by keyboard Search button, for usernames
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"searchBarSearchButtonClicked");
    self.activityStatus = SearchingForUsernameIsInProcess;
    [self searchDisplayController:self.searchDisplayController shouldReloadTableForSearchString:searchBar.text];
}


#pragma mark - Table view data source

-(void)searchForString:(NSString *)userIdentifier forController:(UISearchDisplayController *)controller
{
    if (controller.searchBar.selectedScopeButtonIndex == UsernameScopeIndex)
    {
        [self.users removeAllObjects];
        if ([userIdentifier length] < 3)
        {
            [self searchIsCompleteForUsernameReloadTable:controller];
            return;
        }

        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            NSArray *items = [KwikcyAWSRequest searchForUsernameSimilarToUsername:userIdentifier];
            
            [self.users removeAllObjects];
            
            if (!self.onMainScreen)
                [self.users addObjectsFromArray:items];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self searchIsCompleteForUsernameReloadTable:controller];
            });
        });
        
    }
    // Seach by users mobile number
    else
    {
        [self.mobileUsers removeAllObjects];

        if ([userIdentifier length])
        {
            NSMutableDictionary *variables = [NSMutableDictionary new];
            variables[COMMAND]             = SEARCH_MOBILE;
            variables[CONTACTS_NUMBER]     = userIdentifier;
            
            [KwikcyClientManager sendRequestWithParameters:variables
                                     withCompletionHandler:^(BOOL receieved200Response, Response *response, NSError *error)
             {
                 
                 if (self.onMainScreen)
                 {
                     [self searchIsCompleteForMobileReloadTable:controller];
                     return;
                 }
        
                 if (!error)
                 {
                     if (receieved200Response)
                     {
                         KCServerResponse *serverResponse = (KCServerResponse *)response;
                         if (serverResponse.successful)
                         {
                             NSMutableDictionary *item = [NSMutableDictionary new];
                             
                             
                             NSMutableDictionary *userInfo = ((KCServerResponse *)response).info;
                             
                             NSString* username = userInfo[USERNAME];
                             NSString* realname = userInfo[REALNAME];
                             NSString* data     = userInfo[DATA];

                             
                             if (username)
                                 item[USERNAME] = username;
                             if(realname)
                                 item[REALNAME] = realname;
                             if(data)
                                 item[DATA]     = data;
                             
                             [self.mobileUsers addObject:item];
                             
                         }
                         // server response was unsuccessful
                         else
                         {
                             [[Constants alertWithTitle:nil andMessage:serverResponse.message] show];
                         }
                     }
                 }
                 [self searchIsCompleteForMobileReloadTable:controller];

             }];
        }
        else
        {
            [self searchIsCompleteForMobileReloadTable:controller];
        }
    }
}







-(void)searchIsCompleteForUsernameReloadTable:(UISearchDisplayController *)controller
{
    NSLog(@"searchIsCompleteForUsernameReloadTable");

    self.showUsers      = YES;
    self.activityStatus = UserIsTypingForUsername;
    
    [controller.searchResultsTableView reloadData];
}


-(void)searchIsCompleteForMobileReloadTable:(UISearchDisplayController *)controller
{
    NSLog(@"searchIsCompleteForMobileReloadTable");
    
    self.showMobileUsers = YES;
    self.activityStatus  = UserIsTypingForMobile;

    [controller.searchResultsTableView reloadData];
}





- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.onMainScreen)
        return 300;
    
    CGFloat sizeOfCellsAsDrawnInNibCells = 70;
    return sizeOfCellsAsDrawnInNibCells;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}









-(NSString *)stripNumericString:(NSString *)number
{
    NSString *stringWithoutSpaces = [number stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    stringWithoutSpaces = [number stringByReplacingOccurrencesOfString:@"(" withString:@""];
    stringWithoutSpaces = [number stringByReplacingOccurrencesOfString:@")" withString:@""];
    stringWithoutSpaces = [number stringByReplacingOccurrencesOfString:@" " withString:@""];
    return stringWithoutSpaces;
}

-(NSString *)formatterMobileString:(NSString *)string
{
    if(!string)
        return @"";
    
    string = [self stripNumericString:string];
    
    NSUInteger stringLength = [string length];
    
    if  (stringLength > 3 && stringLength < 8)
        return [NSString stringWithFormat:@"%@-%@", [string substringToIndex:3], [string substringFromIndex:3]];
    else if (stringLength > 7 && stringLength < 11)
    {
        NSRange range = NSMakeRange(3, 3);
        return [NSString stringWithFormat:@"(%@) %@-%@", [string substringToIndex:3], [string substringWithRange:range],
                [string substringFromIndex:6]];
    }
    return string;
}






-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqual:@"GoToUsersProfile"])
    {
        
        
        
        [segue.destinationViewController performSelector:@selector(setUserInfo:)
                                              withObject:self.userInfo];
        
        

        
        // Get users image
//        KCProfileImageDownloader *imageDownloader =
//        [[KCProfileImageDownloader alloc] initWithBucket:KWIKCY_PROFILE_BUCKET
//                                             andFilepath:profilePathfile];
//        
//         [imageDownloader setAsyncImageDelegate:segue.destinationViewController];
//        [self.operationQueue addOperation:imageDownloader];
        
        
        
//        NSString *profilePathfile = [NSString stringWithFormat:@"%@/%@", self.userInfo[USERNAME], MEDIUM_IMAGE ];
//
//        [segue.destinationViewController performSelector:@selector(setMediumImageName:)
//                                              withObject:profilePathfile];
//        
//        
//        [segue.destinationViewController performSelector:@selector(getMediumImage)
//                                              withObject:nil];
//        
//
//        
//        
//        
//        // Get users info
//        KCUserProfileDelegate *profileDelegate = [[KCUserProfileDelegate alloc] initWithUserInfo:self.userInfo];
//        
//        [profileDelegate getDetailsForUser:self.userInfo[USERNAME]];
//        
//        [segue.destinationViewController performSelector:@selector(setProfileDelegate:)
//                                              withObject:profileDelegate];
        
//        [[NSNotificationCenter defaultCenter] addObserver:segue.destinationViewController selector:@selector(receivedUserDetails:) name:ReceivedUserDetailsNotification object:profileDelegate];
        
        
        
    }
    
    
    
}



@end


