//
//  LocalContact.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "PhoneNumber.h"
#import "NSManagedObject+Additions.h"

@implementation PhoneNumber

-(void)setOrder:(NSInteger)order
{
    [self setPrimitiveValueFromIntegerValue:order forKey:NSStringFromSelector(@selector(order))];
}

-(NSInteger)order
{
    return [self integerValueFromPrimitiveValueForKey:NSStringFromSelector(@selector(order))];
}

@dynamic type;
@dynamic smsMessages;
@dynamic lineEvents;
@dynamic contact;

@synthesize phoneNumber;

@end