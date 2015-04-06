//
//  KCDate.m
//  Kwikcy
//
//  Created by Hanny Aly on 6/22/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCDate.h"

@implementation KCDate


#define MINUTES_IN_A_HOUR 60
#define HOURS_IN_A_DAY 24
#define SIX_HOURS 6
#define DAYS_IN_A_WEEK 7

#define singular @""
#define multiple @"s"


#define MINUTES_IN_A_DAY 60*24

+(int)timeFromMidnight:(int)time
{
//    int midnight = 24*60;
    return MINUTES_IN_A_DAY - time;
}


+(NSString *)howLongAgoWasMessageDate:(NSDictionary *)messageDate sentFrom:(NSDictionary *)todaysDate
{
    // If different years
    if ( ![messageDate[QPYEAR] isEqualToString:todaysDate[QPYEAR]])
    {
        int todaysYear  = [todaysDate[QPYEAR] intValue];
        int messageYear = [messageDate[QPYEAR] intValue];
        
        int yearDifference = todaysYear - messageYear;
        return [NSString stringWithFormat:@"%d year%@ ago", yearDifference, yearDifference > 1?multiple:singular];
    }
    
    // If different months
    else if ( ![messageDate[QPMONTH] isEqualToString:todaysDate[QPMONTH]])
    {
        int todaysMonth  = [todaysDate[QPMONTH] intValue];
        int messageMonth = [messageDate[QPMONTH] intValue];
        
        int monthDifference = todaysMonth - messageMonth;
        return [NSString stringWithFormat:@"%d month%@ ago", monthDifference, monthDifference > 1?multiple:singular];
    }
    
    //Same month
    else
    {
        
        int todaysHoursTime         = [todaysDate[QPHOURS] intValue] * MINUTES_IN_A_HOUR;
        int todaysMinutesTime       = [todaysDate[QPMINUTES] intValue];
        int totalTodaysMinutes      = todaysHoursTime + todaysMinutesTime;
        
        int messageHoursTime        = [messageDate[QPHOURS] intValue] * MINUTES_IN_A_HOUR;
        int messageMinutesTime      = [messageDate[QPMINUTES] intValue];
        int totalMessageMinutes     = messageHoursTime + messageMinutesTime;
        
        int todaysDay           = [todaysDate[QPDAY] intValue];
        int messageSentDay      = [messageDate[QPDAY] intValue];
        
        int daysDifference      = todaysDay - messageSentDay;
        
        
        // if todays day matches the message sent day
        if (daysDifference == 0)
        {
            int timeDifference = totalTodaysMinutes - totalMessageMinutes;
            
            if ( timeDifference == 0)
                return @"Just now";
            
            else if ( timeDifference < MINUTES_IN_A_HOUR )
                return [NSString stringWithFormat:@"%d minute%@ ago", timeDifference, timeDifference > 1?multiple:singular];
            else
                return [NSString stringWithFormat:@"%d hour%@ ago", (timeDifference / MINUTES_IN_A_HOUR) , (timeDifference / MINUTES_IN_A_HOUR) > 1?multiple:singular];
        }
        // One day difference
        else if (daysDifference == 1 )
        {
            
            NSUInteger minutesDifference = [self differenceMessageMinutes:totalMessageMinutes
                                                 fromTodaysMinutes:totalTodaysMinutes];

            NSLog(@"minutesDifference = %d", minutesDifference);
            if ( minutesDifference < MINUTES_IN_A_HOUR)
            {
                return [NSString stringWithFormat:@"%d minute%@ ago", minutesDifference ,  minutesDifference > 1? multiple:singular];
            }
            // If more than an hour difference days, less than 6 hour difference
            else if ( minutesDifference < SIX_HOURS * MINUTES_IN_A_HOUR)
            {
                return [NSString stringWithFormat:@"%d hour%@ ago", minutesDifference , minutesDifference > MINUTES_IN_A_HOUR ? multiple:singular];
            }
            else
            {
                return [NSString stringWithFormat:@"%@", @"Yesterday"];
            }
        }
        // more than one day, but within a week
        else if (daysDifference > 1 && daysDifference < 7 )
        {
            return [NSString stringWithFormat:@"%d days ago", daysDifference];
        }
        // less than a month, more than a week
        else // if (daysDifference > 7)
        {
            int weeksAgo = daysDifference / DAYS_IN_A_WEEK;
            int daysRemainder = daysDifference % DAYS_IN_A_WEEK;
           
            if (weeksAgo < 4 && daysRemainder > 3)
                weeksAgo++;
            return [NSString stringWithFormat:@"%d week%@ ago", weeksAgo,  weeksAgo > 1? multiple:singular ];
        }
    }
}





                
+(NSUInteger)differenceMessageMinutes:(NSUInteger)messageMinutes fromTodaysMinutes:(NSUInteger)todaysMinutes
{
    int messageSide = [self timeFromMidnight:messageMinutes];
    
    return messageSide + todaysMinutes;
//    if ( ( messageSide + todaysMinutes ) < MINUTES_IN_A_HOUR)
//        return YES;
//    return NO;
}




