//
//  JCPopoverSlider.m
//  JiveOne
//
//  Created by Doug on 5/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPopoverSlider.h"

#define POPOVER_SLIDER_MINIMUM_IMG          @"slider_min.png"
#define POPOVER_SLIDER_MINIMUM_IMG_INSETS   UIEdgeInsetsMake(0, 0, 0, 5)

#define POPOVER_SLIDER_MAXIMUM_IMG          @"slider_maximum.png"
#define POPOVER_SLIDER_MAXIMUM_IMG_INSETS   UIEdgeInsetsMake(0, 0, 0, 5)

#define POPOVER_SLIDER_THUMB_DIAMETER       20
#define POPOVER_SLIDER_THUMB_COLOR          [UIColor blueColor]
#define POPOVER_SLIDER_THUMB_BORDER_COLOR   [UIColor colorWithRed:0.275 green: 0.396 blue: 0.843 alpha:1]
#define POPOVER_SLIDER_THUMB_BORDER_WIDTH   1

#define POPOVER_SLIDER_TRACK_HEIGHT         3           

@interface JCPopoverView : UIView

@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UILabel *textLabel;

- (instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color;

@end

@interface JCPopoverSlider()
{
    UIImage *_simpleThumbImage;
    NSCache *_thumbImageCache;
}

@property (atomic) BOOL touchIsCurrentlyHappening;
@property (strong, nonatomic) JCPopoverView *popupView;

@end

@implementation JCPopoverSlider

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.continuous = YES;
        [self addTarget:self action:@selector(updateThumb) forControlEvents:UIControlEventValueChanged];
        
        _thumbDiameter      = POPOVER_SLIDER_THUMB_DIAMETER;
        _thumbBorderWidth   = POPOVER_SLIDER_THUMB_BORDER_WIDTH;
        _trackHeight        = POPOVER_SLIDER_TRACK_HEIGHT;
        
        _thumbImageCache            = [NSCache new];
        _thumbImageCache.name       = @"JCPopoverSlider.thumbImageCache";
        _thumbImageCache.countLimit = 200;
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    _simpleThumbImage = [self thumbImageWithDiameter:_thumbDiameter
                                               color:self.tintColor
                                         borderColor:self.tintColor
                                         borderWidth:_thumbBorderWidth];
    [self updateThumb];
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    CGRect rect = [super trackRectForBounds:bounds];
    return CGRectMake(rect.origin.x, (self.bounds.size.height/2 - _trackHeight/2), rect.size.width, _trackHeight);
}

#pragma mark - UIControl touch event tracking

-(BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super beginTrackingWithTouch:touch withEvent:event];
    
    self.touchIsCurrentlyHappening = YES;
    [self updateThumb];
    [self positionAndUpdatePopupView];
    [self showPopupView:YES];
    return YES;
}

-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (self.touchIsCurrentlyHappening == NO) {
        self.touchIsCurrentlyHappening = YES;
        [self updateThumb];
    }
    
    [super continueTrackingWithTouch:touch withEvent:event];
    [self positionAndUpdatePopupView];
    return YES;
}

-(void)cancelTrackingWithEvent:(UIEvent *)event
{
    [super cancelTrackingWithEvent:event];
    self.touchIsCurrentlyHappening = NO;
    [self updateThumb];
}

-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    self.touchIsCurrentlyHappening = NO;
    [self updateThumb];
    [self hidePopupView:YES];
    [super endTrackingWithTouch:touch withEvent:event];
}

#pragma mark - Getters -

-(JCPopoverView *)popupView
{
    if (!_popupView) {
        _popupView = [[JCPopoverView alloc] initWithFrame:CGRectZero color:self.tintColor];
    }
    return _popupView;
}

-(NSString *)formattedValue
{
    NSTimeInterval seconds = self.value;
    NSInteger minutes = (NSInteger)(seconds/60.);
    NSInteger remainingSeconds = (NSInteger)seconds % 60;
    return [NSString stringWithFormat:@"%.1ld:%.2ld",(long)minutes,(long)remainingSeconds];
}

#pragma mark - Setters -

-(void)setValue:(float)value
{
    [super setValue:value];
    [self updateThumb];
}

-(void)setThumbImage:(UIImage *)image
{
    [self setThumbImage:image forState:UIControlStateNormal];
    [self setThumbImage:image forState:UIControlStateSelected];
    [self setThumbImage:image forState:UIControlStateHighlighted];
}

#pragma - Private -

- (void)updateThumb
{
    if (self.touchIsCurrentlyHappening == NO) {
        UIImage *image = [self sliderImageWithText:self.formattedValue color:self.tintColor];
        [self setThumbImage:image];
    } else {
        [self setThumbImage:_simpleThumbImage];
    }
}

-(void)showPopupView:(BOOL)animated
{
    JCPopoverView *popupView = self.popupView;
    popupView.alpha = 0;
    [self addSubview:popupView];
    [UIView animateWithDuration:animated ? 0.3 : 0
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         popupView.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)hidePopupView:(BOOL)animated
{
    JCPopoverView *popupView = self.popupView;
    [UIView animateWithDuration:animated ? 0.3 : 0
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         popupView.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [popupView removeFromSuperview];
                     }];
}

