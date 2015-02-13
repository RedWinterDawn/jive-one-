//
//  JCMessageParticipant.m
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCUnknownNumber.h"

@implementation JCUnknownNumber

+(instancetype)unknownNumberWithNumber:(NSString *)number
{
    JCUnknownNumber *unknownNumber = [self new];
    unknownNumber.number = number;
    return unknownNumber;
}

-(NSString *)name
{
    return self.number;
}

-(NSString *)detailText
{
    return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Send SMS to", nil), self.name];
}

@end
