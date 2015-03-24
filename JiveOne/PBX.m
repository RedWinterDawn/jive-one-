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

@implementation PBX

@dynamic jrn;
@dynamic name;
@dynamic pbxId;
@dynamic user;
@dynamic lines;
@dynamic contacts;

#pragma mark - Setters -

-(void)setV5:(BOOL)v5
{
    [self setPrimitiveValueFromBoolValue:v5 forKey:kPBXV5AttributeKey];
}

#pragma mark - Getters -

-(BOOL)isV5
{
    return [self boolValueFromPrimitiveValueForKey:kPBXV5AttributeKey];
}

-(NSString *)displayName
{
    return [NSString stringWithFormat:@"%@ PBX on %@", self.name, self.isV5 ? @"V5" : @"V4"];
}

-(NSString *)pbxId
{
    NSString *jrn = self.jrn;
    
    // "jrn:pbx::jive:01471162-f384-24f5-9351-000100420005:pbx~default";
    NSString *pbxId = nil;
    NSArray *components = [jrn componentsSeparatedByString:@":"];
    if (components.count == 6) {
        pbxId = [components objectAtIndex:4];
    }
    return pbxId;
}

@end
