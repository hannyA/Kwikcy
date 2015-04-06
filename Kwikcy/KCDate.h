//
//  KCDate.h
//  Kwikcy
//
//  Created by Hanny Aly on 6/22/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@interface KCDate : NSObject

+(NSString *)howLongAgoWasMessageDate:(NSDictionary *)messageDate sentFrom:(NSDictionary *)todaysDate;

+(BOOL)messageDate:(NSDictionary *)message isEqualToTodaysDate:(NSDictionary *)today;
+(NSDictionary *)getDictionaryFromTodaysDate;


+(NSString *)getTimeInSecondsFromDate:(NSDate *)date;


+(NSString *)getGMTFormateDate:(NSDate *)localDate;
+(NSDictionary *)getDateAndTimeFromSeconds:(NSString *)seconds;


+(NSDictionary *)getDateAndTime:(NSString *)thisDate;
+(NSString *)getDateFromSeconds:(NSString *)seconds;

+(NSString *)getDateFromSecondsForContacts:(NSString *)seconds;

@end