-(void)positionAndUpdatePopupView
{
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect zeThumbRect = [self thumbRectForBounds:self.bounds trackRect:trackRect value:self.value];
    CGRect popupRect = CGRectOffset(zeThumbRect, -27, 0);
    self.popupView.frame = CGRectInset(popupRect, -10, -10);
    self.popupView.frame = CGRectMake(self.popupView.frame.origin.x, -69, self.popupView.bounds.size.width, self.popupView.bounds.size.height);
    self.popupView.textLabel.text = self.formattedValue;
}

#pragma mark - ThumbImages

-(UIImage *)sliderImageWithText:(NSString *)text color:(UIColor *)color
{
    NSString *key = [NSString stringWithFormat:@"%@-%@", text, color];
    UIImage *image = [_thumbImageCache objectForKey:key];
    if (image != nil) {
        return image;
    }
    
    CGSize size = CGSizeMake(35, 17);
    UIGraphicsBeginImageContextWithOptions(size, FALSE, [[UIScreen mainScreen]scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(size.height/2, size.height/2)];
    bezierPath.miterLimit = 4;
    [color setFill];
    [bezierPath fill];
    
    CGContextDrawPath(context, kCGPathFillStroke);
    [[UIColor whiteColor] set];
    UIFont *font = [UIFont boldSystemFontOfSize:10];
    NSMutableParagraphStyle *paragrapStyle = [[NSMutableParagraphStyle alloc] init];
    paragrapStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *att = @{
                          NSFontAttributeName : font,
                          NSForegroundColorAttributeName : [UIColor whiteColor],
                          NSParagraphStyleAttributeName : paragrapStyle };
    rect.origin.y = 2;
    [text drawInRect:rect withAttributes:att];
    
    // Get the image from the context
    UIImage *sliderImage = UIGraphicsGetImageFromCurrentImageContext();
    [sliderImage drawInRect:rect];
    UIGraphicsEndImageContext();
    
    [_thumbImageCache setObject:sliderImage forKey:key];

    return sliderImage;
}

-(UIImage *)thumbImageWithDiameter:(CGFloat)diameter color:(UIColor *)color borderColor:(UIColor *)borderColor borderWidth:(CGFloat)borderWidth
{
    CGFloat scale = 1.0;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        scale = [[UIScreen mainScreen] scale];
    
    diameter = diameter * scale;
    borderWidth = borderWidth * scale;
    
    CGSize size = CGSizeMake(diameter, diameter);
    CGContextRef context = JCGraphicsContextCreateWithSize(size);
    
    CGRect rect1 = CGRectMake(0, 0, size.width, size.height);
    CGRect rect = CGRectInset(rect1, 2 * borderWidth, 2 * borderWidth);
    CGContextAddEllipseInRect(context, rect);
    
    CGContextSetFillColor(context, CGColorGetComponents(color.CGColor));
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    CGContextSetFillColorWithColor(context, borderColor.CGColor);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    // convert the finished resized image to a UIImage
    CGImageRef newImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    UIImage *image = [[UIImage alloc] initWithCGImage:newImage scale:scale orientation:UIImageOrientationDownMirrored];
    CGImageRelease(newImage);
    return image;
}

CGContextRef JCGraphicsContextCreateWithSize(CGSize size)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL)
        return NULL;
    
    CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, size.width * 4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    return context;
}

@end

@implementation JCPopoverView

- (instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color
{
    UIView *backgroundImageView = [[UIImageView alloc] initWithImage:[self popoverImageWithColor:color]];
    CGRect bounds = backgroundImageView.bounds;
    self = [super initWithFrame:bounds];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:backgroundImageView];
        
        bounds.size.width -= 2;
        bounds.size.height = bounds.size.height / 1.4;
        _textLabel = [[UILabel alloc] initWithFrame:bounds];
        _textLabel.font = [UIFont boldSystemFontOfSize:22.0f];
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_textLabel];
    }
    return self;
}

-(UIImage *)popoverImageWithColor:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(100, 70), FALSE, [[UIScreen mainScreen]scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(88, 25)];
    [bezierPath addCurveToPoint: CGPointMake(68, 45) controlPoint1: CGPointMake(88, 36) controlPoint2: CGPointMake(79, 45)];
    [bezierPath addLineToPoint: CGPointMake(58.9, 45)];
    [bezierPath addLineToPoint: CGPointMake(47.8, 68.2)];
    [bezierPath addLineToPoint: CGPointMake(36.7, 45)];
    [bezierPath addLineToPoint: CGPointMake(28, 45)];
    [bezierPath addCurveToPoint: CGPointMake(8, 25) controlPoint1: CGPointMake(17, 45) controlPoint2: CGPointMake(8, 36)];
    [bezierPath addLineToPoint: CGPointMake(8, 25)];
    [bezierPath addCurveToPoint: CGPointMake(28, 5) controlPoint1: CGPointMake(8, 14) controlPoint2: CGPointMake(17, 5)];
    [bezierPath addLineToPoint: CGPointMake(68, 5)];
    [bezierPath addCurveToPoint: CGPointMake(88, 25) controlPoint1: CGPointMake(79, 5) controlPoint2: CGPointMake(88, 14)];
    [bezierPath addLineToPoint: CGPointMake(88, 25)];
    [bezierPath closePath];
    bezierPath.miterLimit = 4;
    
    [color setFill];
    [bezierPath fill];
    
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextDrawPath(context, kCGPathFillStroke);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
