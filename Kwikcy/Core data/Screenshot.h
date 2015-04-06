//
//  Screenshot.h
//  Kwikcy
//
//  Created by Hanny Aly on 8/8/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Screenshot : NSManagedObject

@property (nonatomic, retain) NSString * attribute;
@property (nonatomic, retain) NSString * filepath;
@property (nonatomic, retain) NSString * me;
@property (nonatomic, retain) NSString * receiver;

@end
