//
//  JCPopoverSlider.m
//  JiveOne
//
//  Created by Doug on 5/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPopoverSlider.h"
@interface JCPopoverSlider()
@property (strong,nonatomic) UIImage* sliderImage;
@property (nonatomic, strong) NSString *sliderText;
@property (nonatomic, strong) UIFont *sliderFont;
@property (strong, nonatomic) UILabel *sliderTextLabel;


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

#pragma mark - Helper methods
-(void)constructSlider {
    [self addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.continuous = YES;
    _popupView = [[JCPopoverView alloc] initWithFrame:CGRectZero];
    _popupView.backgroundColor = [UIColor clearColor];
    _popupView.alpha = 0.0;
    [self addSubview:_popupView];
    [[JCPopoverSlider appearance] setThumbImage:self.sliderImage forState:UIControlStateNormal];
    [self addSubview: self.sliderTextLabel];
    
    
}

-(UIImage*)sliderImage
{
    if (!_sliderImage) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(32, 20), FALSE, [[UIScreen mainScreen]scale]);
        CGContextRef context = UIGraphicsGetCurrentContext();
        //// Color Declarations
//        UIColor* color = [UIColor colorWithRed: 0.275 green: 0.396 blue: 0.843 alpha: 1];
        UIColor* color = [UIColor clearColor];
        //// Rectangle Drawing
        CGRect rect = CGRectMake(0, 0, 32, 20);
        CGContextAddRect(context, rect);
        
        CGContextSetStrokeColorWithColor(context, color.CGColor);
        
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextDrawPath(context, kCGPathFillStroke);
//        UIFont *font = [UIFont boldSystemFontOfSize:10];

//        [[UIColor whiteColor] set];
//        [[self formatSeconds:self.value] drawInRect:CGRectIntegral(CGRectMake(3, 3, rect.size.width, rect.size.height)) withFont:font];
        //get the image from the context
        _sliderImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        
    }
    return _sliderImage;
}
- (void)updateSliderImage
{

}
- (IBAction)sliderValueChanged:(UISlider *)sender {
    NSLog(@"slider value = %f", sender.value);
    [self positionAndUpdateSlider];
}

-(UIImageView*)sliderView{
    if (!_sliderView) {
        _sliderView = [[UIImageView alloc]initWithImage:_sliderImage];
    }
    return _sliderView;
}

-(UILabel*)sliderTextLabel{
    if (!_sliderTextLabel) {
        _sliderTextLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,-6,self.sliderImage.size.width, self.sliderImage.size.width)];
//        CGRectMake(self.thumbRect.origin.x, self.thumbRect.origin.y, self.sliderImage.size.width, self.sliderImage.size.width)
        _sliderTextLabel.text = [self formatSeconds:self.value];
        _sliderTextLabel.font = [UIFont systemFontOfSize:10];
        [_sliderTextLabel setNeedsDisplay];
    }
    return _sliderTextLabel;
}

//The default initWithFrame: method is not invoked when creating an object from a .xib file. Instead, it is this method that is invoked - initWithCoder:.
-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self constructSlider];
    }
    return self;
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

-(void)positionAndUpdateSlider
{
    _sliderTextLabel.frame = self.thumbRect;
    
//    _sliderTextLabel.text = [self formatSeconds:self.value];
    self.sliderText = [self formatSeconds:self.value];
    self.sliderTextLabel.text = self.sliderText;
    [self.sliderTextLabel setNeedsDisplay];
}
-(void)positionAndUpdatePopupView {
    CGRect zeThumbRect = self.thumbRect;
    CGRect popupRect = CGRectOffset(zeThumbRect, -(zeThumbRect.size.width/2), -floor(zeThumbRect.size.height * 1.4));
    _popupView.frame = CGRectInset(popupRect, -20, -10);
    _popupView.value = self.value;
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


#pragma mark - UIControl touch event tracking
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
