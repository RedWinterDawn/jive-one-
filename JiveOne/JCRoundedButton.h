//
//  JCRoundedView.h
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

@interface JCRoundedButton : UIButton
{
    UIColor *_defaultBackgroundColor;
}

@property (nonatomic, strong) UIColor *selectedBackgroundColor;

// Configurable Properties.
@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) UIColor *borderColor;

@end
