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
        self.font = [UIFont boldSystemFontOfSize:15.0f];
        [self CreatePopup];
        UIView* pView = [self CreatePopup];
        [self addSubview:pView];

        textLabel = [[UILabel alloc] init];
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.font = self.font;
        textLabel.textColor = [UIColor colorWithWhite:1.0f alpha:0.7];
        textLabel.text = self.text;
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.frame = CGRectMake(pView.frame.origin.x, pView.frame.origin.y, pView.frame.size.width, pView.frame.size.height/1.5);
        [self addSubview:textLabel];
        [[UIApplication sharedApplication].keyWindow bringSubviewToFront:pView];
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
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(100, 60), FALSE, [[UIScreen mainScreen]scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //// Color Declarations
    UIColor* color = [UIColor colorWithRed: 0.275 green: 0.396 blue: 0.843 alpha: 1];

    //// Rectangle Drawing
    CGContextMoveToPoint(context, 20, 35.14);
    CGContextAddLineToPoint(context,20, 5);
    CGContextAddLineToPoint(context,85, 5);
    CGContextAddLineToPoint(context,85, 35.14);
    CGContextAddLineToPoint(context,60.75, 35.14);
    CGContextAddLineToPoint(context,52.5, 50);
    CGContextAddLineToPoint(context,44.25, 35.14);
    CGContextAddLineToPoint(context,20, 35.14);
    CGContextClosePath(context);

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
    return [NSString stringWithFormat:@"%.2ld:%.2ld",(long)minutes,(long)remainingSeconds];
}
@end
