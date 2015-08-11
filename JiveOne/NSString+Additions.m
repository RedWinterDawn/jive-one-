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

@implementation NSString (Localization)

-(NSLocale *)locale
{
    // Makes the startup of this singleton thread safe.
    static NSLocale *locale = nil;
    static dispatch_once_t pred;        // Lock
    dispatch_once(&pred, ^{             // This code is called at most once per app
        NSString *localization = [NSBundle mainBundle].preferredLocalizations.firstObject;
        locale = [[NSLocale alloc] initWithLocaleIdentifier:localization];
    });
    return locale;
}

@end
