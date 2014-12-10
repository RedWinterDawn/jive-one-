//
//  PBX.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "PBX.h"

#import "NSManagedObject+JCCoreDataAdditions.h"

NSString *const kPBXV5AttributeKey = @"v5";
NSString *const kPBXActiveAttributeKey = @"active";

@implementation PBX

@dynamic jrn;
@dynamic name;
@dynamic pbxId;
@dynamic selfUrl;
@dynamic user;
@dynamic lines;

#pragma mark - Setters -

-(void)setV5:(BOOL)v5
{
    [self setPrimitiveValueFromBoolValue:v5 forKey:kPBXV5AttributeKey];
}

-(void)setActive:(BOOL)active
{
    [self setPrimitiveValueFromBoolValue:active forKey:kPBXActiveAttributeKey];
}

#pragma mark - Getters -

-(BOOL)isV5
{
    return [self boolValueFromPrimitiveValueForKey:kPBXV5AttributeKey];
}

-(BOOL)isActive
{
    return [self boolValueFromPrimitiveValueForKey:kPBXActiveAttributeKey];
}

@end
