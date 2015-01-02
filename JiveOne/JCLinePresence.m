//
//  JCLinePresence.m
//  JiveOne
//
//  Created by Robert Barclay on 12/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLinePresence.h"

@implementation JCLinePresence

-(instancetype)initWithLineIdentifer:(NSString *)identifier
{
    self = [super init];
    if (self) {
        _identfier = identifier;
    }
    return self;
}

@end
