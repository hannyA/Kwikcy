//
//  ViewController_State.h
//  Kwikcy
//
//  Created by Hanny Aly on 8/8/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ViewController_State : NSManagedObject

@property (nonatomic, retain) NSString * action;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) NSString * me;
@property (nonatomic, retain) NSString * objectView;
@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSNumber * valid;
@property (nonatomic, retain) NSString * viewControllerName;

@end
