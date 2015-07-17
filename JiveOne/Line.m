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
#import "LineConfiguration.h"
#import "PBX.h"

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

-(NSString *)lineId
{
    return self.extensionId;
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
            detailText = [NSString stringWithFormat:@"%@ on %@", self.number, name];
        }
        else {
            detailText = [NSString stringWithFormat:@"%@", self.number];
        }
    }
    return detailText;
}



-(NSString *)mailboxId
{
    NSString *seperateString = [self.mailboxJrn componentsSeparatedByString:@":"].lastObject;
    return [seperateString componentsSeparatedByString:@"/"].lastObject;
}

-(NSString *)pbxId
{
    PBX *pbx = self.pbx;
    return pbx.pbxId;
}

#pragma mark - JCSipManagerDataSource -

-(BOOL)isProvisioned
{
    return (self.lineConfiguration != nil);
}

-(BOOL)isV5
{
    return self.pbx.isV5;
}

-(NSString *)displayName
{
    return self.lineConfiguration.display;
}

-(NSString *)username
{
    return self.lineConfiguration.sipUsername;
}

-(NSString *)password
{
    return self.lineConfiguration.sipPassword;
}

-(NSString *)outboundProxy
{
    return self.lineConfiguration.outboundProxy;
}

-(NSString *)registrationHost
{
    return self.lineConfiguration.registrationHost;
}

-(NSString *)server
{
    return self.pbx.isV5 ? self.outboundProxy : self.registrationHost;
}

@end
