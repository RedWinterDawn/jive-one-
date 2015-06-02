//
//  NSDictionary+Validations.h
//  JiveOne
//
//  Created by Robert Barclay on 11/4/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Validations)

/**
 * Returns a string from the dictionary for the corresponding key. If the key
 * is not found or is not a string, returns nil.
 *
 * @param NSString key value to look up.
 * @returns NSString string value.
 */
-(NSString *)stringValueForKey:(NSString *)key;

// Primative conversion.
-(BOOL)boolValueForKey:(NSString *)key;
-(NSInteger)integerValueForKey:(NSString *)key;
-(double)doubleValueForKey:(NSString *)key;
-(float)floatValueForKey:(NSString *)key;
-(NSDecimalNumber *)decimalNumberForKey:(NSString *)key;

-(NSDate *)datetimeValueForKey:(NSString *)key;
-(NSDate *)dateValueForKey:(NSString *)key;
-(NSDate *)timeValueForKey:(NSString *)key;
-(NSURL *)urlValueForKey:(NSString *)key;

-(NSDictionary *)dictionaryForKey:(NSString *)key;
-(NSArray *)arrayForKey:(NSString *)key;

@end


@interface NSDictionary (Normalization)

+ (NSDictionary *)normalizeDictionaryFromArray:(NSArray *)array keyIdentifier:(NSString *)keyIdentifier valueIdentifier:(NSString *)valueIdentifier;

@end