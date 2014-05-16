//
//  JCPopoverSlider.m
//  JiveOne
//
//  Created by Doug on 5/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPopoverSlider.h"
@interface JCPopoverSlider()

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

    [[JCPopoverSlider appearance] setThumbImage: sliderImage([self formatSeconds:self.value]) forState:UIControlStateNormal];
    [[JCPopoverSlider appearance] setThumbImage: justASliderBox() forState:UIControlStateHighlighted];
    
    // Create the callbacks for touch, move, and release
    [self addTarget:self action:@selector(startDrag:) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(updateThumb) forControlEvents:UIControlEventValueChanged];
    [self addTarget:self action:@selector(endDrag:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
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

- (void)updateThumb{
//    NSLog(@"slider value = %f", sender.value);
//    UIImage *customimg = sliderImage([self formatSeconds:self.value]);
    UIImage *customimg = justASliderBox();

	[self setThumbImage: customimg forState: UIControlStateHighlighted];
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
    CGRect popupRect = CGRectOffset(zeThumbRect, -35, -floor(zeThumbRect.size.height * 2.8));
    self.popupView.frame = CGRectInset(popupRect, -10, -10);
    self.popupView.value = self.value;
}

/** Time formatting helper fn: N seconds => MM:SS */
-(NSString *)formatSeconds:(NSTimeInterval)seconds {
    NSInteger minutes = (NSInteger)(seconds/60.);
    NSInteger remainingSeconds = (NSInteger)seconds % 60;
    return [NSString stringWithFormat:@"%.2ld:%.2ld",(long)minutes,(long)remainingSeconds];
}

#pragma mark - Property accessors
-(CGRect)thumbRect {
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbR = [self thumbRectForBounds:self.bounds trackRect:trackRect value:self.value];
    return thumbR;
}

#pragma mark - ThumbImages
UIImage *sliderImage(NSString* text)
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(32, 15), FALSE, [[UIScreen mainScreen]scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //// Color Declarations
    UIColor* color = [UIColor colorWithRed: 0.275 green: 0.396 blue: 0.843 alpha: 1];
    //// Rectangle Drawing
    CGRect rect = CGRectMake(0, 2, 32, 15);
    CGContextAddRect(context, rect);
    
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    
    CGContextSetFillColorWithColor(context, color.CGColor);
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
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(15, 15), FALSE, [[UIScreen mainScreen]scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //// Color Declarations
    UIColor* color = [UIColor colorWithRed: 0.275 green: 0.396 blue: 0.843 alpha: 1];
    //// Rectangle Drawing
    CGRect rect = CGRectMake(0, 0, 15, 15);
    CGContextAddRect(context, rect);
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
// Expand the slider to accommodate the bigger thumb
- (void)startDrag:(UISlider *)aSlider
{
//	self.frame = CGRectInset(self.frame, 0.0f, -30.0f);
}

// At release, shrink the frame back to normal
- (void)endDrag:(UISlider *)aSlider
{
//    self.frame = CGRectInset(self.frame, 0.0f, 30.0f);
}

-(BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    // Fade in and update the popup view
    CGPoint touchPoint = [touch locationInView:self];
    
    // Check if the knob is touched. If so, show the popup view
    if(CGRectContainsPoint(CGRectInset(self.thumbRect, -12.0, -12.0), touchPoint)) {
        [self positionAndUpdatePopupView];
        [self fadePopupViewInAndOut:YES];
    }
    
    return [super beginTrackingWithTouch:touch withEvent:event];
}

-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    // Update the popup view as slider knob is being moved
    [self positionAndUpdatePopupView];
    return [super continueTrackingWithTouch:touch withEvent:event];
}

-(void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
}

-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    // Fade out the popup view
    [self fadePopupViewInAndOut:NO];
    [super endTrackingWithTouch:touch withEvent:event];
}

@end
