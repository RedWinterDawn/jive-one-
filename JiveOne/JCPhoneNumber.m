//
//  JCNumber.m
//  JiveOne
//
//  Created by Robert Barclay on 4/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumber.h"
#import "JCPhoneNumberDataSourceUtils.h"

@implementation JCPhoneNumber

+(instancetype)phoneNumberWithName:(NSString *)name number:(NSString *)number
{
    return [[JCPhoneNumber alloc] initWithName:name number:number];
}

-(instancetype)initWithName:(NSString *)name number:(NSString *)number
{
    self = [super init];
    if (self) {
        if (!number) {
            return nil;
        }
        _number = [number copy];
        
        if (name) {
            _name = [name copy];
        }
    }
    return self;
}

@synthesize name = _name;
@synthesize number = _number;

-(NSString *)titleText
{
    return self.name;
}

-(NSString *)detailText
{
    return self.formattedNumber;
}

-(NSString *)dialableNumber
{
    return [JCPhoneNumberDataSourceUtils dialableStringForPhoneNumber:self];
}

-(NSString *)formattedNumber
{
    return [JCPhoneNumberDataSourceUtils formattedPhoneNumberForPhoneNumber:self];
}

-(NSString *)t9
{
    return [JCPhoneNumberDataSourceUtils t9StringForPhoneNumber:self];
}

-(NSAttributedString *)titleTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    return [JCPhoneNumberDataSourceUtils titleTextWithKeyword:keyword
                                                         font:font
                                                        color:color
                                                  phoneNumber:self];
}

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    return [JCPhoneNumberDataSourceUtils detailTextWithKeyword:keyword
                                                          font:font
                                                         color:color
                                                   phoneNumber:self];
}

-(BOOL)containsKeyword:(NSString *)keyword
{
    return [JCPhoneNumberDataSourceUtils phoneNumber:self
                                     containsKeyword:keyword];
}

-(BOOL)containsT9Keyword:(NSString *)keyword
{
    return [JCPhoneNumberDataSourceUtils phoneNumber:self
                                   containsT9Keyword:keyword];
}

-(BOOL)isEqual:(id)object
{
    return [JCPhoneNumberDataSourceUtils phoneNumber:self
                                             isEqual:object];
}

@end
