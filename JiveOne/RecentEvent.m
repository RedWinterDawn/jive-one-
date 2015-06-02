//
//  RecentEvent.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "RecentEvent.h"
#import "Common.h"

#import "NSManagedObject+Additions.h"

NSString *const kRecentEventReadAttributeKey = @"read";
NSString *const kRecentEventMarkForDeletionAttributeKey = @"markForDeletion";

@implementation RecentEvent

@dynamic date;
@dynamic eventId;

-(void)setRead:(bool)read
{
    [self setPrimitiveValueFromBoolValue:read forKey:kRecentEventReadAttributeKey];
}

-(bool)isRead
{
    return [self boolValueFromPrimitiveValueForKey:kRecentEventReadAttributeKey];
}

-(void)setMarkForDeletion:(BOOL)markForDeletion
{
    [self setPrimitiveValueFromBoolValue:markForDeletion forKey:kRecentEventMarkForDeletionAttributeKey];
}

-(BOOL)isMarkedForDeletion
{
    return [self boolValueFromPrimitiveValueForKey:kRecentEventMarkForDeletionAttributeKey];
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
