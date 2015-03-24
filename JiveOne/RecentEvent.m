//
//  RecentEvent.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "RecentEvent.h"
#import "Common.h"

#import "NSManagedObject+JCCoreDataAdditions.h"

NSString *const kRecentEventReadKey = @"read";

@implementation RecentEvent

@dynamic date;
@dynamic eventId;

-(void)setRead:(bool)read
{
    [self setPrimitiveValueFromBoolValue:read forKey:kRecentEventReadKey];
}

-(bool)isRead
{
    return [self boolValueFromPrimitiveValueForKey:kRecentEventReadKey];
}


#pragma mark - Transient Properties -

-(void)setUnixTimestamp:(long long)unixTimestamp
{
    self.timestamp = [NSNumber numberWithLongLong:unixTimestamp];
}

-(void)setTimestamp:(NSNumber *)timestamp
{
    self.date = [Common dateFromTimestamp:timestamp];
}

#pragma mark - Getters -

-(long long)unixTimestamp
{
    return [self.date timeIntervalSince1970];
}

-(NSNumber *)timestamp
{
    return [NSNumber numberWithLongLong:self.unixTimestamp];
}

-(NSString *)formattedModifiedShortDate
{
    return [Common formattedModifiedShortDate:self.date];
}

-(NSString *)formattedLongDate
{
    return [Common formattedLongDate:self.date];
}

-(NSString *)detailText
{
    return self.formattedModifiedShortDate;
}

@end