/*
 * Checks to see if the two dates are equal by month, day, year
 */

+(BOOL)messageDate:(NSDictionary *)message isEqualToTodaysDate:(NSDictionary *)today
{
    
    if([message[QPDAY] isEqualToString:today[QPDAY]] &&
       [message[QPMONTH] isEqualToString:today[QPMONTH]] &&
       [message[QPYEAR] isEqualToString:today[QPYEAR]])
        return YES;
    return NO;
}



+(NSDictionary *)getDictionaryFromTodaysDate
{
    NSDate *localDate = [NSDate date];
    
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:timeZone];
    
    
    
    
    [dateFormat setDateFormat:@"HH"];
    NSString *theHours = [dateFormat stringFromDate:localDate];
    
    [dateFormat setDateFormat:@"mm"];
    NSString *theMinutes = [dateFormat stringFromDate:localDate];
    
    
    
    [dateFormat setDateFormat:@"hh:mm a"];
    NSString *theTime = [dateFormat stringFromDate:localDate];
    
    [dateFormat setDateFormat:@"dd"];
    NSString *day = [dateFormat stringFromDate:localDate];
    
    [dateFormat setDateFormat:@"MM"];
    NSString *month = [dateFormat stringFromDate:localDate];
    
    [dateFormat setDateFormat:@"yyyy"];
    NSString *year = [dateFormat stringFromDate:localDate];
    
    return @{ QPMONTH:month, QPDAY:day, QPYEAR:year,
              QPTIME:theTime, QPHOURS:theHours, QPMINUTES:theMinutes };
}


//Return time as seconds format as int
+(NSString *)getTimeInSecondsFromDate:(NSDate *)date
{
    NSInteger time = [date timeIntervalSince1970];
    return [NSString stringWithFormat:@"%ld", (long)time];
}




//Called from received messages coredate
//Change this to differnce from out time zone and gmt time zone and add the difference

+(NSString *)getDateFromSeconds:(NSString *)seconds
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[seconds doubleValue]];
    NSTimeZone *localZone = [NSTimeZone localTimeZone];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM-dd-yyyy hh:mm:ss a"];
    [dateFormatter setTimeZone:localZone];
    
    NSString * time = [dateFormatter stringFromDate:date];
    
    return  time;
}


+(NSString *)getDateFromSecondsForContacts:(NSString *)seconds
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[seconds doubleValue]];
    NSTimeZone *localZone = [NSTimeZone localTimeZone];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd hh:mm:ss a"];
    [dateFormatter setTimeZone:localZone];
    
    NSString * time = [dateFormatter stringFromDate:date];
    return  time;
}





//Used for sending and storing in db. Not used

/* Converts NSDate to string format with GMT timezone */
/* Used in FYESendingVC : sendVideo */
+(NSString *)getGMTFormateDate:(NSDate *)localDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"MMM-dd-yyyy hh:mm:ss a"];
    
    NSString *dateString = [dateFormatter stringFromDate:localDate];
    return dateString;
}




/*
 * Parameter thisDate is in the format of MMM-dd-yyyy hh:mm:ss a
 * Is that how its sent from the database?
 */

