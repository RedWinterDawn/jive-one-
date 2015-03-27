//
//  RecentLineEvent.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "RecentLineEvent.h"
#import "Contact.h"
#import "Line.h"

@implementation RecentLineEvent

@dynamic name;
@dynamic number;
@dynamic extension;

#pragma mark - Transient Properties -

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
    return [NSString stringWithFormat:@"%li", (long)self.number];
}

#pragma mark - Relationships -

@dynamic contact;
@dynamic line;

@end
