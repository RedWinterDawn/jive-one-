//
//  JCRoundedView.h
//  JiveOne
//
//  This UIView Subclass porovides a simple elegant way of providing acesses into Quartz Core functionality to privide a
//  rounded view in storyboarding, in a single UIVView subclass. It is configurable and a border can be specified all by
//  setting appropriate runtime attributes.
//
//  Created by Robert Barclay on 10/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define DEFAULT_ROUNDED_VIEW_CORNER_RADIUS 2
#define DEFAULT_ROUNDED_VIEW_BORDER_WIDTH 0
#define DEFAULT_ROUNDED_VIEW_BORDER_COLOR [UIColor clearColor]

@interface JCRoundedView : UIView

// Configurable Properties.
@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) UIColor *borderColor;

@end
