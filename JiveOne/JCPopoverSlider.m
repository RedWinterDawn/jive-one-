//
//  JCPopoverSlider.m
//  JiveOne
//
//  Created by Doug on 5/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPopoverSlider.h"
@interface JCPopoverSlider()
@property (strong, nonatomic) UIColor* JCBlue;
@property (atomic) BOOL touchIsCurrentlyHappening;
@end

@implementation JCPopoverSlider

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self constructSlider];
    }
    return self;
}

//The default initWithFrame: method is not invoked when creating an object from a .xib file. Instead, it is this method that is invoked - initWithCoder:.
-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self constructSlider];
    }
    return self;
}

#pragma mark - Helper methods
-(void)constructSlider {
    self.continuous = YES;
    UIImage *minImage = [[UIImage imageNamed:@"slider_maximum.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 5)];
    UIImage *maxImage = [[UIImage imageNamed:@"slider_min.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 5)];
    [[JCPopoverSlider appearance] setMaximumTrackImage:maxImage forState:UIControlStateNormal];
    [[JCPopoverSlider appearance] setMinimumTrackImage:minImage forState:UIControlStateNormal];
    [self addTarget:self action:@selector(updateThumb) forControlEvents:UIControlEventValueChanged];

    self.touchIsCurrentlyHappening = NO;
    [self changeThumbImageToDisplayProgressThumb];
}

-(JCPopoverView*)popupView
{
    if (!_popupView) {
        _popupView = [[JCPopoverView alloc] initWithFrame:CGRectZero];
        _popupView.backgroundColor = [UIColor clearColor];
        _popupView.alpha = 0.0;
        [self addSubview:_popupView];
    }
    return _popupView;
}
-(void)changeThumbImageToSimpleThumb
{
    if (self.touchIsCurrentlyHappening) {
        [self setThumbImage: justASliderBox() forState:UIControlStateNormal];
        [self setThumbImage: justASliderBox() forState:UIControlStateSelected];
        [self setThumbImage: justASliderBox() forState:UIControlStateHighlighted];
    }
}
- (void)updateThumb{
    //    NSLog(@"slider value = %f", sender.value);
    //    UIImage *customimg = sliderImage([self formatSeconds:self.value]);
    
        UIImage *customimg = justASliderBox();
 	[self setThumbImage: customimg forState: UIControlStateHighlighted];
}

- (void)updateThumbWithCurrentProgress{
    UIImage *customimg = sliderImage([self formatSeconds:self.value]);
 	[self setThumbImage: customimg forState: UIControlStateNormal];
}


-(void)changeThumbImageToDisplayProgressThumb
{
    if (self.touchIsCurrentlyHappening == NO) {
        [self setThumbImage: sliderImage([self formatSeconds:self.value]) forState:UIControlStateNormal];
        [self setThumbImage: sliderImage([self formatSeconds:self.value]) forState:UIControlStateSelected];
        [self setThumbImage: sliderImage([self formatSeconds:self.value]) forState:UIControlStateHighlighted];
    }
}

-(void)fadePopupViewInAndOut:(BOOL)aFadeIn {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    if (aFadeIn) {
        _popupView.alpha = 1.0;
    } else {
        _popupView.alpha = 0.0;
    }
    [UIView commitAnimations];
}

-(void)positionAndUpdatePopupView {

    CGRect zeThumbRect = self.thumbRect;
//    NSLog(@"popupView: %f,%f, %f,%f", self.popupView.frame.origin.x, self.popupView.frame.origin.y, self.popupView.bounds.size.width, self.popupView.bounds.size.height);

    CGRect popupRect = CGRectOffset(zeThumbRect, -27, -floor(zeThumbRect.size.height * 3));
    self.popupView.frame = CGRectInset(popupRect, -10, -10);
    if (self.popupView.frame.origin.y > -79) {
        self.popupView.frame = CGRectMake(self.popupView.frame.origin.x, -79, self.popupView.bounds.size.width, self.popupView.bounds.size.height);
    }
    self.popupView.value = self.value;
}

/** Time formatting helper fn: N seconds => M:SS */
-(NSString *)formatSeconds:(NSTimeInterval)seconds {
    NSInteger minutes = (NSInteger)(seconds/60.);
    NSInteger remainingSeconds = (NSInteger)seconds % 60;
    return [NSString stringWithFormat:@"%.1ld:%.2ld",(long)minutes,(long)remainingSeconds];
}

- (CGRect)trackRectForBounds:(CGRect)bounds{
    return CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, 3);
}

#pragma mark - Property accessors
-(CGRect)thumbRect {
//    NSLog(@"bounds: %f,%f", self.bounds.origin.x, self.bounds.origin.y);

    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbR = [self thumbRectForBounds:self.bounds trackRect:trackRect value:self.value];
    if (thumbR.origin.y > -9) {
        thumbR = CGRectMake(thumbR.origin.x, -9, thumbR.size.width, thumbR.size.height);
    }
    
    return thumbR;
    
}

-(UIColor*)JCBlue{
    if (!_JCBlue) {
        _JCBlue = [UIColor colorWithRed: 0.275 green: 0.396 blue: 0.843 alpha: 1];
    }
    return _JCBlue;
}

#pragma mark - ThumbImages
UIImage* sliderImage(NSString* text)
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(35, 17), FALSE, [[UIScreen mainScreen]scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //// Color Declarations
    UIColor* color = [UIColor colorWithRed: 0.275 green: 0.396 blue: 0.843 alpha: 1];
    //// Rectangle Drawing
    CGRect rect = CGRectMake(0, 2, 35, 17);

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(35, 8.5)];
    [bezierPath addCurveToPoint: CGPointMake(26.25, 17) controlPoint1: CGPointMake(35, 13.17) controlPoint2: CGPointMake(31.06, 17)];
    [bezierPath addLineToPoint: CGPointMake(22.27, 17)];
    [bezierPath addLineToPoint: CGPointMake(12.56, 17)];
    [bezierPath addLineToPoint: CGPointMake(8.75, 17)];
    [bezierPath addCurveToPoint: CGPointMake(0, 8.5) controlPoint1: CGPointMake(3.94, 17) controlPoint2: CGPointMake(0, 13.17)];
    [bezierPath addLineToPoint: CGPointMake(0, 8.5)];
    [bezierPath addCurveToPoint: CGPointMake(8.75, 0) controlPoint1: CGPointMake(0, 3.83) controlPoint2: CGPointMake(3.94, 0)];
    [bezierPath addLineToPoint: CGPointMake(26.25, 0)];
    [bezierPath addCurveToPoint: CGPointMake(35, 8.5) controlPoint1: CGPointMake(31.06, 0) controlPoint2: CGPointMake(35, 3.83)];
    [bezierPath addLineToPoint: CGPointMake(35, 8.5)];
    [bezierPath closePath];
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
                          NSParagraphStyleAttributeName : paragrapStyle
                          };
    [text drawInRect:rect withAttributes:att];
    //get the image from the context
    UIImage* sliderImage = UIGraphicsGetImageFromCurrentImageContext();
    [sliderImage drawInRect:rect];
    UIGraphicsEndImageContext();

    return sliderImage;
}

UIImage *justASliderBox()
{
    const int circleDiameter = 20;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(circleDiameter, circleDiameter), FALSE, [[UIScreen mainScreen]scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //// Color Declarations
    UIColor* color = [UIColor colorWithRed: 0.275 green: 0.396 blue: 0.843 alpha: 1];
    //// Rectangle Drawing
    CGRect rect1 = CGRectMake(0, 0, circleDiameter, circleDiameter);
    CGRect rect = CGRectInset(rect1, 2, 2);
//    CGContextAddRect(context, rect);
    CGContextAddEllipseInRect(context, rect);
    CGContextSetFillColor(context, CGColorGetComponents([[UIColor blueColor] CGColor]));
    
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    //get the image from the context
    UIImage* sliderImage = UIGraphicsGetImageFromCurrentImageContext();
    [sliderImage drawInRect:rect];
    UIGraphicsEndImageContext();
    
    return sliderImage;
}

#pragma mark - UIControl touch event tracking

-(BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super beginTrackingWithTouch:touch withEvent:event];
    
    self.touchIsCurrentlyHappening = YES;
    [self changeThumbImageToSimpleThumb];

    [self positionAndUpdatePopupView];
    [self fadePopupViewInAndOut:YES];
    
    return YES;
}

-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (self.touchIsCurrentlyHappening == NO) {
        self.touchIsCurrentlyHappening = YES;
        [self changeThumbImageToSimpleThumb];
    }
    
    [super continueTrackingWithTouch:touch withEvent:event];
    // Update the popup view as slider knob is being moved
    [self positionAndUpdatePopupView];
    return YES;
}

-(void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
    self.touchIsCurrentlyHappening = NO;
    [self changeThumbImageToDisplayProgressThumb];

}

-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    // Fade out the popup view
    self.touchIsCurrentlyHappening = NO;
    [self changeThumbImageToDisplayProgressThumb];
    [self fadePopupViewInAndOut:NO];
    [super endTrackingWithTouch:touch withEvent:event];
}

@end
