//
//  LocalContact.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "LocalContact.h"
#import "NSManagedObject+Additions.h"

static NSString *LocalContactNumberAttributeKey = @"number";
static NSString *LocalContactNameAttributeKey   = @"name";

@implementation LocalContact

-(void)setNumber:(NSString *)number
{
    [self setPrimitiveValueFromStringValue:number forKey:LocalContactNumberAttributeKey];
}

-(NSString *)number
{
    return [self stringValueFromPrimitiveValueForKey:LocalContactNumberAttributeKey];
}

@dynamic number;
@dynamic personId;
@dynamic smsMessages;

@end
