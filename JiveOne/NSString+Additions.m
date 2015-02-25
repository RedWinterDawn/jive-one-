//
//  NSString+Custom.m
//  JiveOne
//
//  Created by Robert Barclay on 11/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString (Custom)

-(BOOL)isEmpty {
    if ([self isKindOfClass:[NSNull class]]) {
        return YES;
    }
    return !self.length;
}

@end

//
//  NSString+MD5Additions.m
//  JiveOne
//
//  Created by Robert Barclay on 1/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

@implementation NSString (MD5Additions)

- (NSString *)MD5Hash
{
    if(self == nil || [self length] == 0)
        return nil;
    
    const char *string = [self UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(string, (unsigned int)strlen(string), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++)
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    return outputString;
}

@end

@implementation NSString (IsNumeric)

-(bool)isNumeric
{
    NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *inStringSet = [NSCharacterSet characterSetWithCharactersInString:self];
    return [alphaNums isSupersetOfSet:inStringSet];
}

-(NSString *)numericStringValue {
    return [[self componentsSeparatedByCharactersInSet: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
}

@end

#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>

@implementation NSString (PhoneNumbers)

-(NSString *)formattedPhoneNumber
{
    if (self.length < 5)
        return self;
    
    __autoreleasing NSError *error;
    
    static NBPhoneNumberUtil *phoneNumberUtil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        phoneNumberUtil = [NBPhoneNumberUtil new];
    });
    
    NBPhoneNumber *phoneNumber = [phoneNumberUtil parse:self defaultRegion:@"US" error:&error];
    if (error)
        NSLog(@"%@", [error description]);
    return [phoneNumberUtil format:phoneNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&error];
}

@end