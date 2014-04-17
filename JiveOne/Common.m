//
//  Common.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Common.h"
#import "TRVSMonitor.h"

@implementation Common

#define DATE_COMPONENTS (NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit |  NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekdayCalendarUnit | NSWeekdayOrdinalCalendarUnit)
#define CURRENT_CALENDAR [NSCalendar currentCalendar]

+(NSString *) shortDateFromTimestamp:(NSNumber *)timestamp
{
    NSTimeInterval timeInterval = [timestamp longLongValue]/1000;
    NSDate *date = [[NSDate alloc]initWithTimeIntervalSince1970: timeInterval];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone defaultTimeZone];
    
    int days = (int)[self differenceInDaysToDate:date];
    
    if (days == 0) {
        [formatter setDateFormat:@"HH:mm a"];
        NSString* hour = [formatter stringFromDate:date];
        //return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Today", @"Today"), hour];
        return hour;
    } else if (days == -1) {
        //[formatter setDateFormat:@"HH:mm a"];
        //NSString* hour = [formatter stringFromDate:date];
        //return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Yesterday", @"Yesterday"), hour];
        return NSLocalizedString(@"Yesterday", @"Yesterday");
    } else if (days < -1 && days > -6) {
        //[formatter setDateFormat:@"EEEE HH:mm a"];
        [formatter setDateFormat:@"EEE"];
        return [formatter stringFromDate:date];
    }else{
        [formatter setDateFormat:@"MMM d"];
        return [formatter stringFromDate:date];
    }
}
+(NSString*) longDateFromTimestamp:(NSNumber*)timestamp{
    
    NSTimeInterval timeInterval = [timestamp longLongValue]/1000;
    NSDate *date = [[NSDate alloc]initWithTimeIntervalSince1970: timeInterval];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone defaultTimeZone];

    [formatter setDateFormat:@"MM/dd/yyyy hh:mm a"];
    NSTimeZone *timezone = [NSTimeZone defaultTimeZone];
    formatter.timeZone = timezone;
    return [formatter stringFromDate:date];
}

+(NSDate *)NSDateFromTimestap:(NSNumber *)timestamp
{
    NSTimeInterval timeInterval = [timestamp longLongValue]/1000;
    NSDate *date = [[NSDate alloc]initWithTimeIntervalSince1970: timeInterval];
    return date;
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
    NSDate *now = [NSDate date];
	NSTimeInterval ti = [now  timeIntervalSinceDate:aDate];
    double result = (ti / D_DAY);
	return (NSInteger) result;
}

+ (NSInteger) daysBeforeDate: (NSDate *) aDate
{
	NSTimeInterval ti = [aDate timeIntervalSinceDate:[NSDate date]];
	return (NSInteger) (ti / D_DAY);
}

+ (NSInteger)differenceInDaysToDate:(NSDate *)otherDate {
    NSCalendar *cal = [NSCalendar autoupdatingCurrentCalendar];
    NSUInteger unit = NSDayCalendarUnit;
    NSDate *startDays, *endDays;
    
    [cal rangeOfUnit:unit startDate:&startDays interval:NULL forDate:[NSDate date]];
    [cal rangeOfUnit:unit startDate:&endDays interval:NULL forDate:otherDate];
    
    NSDateComponents *comp = [cal components:unit fromDate:startDays toDate:endDays options:0];
    return [comp day];
}

#pragma mark - String Utils
+(BOOL)stringIsNilOrEmpty:(NSString*)aString {
    return !(aString && aString.length);
}


#pragma mark - UIImage Utils

+ (UIImage*)mergeImage:(UIImage*)first withImage:(UIImage*)second
{
    // get size of the first image
    CGImageRef firstImageRef = first.CGImage;
    CGFloat firstWidth = CGImageGetWidth(firstImageRef);
    CGFloat firstHeight = CGImageGetHeight(firstImageRef);
    
    // get size of the second image
    CGImageRef secondImageRef = second.CGImage;
    CGFloat secondWidth = CGImageGetWidth(secondImageRef);
    CGFloat secondHeight = CGImageGetHeight(secondImageRef);
    
    // build merged size
    CGSize mergedSize = CGSizeMake(MAX(firstWidth, secondWidth), MAX(firstHeight, secondHeight));
    
    // capture image context ref
    UIGraphicsBeginImageContext(mergedSize);
    
    //Draw images onto the context
    [first drawInRect:CGRectMake(0, 0, firstWidth, firstHeight)];
    [second drawInRect:CGRectMake(0, 0, secondWidth, secondHeight)];
    
    // assign context to new UIImage
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // end context
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage *) imageFromView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

#pragma mark - Encryption Utils

+ (NSString*)encodeStringToBase64:(NSString*)plainString
{
    NSData *plainData = [plainString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [plainData base64EncodedStringWithOptions:0];
    NSLog(@"%@", base64String);
    return base64String;
}

+ (NSString*)decodeBase64ToString:(NSString*)base64String
{
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", decodedString); // foo
    return decodedString;
}

#pragma mark - Telephony Utils
+ (BOOL) IsConnectionFast
{
//    TRVSMonitor *monitor = [TRVSMonitor monitor];
    CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
    NSLog(@"Current Radio Access Technology: %@", telephonyInfo.currentRadioAccessTechnology);
    
//    [NSNotificationCenter.defaultCenter addObserverForName:CTRadioAccessTechnologyDidChangeNotification
//                                                    object:nil
//                                                     queue:nil
//                                                usingBlock:^(NSNotification *note)
//     {
//         NSLog(@"New Radio Access Technology: %@", telephonyInfo.currentRadioAccessTechnology);
//         
//     }];
    
//    [monitor waitWithTimeout:10];
    
    return [self isFast:telephonyInfo.currentRadioAccessTechnology];
}

+ (BOOL)isFast:(NSString*)radioAccessTechnology {
    if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) {
        return NO;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge]) {
        return NO;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSDPA]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSUPA]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyeHRPD]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
        return YES;
    }
    
    return YES;
}


@end
