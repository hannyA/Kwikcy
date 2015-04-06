//
//  User.h
//  Kwikcy
//
//  Created by Hanny Aly on 8/8/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSData   * data;
@property (nonatomic, retain) NSString * dataType;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * me;
@property (nonatomic, retain) NSString * mobile;
@property (nonatomic, retain) NSString * realname;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * status;

@end
