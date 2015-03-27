//
//  DID.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "DID.h"
#import "NSManagedObject+Additions.h"

#define DID_INDEX_OF_DID_ID_IN_JRN 6
//"jrn:pbx::jive:0127d974-f9f3-0704-2dee-000100420001:did:014885d6-1526-8b77-a111-000100420002",

NSString *const kDIDMakeCallAttribute       = @"makeCall";
NSString *const kDIDReceiveCallAttribute    = @"receiveCall";
NSString *const kDIDSendSMSAttribute        = @"sendSMS";
NSString *const kDIDReceiveSMSAttribute     = @"receiveSMS";

@implementation DID

@dynamic number;
@dynamic jrn;
@dynamic pbx;
@dynamic smsMessages;

#pragma mark - Setters -

-(void)setMakeCall:(BOOL)makeCall
{
    [self setPrimitiveValueFromBoolValue:makeCall forKey:kDIDMakeCallAttribute];
}

-(void)setReceiveCall:(BOOL)receiveCall
{
    [self setPrimitiveValueFromBoolValue:receiveCall forKey:kDIDReceiveCallAttribute];
}

-(void)setSendSMS:(BOOL)sendSMS
{
    [self setPrimitiveValueFromBoolValue:sendSMS forKey:kDIDSendSMSAttribute];
}

-(void)setReceiveSMS:(BOOL)receiveSMS
{
    [self setPrimitiveValueFromBoolValue:receiveSMS forKey:kDIDReceiveSMSAttribute];
}

#pragma mark - Getters -

-(BOOL)canMakeCall
{
    return [self boolValueFromPrimitiveValueForKey:kDIDMakeCallAttribute];
}

-(BOOL)canReceiveCall
{
    return [self boolValueFromPrimitiveValueForKey:kDIDReceiveCallAttribute];
}

-(BOOL)canSendSMS
{
    return [self boolValueFromPrimitiveValueForKey:kDIDSendSMSAttribute];
}

-(BOOL)canReceiveSMS
{
    return [self boolValueFromPrimitiveValueForKey:kDIDReceiveSMSAttribute];
}

-(NSString *)didId
{
    return [[self class] identifierFromJrn:self.jrn index:DID_INDEX_OF_DID_ID_IN_JRN];
}

@end
