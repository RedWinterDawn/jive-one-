//
//  LineConfiguration.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "LineConfiguration.h"
#import "NSManagedObject+JCCoreDataAdditions.h"

NSString *const kLineConfigurationActiveAttribute = @"active";

@implementation LineConfiguration

-(void)setActive:(BOOL)active
{
    [self setPrimitiveValueFromBoolValue:active forKey:kLineConfigurationActiveAttribute];
}

-(BOOL)isActive
{
    return [self boolValueFromPrimitiveValueForKey:kLineConfigurationActiveAttribute];
}

@dynamic display;
@dynamic outboundProxy;
@dynamic registrationHost;
@dynamic sipUsername;
@dynamic sipPassword;

@end
