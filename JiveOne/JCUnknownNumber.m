//
//  JCMessageParticipant.m
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCUnknownNumber.h"

@interface JCUnknownNumber ()

@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSString *number;

@end

@implementation JCUnknownNumber

@synthesize name = _name;
@synthesize number = _number;

+(instancetype)unknownNumberWithNumber:(NSString *)number
{
    JCUnknownNumber *unknownNumber = [self new];
    unknownNumber.name = NSLocalizedString(@"Unknown", nil);
    unknownNumber.number = number;
    return unknownNumber;
}

-(NSString *)dialableNumber
{
    return self.number.dialableString;
}

-(NSString *)detailText
{
    return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Send SMS to", nil), self.name];
}

@end
