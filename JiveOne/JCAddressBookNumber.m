//
//  JCAddressBookNumber.m
//  JiveOne
//
//  Created by Robert Barclay on 2/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAddressBookNumber.h"

@implementation JCAddressBookNumber

@synthesize name;
@synthesize number;

-(NSString *)detailText
{
    return [NSString stringWithFormat:@"%@: %@", self.type, self.number];
}

@end
