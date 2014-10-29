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
    
    Call *call = self.call;
    self.name.text = call.name;
    self.number.text = call.number;
    self.timestamp.text = call.formattedModifiedShortDate;
    self.extension.text = call.extension;
    self.icon.image = call.icon;
}

#pragma mark - Setters -

-(void)setCall:(Call *)call
{
    self.recentEvent = call;
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
