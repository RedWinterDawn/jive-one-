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

static inline double radians (double degrees) { return degrees * M_PI/180; }

+(NSString *)formattedModifiedShortDateFromTimestamp:(NSNumber *)timestamp
{
    NSTimeInterval timeInterval = [timestamp longLongValue];// Depending of how the service give us the unix timestamp, we might need to devide it by 1000: /1000;
    NSDate *date = [[NSDate alloc]initWithTimeIntervalSince1970: timeInterval];
    return [Common formattedModifiedShortDate:date];
}

+(NSString *)formattedModifiedShortDate:(NSDate *)date
{
    if (!date) {
        return nil;
    }
    
    static NSDateFormatter *shortDateFormatter;
    static dispatch_once_t pred;        // Lock
    dispatch_once(&pred, ^{             // This code is called at most once per app
        shortDateFormatter = [[NSDateFormatter alloc] init];
        shortDateFormatter.timeZone = [NSTimeZone defaultTimeZone];
    });
    
    int days = (int)[self differenceInDaysToDate:date];
    if (days == 0){
        [shortDateFormatter setDateFormat:@"h:mm a"];
        NSString* hour = [shortDateFormatter stringFromDate:date];
        return hour;
    } else if (days == -1){
        return NSLocalizedString(@"Yesterday", @"Yesterday");
    } else if (days < -1 && days > -6) {
        [shortDateFormatter setDateFormat:@"EEE"];
        return [shortDateFormatter stringFromDate:date];
    }else{
        [shortDateFormatter setDateFormat:@"MMM d"];
        return [shortDateFormatter stringFromDate:date];
    }
}

+(NSString *)formattedLongDateFromTimestamp:(NSNumber*)timestamp{
    
    NSTimeInterval timeInterval = [timestamp longLongValue]/1000;
    NSDate *date = [[NSDate alloc]initWithTimeIntervalSince1970: timeInterval];
    return [Common formattedLongDate:date];
}

+(NSString *)formattedLongDate:(NSDate *)date
{
    if (!date) {
        return nil;
    }
    
    static NSDateFormatter *longDateFormatter;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        longDateFormatter = [[NSDateFormatter alloc] init];
        longDateFormatter.timeZone = [NSTimeZone defaultTimeZone];
        [longDateFormatter setDateFormat:@"M/dd/yyyy hh:mm a"];
    });
    return [longDateFormatter stringFromDate:date];
}

+(NSString *) shortDateFromTimestampDate:(NSDate *)date{
    return [NSString stringWithFormat:@"%@", date];
}

+(NSDate *)dateFromTimestamp:(NSNumber *)timestamp
{
    NSTimeInterval timeInterval = [timestamp longLongValue];
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

+ (long long) epochFromNSDate:(NSDate *)date {
    
    long long tes = [@(floor([date timeIntervalSince1970] * 1000)) longLongValue];
    return tes;
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
	if ([aString isKindOfClass:[NSNull class]]) {
		return YES;
	}
	else {	
		return !(aString && aString.length);
	}
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

+ (UIImage *)tintedImageWithColor:(UIColor *)tintColor image:(UIImage *)image
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    // draw alpha-mask
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, image.CGImage);
    
    // draw tint color, preserving alpha values of original image
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [tintColor setFill];
    CGContextFillRect(context, rect);
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return coloredImage;
}

+ (UIImage *)ExtractImageOn:(CGPoint)pointExtractedImg ofSize:(CGSize)sizeExtractedImg FromSpriteSheet:(UIImage*)imgSpriteSheet
{
    UIImage *ExtractedImage;
    
    CGRect rectExtractedImage;
    
    rectExtractedImage=CGRectMake(pointExtractedImg.x,pointExtractedImg.y,sizeExtractedImg.width,sizeExtractedImg.height);
    
    CGImageRef imgRefSpriteSheet=imgSpriteSheet.CGImage;
    
    CGImageRef imgRefExtracted=CGImageCreateWithImageInRect(imgRefSpriteSheet,rectExtractedImage);
    
    ExtractedImage=[UIImage imageWithCGImage:imgRefExtracted];
    
    CGImageRelease(imgRefExtracted);
    
    //CGImageRelease(imgRefSpriteSheet); I have commented it because we should not release the object that we don't own..So why do we release imgRefExtracted alone? bcuz it has name create in its method so the ownership comes to us so we have to release it.
    
    return ExtractedImage;
}

+ (UIImage *) rotateImage:(UIImage *)src orientation:(UIImageOrientation)orientation
{
    UIGraphicsBeginImageContext(src.size);
	
    CGContextRef context = UIGraphicsGetCurrentContext();
	
    if (orientation == UIImageOrientationRight) {
        CGContextRotateCTM (context, radians(90));
    } else if (orientation == UIImageOrientationLeft) {
        CGContextRotateCTM (context, radians(-90));
    } else if (orientation == UIImageOrientationDown) {
        // NOTHING
    } else if (orientation == UIImageOrientationUp) {
        CGContextRotateCTM (context, radians(90));
    }
	
    [src drawAtPoint:CGPointMake(0, 0)];
	
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - Encoding Utils

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
    CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
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

#pragma mark - Create NSError Util
+ (NSError *)createErrorWithDescription:(NSString *)description reason:(NSString *)reason code:(NSInteger)code
{
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: description,
                               NSLocalizedFailureReasonErrorKey: reason
                               };
    return [NSError errorWithDomain:@"JIVE"
                                         code:code
                                     userInfo:userInfo];
}


@end
