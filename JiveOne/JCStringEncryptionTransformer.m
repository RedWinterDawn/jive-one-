//
//  JCStringEncryptionTransformer.m
//  JiveOne
//
//  Created by Robert Barclay on 12/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCStringEncryptionTransformer.h"

@implementation JCStringEncryptionTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

-(id)transformedValue:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [super transformedValue:data];
}

-(id)reverseTransformedValue:(NSData *)data
{
    if (!data)
        return nil;
    
    data = [super reverseTransformedValue:data];
    
    __autoreleasing NSString *string = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    return string;
}

@end
