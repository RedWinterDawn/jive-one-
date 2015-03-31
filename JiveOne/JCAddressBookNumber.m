//
//  JCAddressBookNumber.m
//  JiveOne
//
//  Created by Robert Barclay on 2/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAddressBookNumber.h"
#import "NSString+Additions.h"

@implementation JCAddressBookNumber

@synthesize name = _name;
@synthesize number = _number;

-(NSString *)detailText
{
    return [NSString stringWithFormat:@"%@: %@", self.type, self.number];
}

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color{
    
    NSMutableAttributedString *attributedNumberText = [self.number formattedPhoneNumberWithKeyword:keyword font:font color:color];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           font, NSFontAttributeName,
                           color, NSForegroundColorAttributeName, nil];
    
    NSAttributedString *typeString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", self.type] attributes:attrs];
    [attributedNumberText insertAttributedString:typeString atIndex:0];
    return attributedNumberText;
}

@end
