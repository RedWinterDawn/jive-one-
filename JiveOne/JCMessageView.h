//
//  JCMessageView.h
//  JiveOne
//
//  This view is a subclass of UIView that is meant to be sublcassed for drawing purposes to draw a
//  message bubble using core graphics. This class defines a configurable set of properties that can
//  be configured within a storyboard to define drawing paramters.
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

@interface JCMessageView : UIView
{
    UIColor *_bubbleColor;
    NSInteger _cornerRadius;
    NSInteger _margin;
}

@property (nonatomic, strong) UIColor *bubbleColor;
@property (nonatomic) NSInteger cornerRadius;
@property (nonatomic) NSInteger margin;

@end
