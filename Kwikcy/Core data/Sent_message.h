//
//  Sent_message.h
//  Kwikcy
//
//  Created by Hanny Aly on 9/14/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Sent_message : NSManagedObject

@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSString * filepath;
@property (nonatomic, retain) NSString * mediaType;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * receivers;
@property (nonatomic, retain) NSString * sender;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * unsend_key;

@end
