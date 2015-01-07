//
//  JCEncryptionTransformer.m
//  JiveOne
//
//  Created by Robert Barclay on 12/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCEncryptionTransformer.h"
#import "NSData+AESAddition.h"

@interface JCEncryptionTransformer ()

@property (nonatomic, readonly) NSString *encryptionKey;

@end


@implementation JCEncryptionTransformer

// Static Methods

+ (Class)transformedValueClass
{
    return [NSData class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

// Properties

-(NSString *)encryptionKey
{
    return [UIDevice currentDevice].installationIdentifier;
}

- (id)transformedValue:(NSData *)data
{
    if (!data || data.length == 0)
        return nil;
    
    NSString *key = self.encryptionKey;
    return [data AES256EncryptWithKey:key];
}

- (id)reverseTransformedValue:(NSData *)data
{
    if (!data || data.length == 0)
        return nil;
    
    NSString *key = self.encryptionKey;
    return [data AES256DecryptWithKey:key];
}


@end
