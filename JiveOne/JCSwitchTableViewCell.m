//
//  JCSwitchTableViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 7/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSwitchTableViewCell.h"

@implementation JCSwitchTableViewCell

@dynamic textLabel;

-(void)setEnabled:(BOOL)enabled
{
    self.userInteractionEnabled = enabled;
    self.switchBtn.enabled = enabled;
    self.textLabel.enabled = enabled;
    self.detailTextLabel.enabled = enabled;
}

@end
