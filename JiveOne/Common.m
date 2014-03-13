//
//  Common.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Common.h"

@implementation Common

#define DATE_COMPONENTS (NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit |  NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekdayCalendarUnit | NSWeekdayOrdinalCalendarUnit)
#define CURRENT_CALENDAR [NSCalendar currentCalendar]

+(NSString *) dateFromTimestamp:(NSNumber *)timestamp
{
    NSTimeInterval timeInterval = [timestamp longLongValue]/1000;
    NSDate *date = [[NSDate alloc]initWithTimeIntervalSince1970: timeInterval];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone defaultTimeZone];
    
    int days = [self daysBeforeDate:date];
    
    if (days == 0) {
        [formatter setDateFormat:@"HH:mm a"];
        NSString* hour = [formatter stringFromDate:date];
        return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Today", @"Today"), hour];
    } else if (days == 1) {
        [formatter setDateFormat:@"HH:mm a"];
        NSString* hour = [formatter stringFromDate:date];
        return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Yesterday", @"Yesterday"), hour];
    } else if (days > 1 && days < 6) {
        [formatter setDateFormat:@"EEEE HH:mm a"];
        return [formatter stringFromDate:date];
    }
        
    [formatter setDateFormat:@"MM/dd/yyyy hh:mm a"];
    NSTimeZone *timezone = [NSTimeZone defaultTimeZone];
    formatter.timeZone = timezone;
    return [formatter stringFromDate:date];
}

+ (BOOL) isEqualToDateIgnoringTime: (NSDate *) aDate
{
	NSDateComponents *components1 = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:[NSDate date]];
	NSDateComponents *components2 = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:aDate];
	return ((components1.year == components2.year) &&
			(components1.month == components2.month) &&
			(components1.day == components2.day));
}

+ (BOOL) isEarlierThanDate: (NSDate *) aDate
{
	return ([[NSDate date] compare:aDate] == NSOrderedAscending);
}

+ (BOOL) isLaterThanDate: (NSDate *) aDate
{
	return ([[NSDate date] compare:aDate] == NSOrderedDescending);
}

#pragma mark Retrieving Intervals

+ (NSInteger) minutesAfterDate: (NSDate *) aDate
{
	NSTimeInterval ti = [[NSDate date] timeIntervalSinceDate:aDate];
	return (NSInteger) (ti / D_MINUTE);
}

+ (NSInteger) minutesBeforeDate: (NSDate *) aDate
{
	NSTimeInterval ti = [aDate timeIntervalSinceDate:[NSDate date]];
	return (NSInteger) (ti / D_MINUTE);
}

+ (NSInteger) hoursAfterDate: (NSDate *) aDate
{
	NSTimeInterval ti = [[NSDate date]  timeIntervalSinceDate:aDate];
	return (NSInteger) (ti / D_HOUR);
}

+ (NSInteger) hoursBeforeDate: (NSDate *) aDate
{
	NSTimeInterval ti = [aDate timeIntervalSinceDate:[NSDate date]];
	return (NSInteger) (ti / D_HOUR);
}

+ (NSInteger) daysAfterDate: (NSDate *) aDate
{
	NSTimeInterval ti = [[NSDate date]  timeIntervalSinceDate:aDate];
	return (NSInteger) (ti / D_DAY);
}

+ (NSInteger) daysBeforeDate: (NSDate *) aDate
{
	NSTimeInterval ti = [aDate timeIntervalSinceDate:[NSDate date]];
	return (NSInteger) (ti / D_DAY);
}




@end
