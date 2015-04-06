//
//  KCMailboxCoreDataMethods.h
//  Kwikcy
//
//  Created by Hanny Aly on 8/27/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCMailboxCoreDataMethods : NSObject


@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

+(NSArray *)getMessagesForSelectedSegment:(NSUInteger)selectedSegmentIndex withManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;


+(void)addScreenShotInfoToCoreData:(NSDictionary *)dic;

@end
