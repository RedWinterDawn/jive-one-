//
//  JCRoundedView.m
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRoundedButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation JCRoundedButton

-(void)layoutSubviews{
    [super layoutSubviews];
    self.layer.cornerRadius = self.bounds.size.width/2;
    self.layer.masksToBounds = true;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
