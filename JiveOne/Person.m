//
//  Person.m
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Person.h"

@implementation Person

@dynamic jrn;
@dynamic name;
@dynamic extension;
@dynamic pbxId;

- (NSString *)firstLetter
{
    NSString *result = [self.name substringToIndex:1];
    return [result uppercaseString];
}

-(NSString *)detailText
{
   return self.extension;
}

@end
