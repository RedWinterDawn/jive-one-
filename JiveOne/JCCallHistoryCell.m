//
//  JCHistoryCell.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallHistoryCell.h"

@implementation JCCallHistoryCell

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.number.text = self.call.number;
    
    self.icon.image = self.call.icon;
}

#pragma mark - Setters -

-(void)setRecentEvent:(RecentEvent *)recentEvent
{
    if ([self.call isKindOfClass:[Call class]]) {
        self.call = (Call *)recentEvent;
    }
}

-(void)setCall:(Call *)call
{
    super.recentEvent = call;
    [self setNeedsLayout];
}

#pragma mark - Getters -

-(Call *)call
{
    RecentEvent *recentEvent = self.recentEvent;
    if ([recentEvent isKindOfClass:[Call class]]) {
        return (Call *)self.recentEvent;
    }
    return nil;
}


@end
