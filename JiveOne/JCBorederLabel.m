//
//  JCBorederLabel.m
//  JiveOne
//
//  Created by P Leonard on 6/15/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBorederLabel.h"
#import "JCDrawing.h"

#define DEFAULT_SEPERATOR_COLOR [UIColor colorWithRed:200/255.0 green:199/255.0 blue:204/255.0 alpha:1.0]

@implementation JCBorederLabel



// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    //Create a line to put on the lable with a width and color.
    JCDrawingLine line = JCDrawingLineMake(0.5, DEFAULT_SEPERATOR_COLOR.CGColor);
    //Use that line and attach it to the right side of the rect 
    JCDrawingContextDrawLineAtPosition(context, line, rect, kJCDrawingLinePositionRight);
    
    
}


@end
