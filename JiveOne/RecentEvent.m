//
//  RecentEvent.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "RecentEvent.h"
#import "Common.h"

@implementation RecentEvent

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

@end
