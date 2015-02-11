//
//  NSString+DialString.m
//  JiveOne
//
//  Created by Robert Barclay on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "NSString+DialString.h"
#import "NSString+Additions.h"

NSString *const kDialStringStarKey = @"*";
NSString *const kDialStringPoundKey = @"#";

NSString *const kDialStringAKey = @"a";
NSString *const kDialStringBKey = @"b";
NSString *const kDialStringCKey = @"c";
NSString *const kDialStringDKey = @"d";
NSString *const kDialStringEKey = @"e";
NSString *const kDialStringFKey = @"f";
NSString *const kDialStringGKey = @"g";
NSString *const kDialStringHKey = @"h";
NSString *const kDialStringIKey = @"i";
NSString *const kDialStringJKey = @"j";
NSString *const kDialStringKKey = @"k";
NSString *const kDialStringLKey = @"l";
NSString *const kDialStringMKey = @"m";
NSString *const kDialStringNKey = @"n";
NSString *const kDialStringOKey = @"o";
NSString *const kDialStringPKey = @"p";
NSString *const kDialStringQKey = @"q";
NSString *const kDialStringRKey = @"r";
NSString *const kDialStringSKey = @"s";
NSString *const kDialStringTKey = @"t";
NSString *const kDialStringUKey = @"u";
NSString *const kDialStringVKey = @"v";
NSString *const kDialStringWKey = @"w";
NSString *const kDialStringXKey = @"x";
NSString *const kDialStringYKey = @"y";
NSString *const kDialStringZKey = @"z";

NSString *const kDialString0 = @"0";
NSString *const kDialString1 = @"1";
NSString *const kDialString2 = @"2";
NSString *const kDialString3 = @"3";
NSString *const kDialString4 = @"4";
NSString *const kDialString5 = @"5";
NSString *const kDialString6 = @"6";
NSString *const kDialString7 = @"7";
NSString *const kDialString8 = @"8";
NSString *const kDialString9 = @"9";

@implementation NSString (DialString)

-(NSString *)dialString
{
    NSMutableString *dialString = [NSMutableString string];
    
    NSUInteger length = self.length;
    unichar buffer[length+1];
    [self getCharacters:buffer range:NSMakeRange(0, length)];
    for(int i = 0; i < length; i++)
    {
        NSString *character = [self getDialStringCharFromString:[NSString stringWithFormat:@"%C", buffer[i]]];
        if (character)
            [dialString appendString:character];
    }
    
    // Return dial string if we can.
    if (dialString.length > 0)
        return dialString;
    
    return nil;
}

#pragma mark - Private -

/**
 * Coverts an input string to a proper dial string character. If charater is numeric, star or pound, it is returned. If 
 * it is A-Z, it is converted to be its numeric equivalent for that character.
 */
-(NSString *)getDialStringCharFromString:(NSString *)string
{
    if (string.isNumeric)
        return string;
    
    if ([string isEqualToString:kDialStringStarKey] ||
        [string isEqualToString:kDialStringPoundKey])
        return string;
    
    string = string.lowercaseString;
    if ([string isEqualToString:kDialStringAKey] ||
        [string isEqualToString:kDialStringBKey] ||
        [string isEqualToString:kDialStringCKey])
        return kDialString2;
    else if ([string isEqualToString:kDialStringDKey] ||
             [string isEqualToString:kDialStringEKey] ||
             [string isEqualToString:kDialStringFKey])
        return kDialString3;
    else if ([string isEqualToString:kDialStringGKey] ||
             [string isEqualToString:kDialStringHKey] ||
             [string isEqualToString:kDialStringIKey])
        return kDialString4;
    else if ([string isEqualToString:kDialStringJKey] ||
             [string isEqualToString:kDialStringKKey] ||
             [string isEqualToString:kDialStringLKey])
        return kDialString5;
    else if ([string isEqualToString:kDialStringMKey] ||
             [string isEqualToString:kDialStringNKey] ||
             [string isEqualToString:kDialStringOKey])
        return kDialString6;
    else if ([string isEqualToString:kDialStringPKey] ||
             [string isEqualToString:kDialStringQKey] ||
             [string isEqualToString:kDialStringRKey] ||
             [string isEqualToString:kDialStringSKey])
        return kDialString7;
    else if ([string isEqualToString:kDialStringTKey] ||
             [string isEqualToString:kDialStringUKey] ||
             [string isEqualToString:kDialStringVKey])
        return kDialString8;
    else if ([string isEqualToString:kDialStringWKey] ||
             [string isEqualToString:kDialStringXKey] ||
             [string isEqualToString:kDialStringYKey] ||
             [string isEqualToString:kDialStringZKey])
        return kDialString9;
    return nil;
}

@end
