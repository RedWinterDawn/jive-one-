//
//  JCPhoneNumberManagedObject.m
//  JiveOne
//
//  Created by Robert Barclay on 4/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumberManagedObject.h"
#import "JCPhoneNumberUtils.h"

NSString *const kPersonT9AttributeKey = @"t9";

@implementation JCPhoneNumberManagedObject

-(void)willSave
{
    if (![self isDeleted])
    {
        // generates the t9 representation of the name of the number.
        NSString *name = self.name;
        if(name) {
            NSString *t9 = [JCPhoneNumberUtils t9StringForString:name];
            [self setPrimitiveValue:t9 forKey:kPersonT9AttributeKey];
        }
    }
    [super willSave];
}

#pragma mark - Attributes -

@dynamic type;
@dynamic name;
@dynamic number;
@dynamic t9;

#pragma mark - Transient Properties -

-(NSString *)firstInitial
{
    NSString *name = self.name;
    if (name.length > 0) {
        return [[name substringToIndex:1] uppercaseStringWithLocale:name.locale];
    }
    return nil;
}

#pragma mark - JCPhoneNumberDataSource Protocol -

-(NSString *)titleText
{
    return self.name;
}

-(NSString *)detailText
{
    NSString *formattedNumber = self.formattedNumber;
    NSString *type = self.type;
    if (type) {
        return [NSString stringWithFormat:@"%@: %@", type, formattedNumber];
    }
    return formattedNumber;
}

-(NSString *)dialableNumber
{
    return [JCPhoneNumberUtils dialableStringForPhoneNumber:self];
}

-(NSString *)formattedNumber
{
    return [JCPhoneNumberUtils formattedPhoneNumberForPhoneNumber:self];
}

-(NSAttributedString *)titleTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    return [JCPhoneNumberUtils titleTextWithKeyword:keyword
                                                         font:font
                                                        color:color
                                                  phoneNumber:self];
}

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    return [JCPhoneNumberUtils detailTextWithKeyword:keyword
                                                          font:font
                                                         color:color
                                                   phoneNumber:self];
}

-(BOOL)containsKeyword:(NSString *)keyword
{
    return [JCPhoneNumberUtils phoneNumber:self
                                     containsKeyword:keyword];
}

-(BOOL)containsT9Keyword:(NSString *)keyword
{
    return [JCPhoneNumberUtils phoneNumber:self
                                   containsT9Keyword:keyword];
}

-(BOOL)isEqualToPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    return [JCPhoneNumberUtils phoneNumber:self isEqualToPhoneNumber:phoneNumber];
}

@end
