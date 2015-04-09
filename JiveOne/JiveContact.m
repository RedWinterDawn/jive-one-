//
//  JiveContact.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JiveContact.h"

@implementation JiveContact

@dynamic extension;
@dynamic jrn;
@dynamic pbxId;

#pragma mark - Transient Properties -

-(NSAttributedString *)titleTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    NSMutableAttributedString *attributedText = [self.name formattedStringWithT9Keyword:keyword font:font color:color];
    
    return attributedText;
}

-(NSString *)detailText
{
    return self.extension;
}

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    NSMutableAttributedString *attributedNumberText = [self.extension formattedPhoneNumberWithKeyword:keyword font:font color:color];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           font, NSFontAttributeName,
                           color, NSForegroundColorAttributeName, nil];
    
    NSAttributedString *typeString = [[NSAttributedString alloc] initWithString:@"ext: " attributes:attrs];
    [attributedNumberText insertAttributedString:typeString atIndex:0];
    return attributedNumberText;
}

-(NSString *)number
{
    return self.extension;
}

@end
