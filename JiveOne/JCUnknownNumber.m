//
//  JCMessageParticipant.m
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCUnknownNumber.h"

@implementation JCUnknownNumber

+(instancetype)unknownNumberWithNumber:(NSString *)number
{
    JCUnknownNumber *unknownNumber = [self new];
    unknownNumber.number = number;
    return unknownNumber;
}

-(NSString *)titleText
{
    return self.name;
}

-(NSString *)t9
{
    return self.number.t9;
}

-(NSString *)name
{
    return self.number;
}

-(NSString *)detailText
{
    return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Send SMS to", nil), self.name];
}

-(BOOL)containsKeyword:(NSString *)keyword
{
    return FALSE;
}

-(BOOL)containsT9Keyword:(NSString *)keyword
{
    return FALSE;
}

-(NSAttributedString *)titleTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    NSDictionary *attrs = @{ NSFontAttributeName: font, NSForegroundColorAttributeName: color };
    return [[NSAttributedString alloc] initWithString:self.titleText attributes:attrs];
}

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    NSDictionary *attrs = @{ NSFontAttributeName: font, NSForegroundColorAttributeName: color };
    return [[NSAttributedString alloc] initWithString:self.detailText attributes:attrs];
}

@end
