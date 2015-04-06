//
//  QPCoreDataManager.h
//  Quickpeck
//
//  Created by Hanny Aly on 8/20/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QPCoreDataManager : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

+ (QPCoreDataManager *)sharedInstance;

@end
