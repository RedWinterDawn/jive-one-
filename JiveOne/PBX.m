//
//  PBX.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "PBX.h"
#import "DID.h"
#import "NSManagedObject+Additions.h"

#define PBX_INDEX_OF_PBX_ID_IN_JRN 4
// "jrn:pbx::jive:01471162-f384-24f5-9351-000100420005:pbx~default";

NSString *const kPBXV5AttributeKey = @"v5";

@implementation PBX

@dynamic domain;
@dynamic jrn;
@dynamic name;

-(void)setV5:(BOOL)v5
{
    [self setPrimitiveValueFromBoolValue:v5 forKey:kPBXV5AttributeKey];
}
-(BOOL)isV5
{
    return [self boolValueFromPrimitiveValueForKey:kPBXV5AttributeKey];
}

#pragma mark - Relationships -

@dynamic user;
@dynamic lines;
@dynamic contacts;
@dynamic dids;

#pragma mark - Transient -

-(NSString *)displayName
{
    return [NSString stringWithFormat:@"%@ PBX on %@", self.name, self.isV5 ? @"V5" : @"V4"];
}

-(NSString *)pbxId
{
    return [[self class] identifierFromJrn:self.jrn index:PBX_INDEX_OF_PBX_ID_IN_JRN];
}

-(BOOL)smsEnabled
{
    NSSet *dids = self.dids;
    for (DID *did in dids) {
        if (did.canSendSMS || did.canReceiveSMS) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)receiveSMSMessages
{
    NSSet *dids = self.dids;
    for (DID *did in dids) {
        if (did.canReceiveSMS) {
            return YES;
        }
    }
    return NO;
}
-(BOOL)sendSMSMessages
{
    NSSet *dids = self.dids;
    for (DID *did in dids) {
        if (did.canSendSMS) {
            return YES;
        }
    }
    return NO;
}

@end
