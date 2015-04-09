//
//  Lines.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Line.h"
#import "NSManagedObject+Additions.h"
#import "PBX.h"
#import "NSString+Additions.h"

#define LINE_INDEX_OF_LINE_IN_JRN 5
// "jrn:line::jive:0144096e-bb05-ff06-702e-000100420002:0146db6f-52c9-9895-f67d-000100620002",

NSString *const kLineActiveAttribute = @"active";

@implementation Line

@dynamic mailboxJrn;
@dynamic mailboxUrl;

-(void)setActive:(BOOL)active
{
    [self setPrimitiveValueFromBoolValue:active forKey:kLineActiveAttribute];
}

-(BOOL)isActive
{
    return [self boolValueFromPrimitiveValueForKey:kLineActiveAttribute];
}

#pragma mark - Relationships -

@dynamic events;
@dynamic lineConfiguration;
@dynamic pbx;

#pragma mark - Transient Properties -

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
    return [[self class] identifierFromJrn:self.jrn index:LINE_INDEX_OF_LINE_IN_JRN];
}

-(NSString *)pbxId
{
    PBX *pbx = self.pbx;
    return pbx.pbxId;
}

@end
