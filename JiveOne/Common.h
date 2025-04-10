//
//  Common.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;
@import UIKit;
@import CoreTelephony;

#import "LoggerCommon.h"

#define D_MINUTE	60
#define D_HOUR		3600
#define D_DAY		86400
#define D_WEEK		604800
#define D_YEAR		31556926

@interface Common : NSObject

+(NSDate *)dateFromTimestamp:(NSNumber *)timestamp;

+(NSString *)formattedModifiedShortDate:(NSDate *)date;
+(NSString *)formattedModifiedShortDateFromTimestamp:(NSNumber *)timestamp;
+(NSString *)formattedLongDate:(NSDate *)date;
+(NSString *)formattedLongDateFromTimestamp:(NSNumber *)timestamp;


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
+ (UIImage *)ExtractImageOn:(CGPoint)pointExtractedImg ofSize:(CGSize)sizeExtractedImg FromSpriteSheet:(UIImage*)imgSpriteSheet;
+ (UIImage *)rotateImage:(UIImage *)src orientation:(UIImageOrientation)orientation;
#pragma mark - Encryption Utils

+ (NSString*)encodeStringToBase64:(NSString*)plainString;
+ (NSString*)decodeBase64ToString:(NSString*)base64String;

#pragma mark - Telephony Utils
+ (BOOL) IsConnectionFast;

#pragma mark - Create NSError Util
+ (NSError *)createErrorWithDescription:(NSString *)description reason:(NSString *)reason code:(NSInteger)code;

@end
