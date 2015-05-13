//
//  RecentLineEvent.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "RecentLineEvent.h"
#import "Contact.h"
#import "Line.h"

#import "JCPhoneNumberDataSourceUtils.h"
#import "JCMultiPersonPhoneNumber.h"

@implementation RecentLineEvent

@dynamic name;
@dynamic number;

#pragma mark - Relationships -

@dynamic contact;
@dynamic line;
@dynamic localContacts;

#pragma mark - Transient Properties -

-(NSString *)titleText
{
    NSString *name = self.name;
    if (!name) {
        Contact *contact = self.contact;
        NSArray *localContacts = self.localContacts.allObjects;
        if (contact) {
            name = contact.titleText;
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
