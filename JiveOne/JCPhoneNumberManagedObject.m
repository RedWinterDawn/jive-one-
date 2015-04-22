//
//  JCPhoneNumberManagedObject.m
//  JiveOne
//
//  Created by Robert Barclay on 4/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumberManagedObject.h"
#import "JCPhoneNumberDataSourceUtils.h"

NSString *const kPersonT9AttributeKey = @"t9";

@implementation JCPhoneNumberManagedObject

-(void)willSave
{
    if (![self isDeleted])
    {
        NSString *name = self.name;
        if(name) {
            NSString *t9 = [JCPhoneNumberDataSourceUtils t9StringForString:name];
            [self setPrimitiveValue:t9 forKey:kPersonT9AttributeKey];
        }
    }
    [super willSave];
}

#pragma mark - Attributes -

@dynamic name;
@dynamic number;
@dynamic t9;

#pragma mark - JCPhoneNumberDataSource Protocol -

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

@end
