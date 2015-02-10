//
//  SMSMessage.m
//  JiveOne
//
//  Created by Robert Barclay on 1/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "SMSMessage.h"

@implementation SMSMessage

-(NSString *)detailText {
    return [NSString stringWithFormat:@"SMS at %@", self.formattedModifiedShortDate];
}

@end
