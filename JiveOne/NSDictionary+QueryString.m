//
//  NSDictionary+QueryString.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 5/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "NSDictionary+QueryString.h"
#import "NSString+URLEncoding.h"

@implementation NSDictionary (QueryString)

+ (NSDictionary *)dictionaryWithQueryString:(NSString *)queryString
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSArray *pairs = [queryString componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs)
    {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        if (elements.count == 2)
        {
            NSString *key = elements[0];
            NSString *value = elements[1];
            NSString *decodedKey = [key URLDecodedString];
            NSString *decodedValue = [value URLDecodedString];
            
            if (![key isEqualToString:decodedKey])
                key = decodedKey;
            
            if (![value isEqualToString:decodedValue])
                value = decodedValue;
            
            [dictionary setObject:value forKey:key];
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSString *)queryStringValue
{
    NSMutableArray *pairs = [NSMutableArray array];
    for (NSString *key in [self keyEnumerator])
    {
        id value = [self objectForKey:key];
        NSString *escapedValue = [value URLEncodedString];
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escapedValue]];
    }
    
    return [pairs componentsJoinedByString:@"&"];
}

@end
