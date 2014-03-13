//
//  Common.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define D_MINUTE	60
#define D_HOUR		3600
#define D_DAY		86400
#define D_WEEK		604800
#define D_YEAR		31556926

@interface Common : NSObject

+(NSString *) dateFromTimestamp:(NSNumber *)timestamp;
+ (BOOL) isEqualToDateIgnoringTime: (NSDate *) aDate;
+ (BOOL) isEarlierThanDate: (NSDate *) aDate;
+ (BOOL) isLaterThanDate: (NSDate *) aDate;
// Retrieving intervals
+ (NSInteger) minutesAfterDate: (NSDate *) aDate;
+ (NSInteger) minutesBeforeDate: (NSDate *) aDate;
+ (NSInteger) hoursAfterDate: (NSDate *) aDate;
+ (NSInteger) hoursBeforeDate: (NSDate *) aDate;
+ (NSInteger) daysAfterDate: (NSDate *) aDate;
+ (NSInteger) daysBeforeDate: (NSDate *) aDate;
+ (NSInteger)distanceInDaysToDate:(NSDate *)anotherDate;

@end
