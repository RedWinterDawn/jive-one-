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

#import "JCPhoneNumberUtils.h"
#import "JCMultiPersonPhoneNumber.h"

@implementation RecentLineEvent

@dynamic type;
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
    return [JCPhoneNumberUtils dialableStringForPhoneNumber:self];
}

-(NSString *)formattedNumber
{
    return [JCPhoneNumberUtils formattedPhoneNumberForPhoneNumber:self];
}

-(NSString *)t9
{
    return [JCPhoneNumberUtils t9StringForPhoneNumber:self];
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
    return [JCPhoneNumberUtils phoneNumber:self
                                isEqualToPhoneNumber:phoneNumber];
}

@end
