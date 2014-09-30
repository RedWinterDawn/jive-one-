//
//  JCWarmTransferButton.m
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCWarmTransferButton.h"
#import "JCDialerOptions.h"


@interface JCWarmTransferButton()
@property (nonatomic) BOOL isSelected;
@property (nonatomic) JCDialerOptions* parentview;
@end

@implementation JCWarmTransferButton


-(void)setIsSelected:(BOOL)isSelected
{
    _isSelected = isSelected;
    [self setNeedsDisplay];
    
}

@end
