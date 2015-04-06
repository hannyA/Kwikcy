//
//  Received_message.h
//  Kwikcy
//
//  Created by Hanny Aly on 9/2/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Received_message : NSManagedObject

@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSString * date_sender;
@property (nonatomic, retain) NSDate * delete_date;
@property (nonatomic, retain) NSString * delete_marker;
@property (nonatomic, retain) NSString * filepath;
@property (nonatomic, retain) NSString * from;
@property (nonatomic, retain) NSString * me;
@property (nonatomic, retain) NSString * mediaType;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * view_status;
@property (nonatomic, retain) NSNumber * screenshot_safe;

@end
