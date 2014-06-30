//
//  JCVoicemailIcon.m
//  JiveOne
//
//  Created by Doug on 6/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailIcon.h"
#import "JCStyleKit.h"
@implementation JCVoicemailIcon
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}
- (void)drawRect:(CGRect)rect
{
    [JCStyleKit drawVoicemailIconWhiteWithFrame:self.bounds];
}
@end
