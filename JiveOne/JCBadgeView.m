//
//  JCBadgeView.m
//  JiveOne
//
//  Created by Robert Barclay on 11/5/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCBadgeView.h"

@implementation JCBadgeViewStyle

/* Creates default BadgeStyle which means:
 - Helvetica Neue Light as font
 - White text
 - Red background color
 - No frame, shadow or shining */
+ (instancetype) defaultStyle {
    id instance = [[super alloc] init];
    [instance setBadgeFontType:BadgeStyleFontTypeHelveticaNeueLight];
    [instance setBadgeTextColor:[UIColor whiteColor]];
    [instance setBadgeInsetColor:[UIColor redColor]];
    [instance setBadgeFrameColor:nil];
    [instance setBadgeFrame:NO];
    [instance setBadgeShadow:NO];
    [instance setBadgeShine:NO];
    return instance;
}

/* Creates prior to iOS7 style BadgeStyle which means:
 - Helvetica Neue Medium as font
 - White text
 - Red background color
 - With frame, shadow or shining */
+ (instancetype) oldStyle {
    id instance = [[super alloc] init];
    [instance setBadgeFontType:BadgeStyleFontTypeHelveticaNeueMedium];
    [instance setBadgeTextColor:[UIColor whiteColor]];
    [instance setBadgeInsetColor:[UIColor redColor]];
    [instance setBadgeFrameColor:[UIColor whiteColor]];
    [instance setBadgeFrame:YES];
    [instance setBadgeShadow:YES];
    [instance setBadgeShine:YES];
    return instance;
}

/* Create your own BadgeStyle */
+ (instancetype) freeStyleWithTextColor:(UIColor*)textColor withInsetColor:(UIColor*)insetColor withFrameColor:(UIColor*)frameColor withFrame:(BOOL)frame withShadow:(BOOL)shadow withShining:(BOOL)shining withFontType:(BadgeStyleFontType)fontType {
    
    id instance = [[super alloc] init];
    [instance setBadgeFontType:fontType];
    [instance setBadgeTextColor:textColor];
    [instance setBadgeInsetColor:insetColor];
    [instance setBadgeFrameColor:frameColor];
    [instance setBadgeFrame:frame];
    [instance setBadgeShadow:shadow];
    [instance setBadgeShine:shining];
    return instance;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    id copy = [[JCBadgeViewStyle alloc] init];
    if (copy) {
        [copy setBadgeTextColor:[self.badgeTextColor copyWithZone:zone]];
        [copy setBadgeInsetColor:[self.badgeInsetColor copyWithZone:zone]];
        [copy setBadgeFrameColor:[self.badgeFrameColor copyWithZone:zone]];
        [copy setBadgeFontType:self.badgeFontType];
        [copy setBadgeFrame:self.badgeFrame];
        [copy setBadgeShine:self.badgeShine];
        [copy setBadgeShadow:self.badgeShadow];
    }
    return copy;
}

@end

@interface JCBadgeView ()
{
    CGFloat _defaultWidth;
}

@end

@implementation JCBadgeView

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.badgeStyle = [JCBadgeViewStyle defaultStyle];
        self.badgeCornerRoundness = 0.4;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(void)awakeFromNib
{
    _defaultWidth = self.width.constant;
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawRoundedRectWithContext:context withRect:rect];
    
    if(self.badgeStyle.badgeShine) {
        [self drawShineWithContext:context withRect:rect];
    }
    
    if (self.badgeStyle.badgeFrame)  {
        [self drawFrameWithContext:context withRect:rect];
    }
    
    if ([self.badgeText length]>0) {
        CGFloat sizeOfFont = 13.5;
        if ([self.badgeText length]<2) {
            sizeOfFont += sizeOfFont * 0.20f;
        }
        UIFont *textFont =  [self fontForBadgeWithSize:sizeOfFont];
        NSDictionary *fontAttr = @{ NSFontAttributeName : textFont, NSForegroundColorAttributeName : self.badgeStyle.badgeTextColor };
        CGSize textSize = [self.badgeText sizeWithAttributes:fontAttr];
        CGPoint textPoint = CGPointMake((rect.size.width/2-textSize.width/2), (rect.size.height/2-textSize.height/2) - 1 );
        [self.badgeText drawAtPoint:textPoint withAttributes:fontAttr];
    }
}

#pragma mark - Setters -

-(void)setBadgeText:(NSString *)badgeText
{
    _badgeText = badgeText;
    [self autoBadgeSizeWithString:badgeText];
}


-(void)setBadgeTextColor:(UIColor *)badgeTextColor
{
    self.badgeStyle.badgeTextColor = badgeTextColor;
    [self setNeedsDisplay];
}

-(void)setBadgeInsetColor:(UIColor *)badgeInsetColor
{
    self.badgeStyle.badgeInsetColor = badgeInsetColor;
    [self setNeedsDisplay];
}

-(void)setBadgeFrameColor:(UIColor *)badgeFrameColor
{
    self.badgeStyle.badgeFrameColor = badgeFrameColor;
    [self setNeedsDisplay];
}

-(void)setBadgeFontType:(BadgeStyleFontType)badgeFontType
{
    self.badgeStyle.badgeFontType = badgeFontType;
    [self setNeedsDisplay];
}

-(void)setBadgeFrame:(BOOL)badgeFrame
{
    self.badgeStyle.badgeFrame = badgeFrame;
    [self setNeedsDisplay];
}

-(void)setBadgeShine:(BOOL)badgeShine
{
    self.badgeStyle.badgeShine = badgeShine;
    [self setNeedsDisplay];
}

-(void)setBadgeShadow:(BOOL)badgeShadow
{
    self.badgeStyle.badgeShadow = badgeShadow;
    [self setNeedsDisplay];
}

