//
//  RecentLineEvent.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "RecentLineEvent.h"
#import "InternalExtension.h"
#import "Line.h"

#import "JCPhoneNumberDataSourceUtils.h"
#import "JCMultiPersonPhoneNumber.h"

@implementation RecentLineEvent

@dynamic name;
@dynamic number;

#pragma mark - Relationships -

@dynamic internalExtension;
@dynamic line;
@dynamic phoneNumbers;

#pragma mark - Transient Properties -

-(NSString *)titleText
{
    NSString *name = self.name;
    if (!name) {
        InternalExtension *internalExtension = self.internalExtension;
        NSArray *localContacts = self.phoneNumbers.allObjects;
        if (internalExtension) {
            name = internalExtension.titleText;
        } else if (localContacts.count > 0) {
            name = [JCMultiPersonPhoneNumber multiPersonPhoneNumberWithPhoneNumbers:localContacts].name;
        } else {
            name = NSLocalizedString(@"Unknown", nil);
        }
    }
    return name;
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

-(BOOL)isEqualToPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    return [JCPhoneNumberDataSourceUtils phoneNumber:self
                                isEqualToPhoneNumber:phoneNumber];
}

@end
