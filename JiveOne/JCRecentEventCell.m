//
//  JCRecentEventCell.m
//  JiveOne
//
//  Created by Robert Barclay on 10/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentEventCell.h"

@implementation JCRecentEventCell

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.date.text = self.recentEvent.formattedModifiedShortDate;
    self.name.text = self.recentEvent.displayName;
    self.number.text = self.recentEvent.displayNumber;
}

@end
