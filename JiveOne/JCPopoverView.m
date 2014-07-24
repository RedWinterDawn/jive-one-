//
//  JCPopoverView.m
//  JiveOne
//
//  Created by Doug on 5/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPopoverView.h"

@implementation JCPopoverView{
    UILabel *textLabel;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.font = [UIFont boldSystemFontOfSize:22.0f];
        UIView* pView = [self CreatePopup];
        [self addSubview:pView];

        textLabel = [[UILabel alloc] initWithFrame:CGRectMake(pView.frame.origin.x, pView.frame.origin.y, pView.frame.size.width-2, pView.frame.size.height/1.4)];
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.font = self.font;
        textLabel.textColor = [UIColor whiteColor];
        textLabel.text = self.text;
        textLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:textLabel];
    }
    return self;
}

-(void)setValue:(float)aValue {
    _value = aValue;
    
    self.text = [self formatSeconds:_value];
    textLabel.text = self.text;
    [self setNeedsDisplay];
}



-(UIImageView*)CreatePopup{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(100, 70), FALSE, [[UIScreen mainScreen]scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //// Color Declarations
    UIColor* color = [UIColor colorWithRed: 0.275 green: 0.396 blue: 0.843 alpha: 1];
    
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
    //get the image from the context
    UIImage *squareImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageView *popoverView = [[UIImageView alloc]initWithImage:squareImage];
    return popoverView;
}

/** Time formatting helper fn: N seconds => MM:SS */
-(NSString *)formatSeconds:(NSTimeInterval)seconds {
    NSInteger minutes = (NSInteger)(seconds/60.);
    NSInteger remainingSeconds = (NSInteger)seconds % 60;
    return [NSString stringWithFormat:@"%.1ld:%.2ld",(long)minutes,(long)remainingSeconds];
}
@end
