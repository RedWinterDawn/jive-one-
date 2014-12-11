//
//  Lines.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Line.h"
#import "NSManagedObject+JCCoreDataAdditions.h"
#import "PBX.h"

NSString *const kLineActiveAttribute = @"active";

@implementation Line

@dynamic mailboxJrn;
@dynamic mailboxUrl;

@dynamic events;
@dynamic lineConfiguration;
@dynamic pbx;

-(void)setActive:(BOOL)active
{
    [self setPrimitiveValueFromBoolValue:active forKey:kLineActiveAttribute];
}

-(BOOL)isActive
{
    return [self boolValueFromPrimitiveValueForKey:kLineActiveAttribute];
}

-(NSString *)detailText
{
    NSString * detailText = super.detailText;
    if (self.pbx) {
        NSString *name = self.pbx.name;
        if (name && !name.isEmpty) {
            detailText = [NSString stringWithFormat:@"%@ on %@", self.extension, name];
        }
        else {
            detailText = [NSString stringWithFormat:@"%@", self.extension];
        }
    }
    return detailText;
}

-(NSString *)lineId
{
    NSArray *elements = [self.jrn componentsSeparatedByString:@":"];
    return elements.lastObject;
}

@end
