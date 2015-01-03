//
//  NSDictionary+Validations.m
//  JiveOne
//
//  Created by Robert Barclay on 11/4/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "NSDictionary+Validations.h"

NSString *const kNSStringEmptyString = @"";

@implementation NSDictionary (Validations)

-(NSString *)stringValueForKey:(NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSString class]])
    {
        NSString *string = (NSString *)object;
        if(![string isEqualToString:kNSStringEmptyString])
            return (NSString *)object;
    }
    return nil;
}

-(BOOL)boolValueForKey:(NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSNumber class]])
        return ((NSNumber *)object).boolValue;
    return FALSE;
}

-(double)doubleValueForKey:(NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSNumber class]])
        return ((NSNumber *)object).floatValue;
    else if([object isKindOfClass:[NSString class]])
    {
        NSString *string = (NSString *)object;
        double value = string.doubleValue;
        return value;
    }
    return 0.0f;
}

-(float)floatValueForKey:(NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSNumber class]])
        return ((NSNumber *)object).floatValue;
    else if([object isKindOfClass:[NSString class]])
    {
        NSString *string = (NSString *)object;
        float value = string.floatValue;
        return value;
    }
    return 0.0f;
}

-(NSDecimalNumber *)decimalNumberForKey:(NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSNumber class]])
    {
        NSNumber *number = (NSNumber *)object;
        NSDecimalNumber *decimalNumber = [[NSDecimalNumber alloc] initWithDecimal:number.decimalValue];
        return decimalNumber;
    }
    else if ([object isKindOfClass:[NSString class]])
    {
        NSString *string = (NSString *)object;
        NSNumberFormatter *numberFormat = [[NSNumberFormatter alloc] init];
        NSNumber *number = [numberFormat numberFromString:string];
        NSDecimalNumber *decimalNumber = [[NSDecimalNumber alloc] initWithDecimal:number.decimalValue];
        return decimalNumber;
    }
    return nil;
}

-(NSInteger)integerValueForKey:(NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSNumber class]])
        return ((NSNumber *)object).integerValue;
    if ([object isKindOfClass:[NSString class]])
    {
        NSString *string = (NSString *)object;
        NSNumberFormatter *numberFormat = [[NSNumberFormatter alloc] init];
        NSNumber *number = [numberFormat numberFromString:string];
        NSInteger integer = number.integerValue;
        return integer;
    }
    
    return 0;
}

static NSDateFormatter *dateFormatter = nil;

-(NSDate *)dateValueForKey:(NSString *)key
{
    NSString *string = [self stringValueForKey:key];
    if (string)
    {
        // If the date formatters aren't already set up, create them and cache them for reuse.
        if (dateFormatter == nil)
        {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyyMMdd"];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        }
        
        NSDate *date = [dateFormatter dateFromString:string];
        return date;
    }
    return nil;
}

static NSDateFormatter *timeFormatter = nil;

-(NSDate *)timeValueForKey:(NSString *)key
{
    NSString *string = [self stringValueForKey:key];
    if (string)
    {
        // If the date formatters aren't already set up, create them and cache them for reuse.
        if (timeFormatter == nil)
        {
            timeFormatter = [[NSDateFormatter alloc] init];
            [timeFormatter setDateFormat:@"HH:mm:ss"];
            [timeFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        }
        
        NSDate *date = [timeFormatter dateFromString:string];
        return date;
    }
    return nil;
}

-(NSURL *)urlValueForKey:(NSString *)key
{
    NSString *absoluteString = [self stringValueForKey:key];
    if (absoluteString)
        return [NSURL URLWithString:absoluteString];
    return nil;
}

-(NSDictionary *)dictionaryForKey:(NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSDictionary class]]) {
        return object;
    }
    return nil;
}

-(NSArray *)arrayForKey:(NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSArray class]]) {
        return object;
    }
    return nil;
}


@end

@implementation NSDictionary (Normalization)

+ (NSDictionary *)normalizeDictionaryFromArray:(NSArray *)array keyIdentifier:(NSString *)keyIdentifier valueIdentifier:(NSString *)valueIdentifier
{
    // Normalize Data into Key/value pairs.
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *item = (NSDictionary*)obj;
            NSString *key = [item stringValueForKey:keyIdentifier];
            NSString *value = [item stringValueForKey:valueIdentifier];
            [dictionary setObject:value forKey:key];
        }
    }];
    
    return (dictionary.count > 0) ? dictionary : nil;
}

@end
