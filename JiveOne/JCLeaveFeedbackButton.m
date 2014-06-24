//
//  JCLeaveFeedbackButton.m
//  JiveOne
//
//  Created by Doug on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLeaveFeedbackButton.h"

@implementation JCLeaveFeedbackButton
- (void)drawRect:(CGRect)rect
{
    [JCStyleKit drawLeaveFeedback_ButtonWithFrame:self.bounds];
}
@end
