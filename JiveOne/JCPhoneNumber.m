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

+(NBPhoneNumberUtil *)phoneNumberUtilities
{
    static NBPhoneNumberUtil *phoneNumberUtil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        phoneNumberUtil = [NBPhoneNumberUtil new];
    });
    return phoneNumberUtil;
}

+(instancetype)phoneNumberWithName:(NSString *)name number:(NSString *)number
{
    return [[[self class] alloc] initWithName:name number:number];
}

-(instancetype)initWithName:(NSString *)name number:(NSString *)number
{
    NSString *extension;
    if ([number rangeOfString:@";"].location != NSNotFound)
    {
        NSArray *components = [number componentsSeparatedByString:@";"];
        if (components.count == 2) {
            number = components.firstObject;
            extension = components.lastObject;
        }
    }
    
    __autoreleasing NSError *error;
    NBPhoneNumber *phoneNumber = [[[self class] phoneNumberUtilities] parse:number defaultRegion:@"US" error:&error];
    self = [super init];
    if (self) {
        if (!number) {
            return nil;
        }
        _number                         = [number copy];
        _countryCode                    = phoneNumber.countryCode;
        _nationalNumber                 = phoneNumber.nationalNumber;
        _extension                      = extension ? extension : phoneNumber.extension;
        _countryCodeSource              = phoneNumber.countryCodeSource;
        _preferredDomesticCarrierCode   = phoneNumber.preferredDomesticCarrierCode;
        _italianLeadingZero             = phoneNumber.italianLeadingZero;
        
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
    NSString *name = self.name;
    if (!name) {
        name = NSLocalizedString(@"Unknown", nil);
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

-(NSString *)internationalNumber
{
    return [NSString stringWithFormat:@"+%@%@", self.countryCode, self.nationalNumber];
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

-(BOOL)isEqual:(id)object
{
    return [JCPhoneNumberDataSourceUtils phoneNumber:self
                                             isEqual:object];
}

@end
