//
//  RecentEvent.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "RecentEvent.h"
#import "Common.h"
#import "Contact.h"

#import "NSManagedObject+JCCoreDataAdditions.h"

NSString *const kRecentEventReadKey = @"read";

@implementation RecentEvent

@dynamic name;
@dynamic number;
@dynamic date;

#pragma mark - Setters -

-(void)setUnixTimestamp:(long long)unixTimestamp
{
    self.timestamp = [NSNumber numberWithLongLong:unixTimestamp];
}

-(void)setTimestamp:(NSNumber *)timestamp
{
    self.date = [Common dateFromTimestamp:timestamp];
}

-(void)setRead:(bool)read
{
    [self setPrimitiveValueFromBoolValue:read forKey:kRecentEventReadKey];
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

-(NSString *)displayName
{
    if (self.contact) {
        return self.contact.name;
    }
    
    NSString *name = [self.name stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    if ([name isEqualToString:@"*99"]) {
        return NSLocalizedString(@"Voicemail", nil);
    }
    return name;
}

-(NSString *)displayNumber
{
    if (self.contact) {
        return self.contact.extension;
    }
    return self.number;
}

-(bool)isRead
{
    return [self boolValueFromPrimitiveValueForKey:kRecentEventReadKey];
}

@dynamic line;
@dynamic contact;

@end
