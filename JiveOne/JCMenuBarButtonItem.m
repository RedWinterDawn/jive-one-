//
//  JCMenuBarButtonItem.m
//
//  Created by Robert Barclay on 10/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCMenuBarButtonItem.h"

@implementation JCMenuBarButtonItem

-(id)initWithTarget:(id)target action:(SEL)action
{
    return [self initWithImage:[self.class drawerButtonItemImage]
                         style:UIBarButtonItemStylePlain
                        target:target
                        action:action];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    // non-ideal way to get the target/action, but it works
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCoder: aDecoder];
    return [self initWithTarget:barButtonItem.target action:barButtonItem.action];
}

+(UIImage *)drawerButtonItemImage
{
    static UIImage *drawerButtonImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        UIGraphicsBeginImageContextWithOptions( CGSizeMake(26, 26), NO, 0 );
        
        CGFloat width = 2;
        
        //// Color Declarations
        UIColor *fillColor = [UIColor whiteColor];
        
        //// Frames
        CGRect frame = CGRectMake(0, 0, 26, 26);
        
        //// Bottom Bar Drawing
        UIBezierPath *bottomBarPath = [UIBezierPath bezierPathWithRect: CGRectMake(CGRectGetMinX(frame) + floor((CGRectGetWidth(frame) - 16) * 0.50000 + 0.5), CGRectGetMinY(frame) + floor((CGRectGetHeight(frame) - 1) * 0.68000 + 0.5), 16, width)];
        [fillColor setFill];
        [bottomBarPath fill];
        
        //// Middle Bar Drawing
        UIBezierPath *middleBarPath = [UIBezierPath bezierPathWithRect: CGRectMake(CGRectGetMinX(frame) + floor((CGRectGetWidth(frame) - 16) * 0.50000 + 0.5), CGRectGetMinY(frame) + floor((CGRectGetHeight(frame) - 1) * 0.48000 + 0.5), 16, width)];
        [fillColor setFill];
        [middleBarPath fill];
        
        //// Top Bar Drawing
        UIBezierPath *topBarPath = [UIBezierPath bezierPathWithRect: CGRectMake(CGRectGetMinX(frame) + floor((CGRectGetWidth(frame) - 16) * 0.50000 + 0.5), CGRectGetMinY(frame) + floor((CGRectGetHeight(frame) - 1) * 0.28000 + 0.5), 16, width)];
        [fillColor setFill];
        [topBarPath fill];
        
        drawerButtonImage = UIGraphicsGetImageFromCurrentImageContext();
    });
    
    return drawerButtonImage;
}


@end
