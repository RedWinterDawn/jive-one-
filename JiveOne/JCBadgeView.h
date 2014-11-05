//
//  JCBadgeView.h
//  JiveOne
//
//  Created by Robert Barclay on 11/5/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

typedef enum : NSUInteger {
    BadgeStyleFontTypeHelveticaNeueMedium,
    BadgeStyleFontTypeHelveticaNeueLight,
} BadgeStyleFontType;

@interface JCBadgeViewStyle : NSObject <NSCopying>

@property(nonatomic, strong) UIColor *badgeTextColor;
@property(nonatomic, strong) UIColor *badgeInsetColor;
@property(nonatomic, strong) UIColor *badgeFrameColor;
@property(nonatomic) BadgeStyleFontType badgeFontType;
@property(nonatomic) BOOL badgeFrame;
@property(nonatomic) BOOL badgeShine;
@property(nonatomic) BOOL badgeShadow;

+ (instancetype) defaultStyle;
+ (instancetype) freeStyleWithTextColor:(UIColor*)textColor
                         withInsetColor:(UIColor*)insetColor
                         withFrameColor:(UIColor*)frameColor
                              withFrame:(BOOL)frame
                             withShadow:(BOOL)shadow
                            withShining:(BOOL)shining
                           withFontType:(BadgeStyleFontType)fontType;

@end

@interface JCBadgeView : UIView

@property(nonatomic, strong) IBOutlet NSLayoutConstraint *width;

@property(nonatomic, strong) NSString *badgeText;
@property(nonatomic) JCBadgeViewStyle *badgeStyle;
@property(nonatomic) CGFloat badgeCornerRoundness;

// Storyboard Configurable Properties (sets the Badge View Style)
@property(nonatomic, strong) UIColor *badgeTextColor;
@property(nonatomic, strong) UIColor *badgeInsetColor;
@property(nonatomic, strong) UIColor *badgeFrameColor;
@property(nonatomic) BadgeStyleFontType badgeFontType;
@property(nonatomic) BOOL badgeFrame;
@property(nonatomic) BOOL badgeShine;
@property(nonatomic) BOOL badgeShadow;

@end
