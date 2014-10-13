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

@dynamic timeStamp;

-(NSString *)formattedShortDate
{
    return [Common shortDateFromTimestamp:self.timeStamp];
}

@end