+(NSDictionary *)getDateAndTime:(NSString *)dateInSeconds
{
    NSString *thisDate = [self getDateFromSeconds:dateInSeconds];
    
    NSDateFormatter *dateformat = [[NSDateFormatter alloc] init];
    [dateformat setDateFormat:@"MMM-dd-yyyy hh:mm:ss a"];
    NSDate *date = [dateformat dateFromString:thisDate];
    
    
    
    NSDateFormatter *localFormatter = [[NSDateFormatter alloc] init];
    
    
    
    
    [localFormatter setDateFormat:@"HH"];
    NSString *theHours = [localFormatter stringFromDate:date];
    
    [localFormatter setDateFormat:@"mm"];
    NSString *theMinutes = [localFormatter stringFromDate:date];
    
    
    
    [localFormatter setDateFormat:@"dd"];
    NSString *day = [localFormatter stringFromDate:date];
    
    [localFormatter setDateFormat:@"MM"];
    NSString *month = [localFormatter stringFromDate:date];
    
    [localFormatter setDateFormat:@"yyyy"];
    NSString *year = [localFormatter stringFromDate:date];
    
    
    [localFormatter setDateFormat:@"MMM-dd hh:mm a"];
    NSString *fullDate = [localFormatter stringFromDate:date];
    
    [localFormatter setDateFormat:@"MMM-dd"];
    NSString *theDate = [localFormatter stringFromDate:date];
    
    [localFormatter setDateFormat:@"hh:mm a"];
    NSString *theTime = [localFormatter stringFromDate:date];
    
    return @{ QPDATE: theDate,
              QPTIME:theTime,
              QPFULLDATE:fullDate,
              QPMONTH:month,
              QPDAY:day,
              QPYEAR:year,
              QPHOURS:theHours, QPMINUTES:theMinutes
              };
}




//Used in sending messages, so dont need to set up time zone

/* Converts NSString to NSDate to current timezone format to a dictionary with time, date, and both */
+(NSDictionary *)getDateAndTimeFromSeconds:(NSString *)dateInSeconds
{
    NSTimeInterval timeInterval = [dateInSeconds doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    
    NSDateFormatter *dateformat = [[NSDateFormatter alloc] init];
    [dateformat setDateFormat:@"MMM-dd-yyyy hh:mm:ss a"];
    //    NSString *dateString = [dateformat stringFromDate:date]; //] dateFromString:GMTDate];
    
    
    //    NSDateFormatter *dateformat = [[NSDateFormatter alloc] init];
    //    [dateformat setDateFormat:@"MMM-dd-yyyy hh:mm:ss a"];
    //    NSDate *date = [dateformat dateFromString:GMTDate];
    
    
    NSDateFormatter *localFormatter = [[NSDateFormatter alloc] init];
    
    
    
    
    [localFormatter setDateFormat:@"HH"];
    NSString *theHours = [localFormatter stringFromDate:date];
    
    [localFormatter setDateFormat:@"mm"];
    NSString *theMinutes = [localFormatter stringFromDate:date];
    
    
    [localFormatter setDateFormat:@"dd"];
    NSString *day = [localFormatter stringFromDate:date];
    
    [localFormatter setDateFormat:@"MM"];
    NSString *month = [localFormatter stringFromDate:date];
    
    [localFormatter setDateFormat:@"yyyy"];
    NSString *year = [localFormatter stringFromDate:date];
    
    
    [localFormatter setDateFormat:@"MMM-dd hh:mm a"];
    NSString *fullDate = [localFormatter stringFromDate:date];
    
    [localFormatter setDateFormat:@"MMM-dd"];
    NSString *theDate = [localFormatter stringFromDate:date];
    
    [localFormatter setDateFormat:@"hh:mm a"];
    NSString *theTime = [localFormatter stringFromDate:date];
    
    
    return @{ QPDATE: theDate,
              QPTIME:theTime,
              QPFULLDATE:fullDate,
              QPMONTH:month,
              QPDAY:day,
              QPYEAR:year,
              QPHOURS:theHours, QPMINUTES:theMinutes
              };
}

@end
