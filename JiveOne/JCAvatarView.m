//
//  JCAvatarView.m
//  JiveOne
//
//  Created by Robert Barclay on 2/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAvatarView.h"

@implementation JCAvatarView

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.cornerRadius = 6;
        self.borderColor = [UIColor clearColor];
        self.borderWidth = 0;
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    // TODO: Use person to determine what to put where;
}

-(void)setPerson:(Person *)person
{
    _person = person;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
