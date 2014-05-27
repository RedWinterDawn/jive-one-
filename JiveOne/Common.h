//
//  Common.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "JCStyleKit.h"

#define D_MINUTE	60
#define D_HOUR		3600
#define D_DAY		86400
#define D_WEEK		604800
#define D_YEAR		31556926

@interface Common : NSObject


+(NSString *) shortDateFromTimestamp:(NSNumber *)timestamp;
+(NSString *) longDateFromTimestamp:(NSNumber *)timestamp;
+(NSDate *)NSDateFromTimestap:(NSNumber *)timestamp;
+ (BOOL) isEqualToDateIgnoringTime: (NSDate *) aDate;
+ (BOOL) isEarlierThanDate: (NSDate *) aDate;
+ (BOOL) isLaterThanDate: (NSDate *) aDate;
+ (long long) epochFromNSDate:(NSDate *)date;
// Retrieving intervals
+ (NSInteger) minutesAfterDate: (NSDate *) aDate;
+ (NSInteger) minutesBeforeDate: (NSDate *) aDate;
+ (NSInteger) hoursAfterDate: (NSDate *) aDate;
+ (NSInteger) hoursBeforeDate: (NSDate *) aDate;
+ (NSInteger) daysAfterDate: (NSDate *) aDate;
+ (NSInteger) daysBeforeDate: (NSDate *) aDate;

#pragma mark - String Utils
+(BOOL)stringIsNilOrEmpty:(NSString*)aString;


#pragma mark - UIImage Utils
+ (UIImage *)mergeImage:(UIImage*)first withImage:(UIImage*)second;
+ (UIImage *) imageFromView:(UIView *)view;
+ (UIImage *)tintedImageWithColor:(UIColor *)tintColor image:(UIImage *)image;

#pragma mark - Encryption Utils

+ (NSString*)encodeStringToBase64:(NSString*)plainString;
+ (NSString*)decodeBase64ToString:(NSString*)base64String;

#pragma mark - Telephony Utils
+ (BOOL) IsConnectionFast;

@end