#pragma mark - Getters -

-(UIColor *)badgeTextColor
{
    return self.badgeStyle.badgeTextColor;
}

-(UIColor *)badgeInsetColor
{
    return self.badgeStyle.badgeInsetColor;
}

-(UIColor *)badgeFrameColor
{
    return self.badgeStyle.badgeFrameColor;
}

-(BOOL)badgeFrame
{
    return self.badgeStyle.badgeFrame;
}

-(BOOL)badgeShine
{
    return self.badgeStyle.badgeShine;
}

-(BOOL)badgeShadow
{
    return self.badgeStyle.badgeShadow;
}

#pragma mark - Private -

- (UIFont *)fontForBadgeWithSize:(CGFloat)size {
    switch (self.badgeStyle.badgeFontType) {
        case BadgeStyleFontTypeHelveticaNeueMedium:
            return [UIFont fontWithName:@"HelveticaNeue-Medium" size:size];
            break;
        default:
            return [UIFont fontWithName:@"HelveticaNeue-Light" size:size];
            break;
    }
}

- (void)autoBadgeSizeWithString:(NSString *)badgeString
{
    CGFloat newWidth = _defaultWidth;
    NSDictionary *fontAttr = @{ NSFontAttributeName : [self fontForBadgeWithSize:12] };
    if (badgeString.length >= 2)
    {
        newWidth = _defaultWidth + ([badgeString sizeWithAttributes:fontAttr].width + badgeString.length);
    }
    
    self.width.constant = newWidth;
    [self.superview setNeedsUpdateConstraints];
    [self setNeedsDisplay];
}

// Draws the Badge with Quartz
-(void) drawRoundedRectWithContext:(CGContextRef)context withRect:(CGRect)rect
{
    CGContextSaveGState(context);
    
    CGFloat radius = CGRectGetMaxY(rect)*self.badgeCornerRoundness;
    CGFloat puffer = CGRectGetMaxY(rect)*0.10;
    CGFloat maxX = CGRectGetMaxX(rect) - puffer;
    CGFloat maxY = CGRectGetMaxY(rect) - puffer;
    CGFloat minX = CGRectGetMinX(rect) + puffer;
    CGFloat minY = CGRectGetMinY(rect) + puffer;
    
    CGContextBeginPath(context);
    CGContextSetFillColorWithColor(context, [self.badgeStyle.badgeInsetColor CGColor]);
    CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI+(M_PI/2), 0, 0);
    CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0, M_PI/2, 0);
    CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2, M_PI, 0);
    CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2, 0);
    if (self.badgeStyle.badgeShadow) {
        CGContextSetShadowWithColor(context, CGSizeMake(1.0,1.0), 3, [[UIColor blackColor] CGColor]);
    }
    CGContextFillPath(context);
    
    CGContextRestoreGState(context);
    
}

// Draws the Badge Shine with Quartz
-(void) drawShineWithContext:(CGContextRef)context withRect:(CGRect)rect
{
    CGContextSaveGState(context);
    
    CGFloat radius = CGRectGetMaxY(rect)*self.badgeCornerRoundness;
    CGFloat puffer = CGRectGetMaxY(rect)*0.10;
    CGFloat maxX = CGRectGetMaxX(rect) - puffer;
    CGFloat maxY = CGRectGetMaxY(rect) - puffer;
    CGFloat minX = CGRectGetMinX(rect) + puffer;
    CGFloat minY = CGRectGetMinY(rect) + puffer;
    CGContextBeginPath(context);
    CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI+(M_PI/2), 0, 0);
    CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0, M_PI/2, 0);
    CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2, M_PI, 0);
    CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2, 0);
    CGContextClip(context);
    
    
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 0.4 };
    CGFloat components[8] = {  0.92, 0.92, 0.92, 1.0, 0.82, 0.82, 0.82, 0.4 };
    
    CGColorSpaceRef cspace;
    CGGradientRef gradient;
    cspace = CGColorSpaceCreateDeviceRGB();
    gradient = CGGradientCreateWithColorComponents (cspace, components, locations, num_locations);
    
    CGPoint sPoint, ePoint;
    sPoint.x = 0;
    sPoint.y = 0;
    ePoint.x = 0;
    ePoint.y = maxY;
    CGContextDrawLinearGradient (context, gradient, sPoint, ePoint, 0);
    
    CGColorSpaceRelease(cspace);
    CGGradientRelease(gradient);
    
    CGContextRestoreGState(context);
}


// Draws the Badge Frame with Quartz
-(void) drawFrameWithContext:(CGContextRef)context withRect:(CGRect)rect
{
    CGFloat radius = CGRectGetMaxY(rect)*self.badgeCornerRoundness;
    CGFloat puffer = CGRectGetMaxY(rect)*0.10;
    
    CGFloat maxX = CGRectGetMaxX(rect) - puffer;
    CGFloat maxY = CGRectGetMaxY(rect) - puffer;
    CGFloat minX = CGRectGetMinX(rect) + puffer;
    CGFloat minY = CGRectGetMinY(rect) + puffer;
    
    
    CGContextBeginPath(context);
    CGFloat lineSize = 2;
    /*CGFloat scaleFactor = [[UIScreen mainScreen] scale];
    
    if(scaleFactor > 1) {
        lineSize += scaleFactor * 0.25;
    }*/
    CGContextSetLineWidth(context, lineSize);
    CGContextSetStrokeColorWithColor(context, [self.badgeStyle.badgeFrameColor CGColor]);
    CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI+(M_PI/2), 0, 0);
    CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0, M_PI/2, 0);
    CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2, M_PI, 0);
    CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2, 0);
    CGContextClosePath(context);
    CGContextStrokePath(context);
}

@end
