//
//  Lines.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Line.h"
#import "NSString+Custom.h"

@implementation Line

@dynamic displayName;
@dynamic externsionNumber;
@dynamic groups;
@dynamic inUse;
@dynamic isFavorite;
@dynamic jrn;
@dynamic lineId;
@dynamic pbxId;
@dynamic state;
@dynamic userName;
@dynamic mailboxJrn;
@dynamic mailboxUrl;

@dynamic events;
@dynamic lineConfiguration;
@dynamic pbx;

#pragma mark - Transient Attributes -

- (NSString *)firstLetter
{
    NSString *result = [self.displayName substringToIndex:1];
    return [result uppercaseString];
}

-(NSString *)detailText
{
    NSString * detailText = self.externsionNumber;
    PBX *pbx = [PBX MR_findFirstByAttribute:@"pbxId" withValue:self.pbxId];
    if (pbx) {
        NSString *name = pbx.name;
        if (name && !name.isEmpty) {
            detailText = [NSString stringWithFormat:@"%@ on %@", self.externsionNumber, name];
        }
        else {
            detailText = [NSString stringWithFormat:@"%@", self.externsionNumber];
        }
    }
    return detailText;
}

@end
