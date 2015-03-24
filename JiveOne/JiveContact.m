//
//  JiveContact.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JiveContact.h"

@implementation JiveContact

@dynamic extension;
@dynamic jrn;
@dynamic pbxId;

-(NSString *)detailText
{
    return self.extension;
}

@end
