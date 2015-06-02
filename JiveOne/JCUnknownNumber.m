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
    NSString *name = NSLocalizedString(@"Unknown", nil);
    return [JCUnknownNumber phoneNumberWithName:name number:number];
}

@end
