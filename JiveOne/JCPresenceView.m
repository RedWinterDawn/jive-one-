//
//  PresenceView.m
//  DrawingCellProperties
//
//  Created by Eduardo Gueiros on 3/11/14.
//  Copyright (c) 2014 Eduardo Gueiros. All rights reserved.
//

#import "JCPresenceView.h"
#import <QuartzCore/QuartzCore.h>

#define DEFAULT_AVAILABLE_COLOR         [UIColor colorWithRed:129.0/255.0 green:205.0/255.0 blue:0.0/255.0 alpha:1]
#define DEFAULT_AWAY_COLOR              [UIColor colorWithRed:233.0/255.0 green:195.0/255.0 blue:0.0/255.0 alpha:1]
#define DEFAULT_BUSY_COLOR              [UIColor colorWithRed:233.0/255.0 green:195.0/255.0 blue:0.0/255.0 alpha:1]
#define DEFAULT_DO_NOT_DISTURB_COLOR    [UIColor colorWithRed:233.0/255.0 green:0.0/255.0 blue:19.0/255.0 alpha:1]
#define DEFAULT_COLOR                   [UIColor colorWithRed:186.0/255.0 green:186.0/255.0 blue:186.0/255.0 alpha:1]

#define DEFAULT_LINE_WIDTH              3

#define DEFAULT_BASE_COLOR              [UIColor colorWithRed:0.42 green:0.49 blue:0.239 alpha:0.8]

@interface JCPresenceView ()
{
    CALayer *_presenceLayer;
}

@property (nonatomic, readonly) CALayer *presenceLayer;

@end


@implementation JCPresenceView

/**
 * Image Cache
 *
 * As images are created, the are added to the image cache. We have a static
 * mutable array that is shared by all instaces of the PresenceView. We use the
 * dispatch once to ensure that it is only ever instanced once.
 */
+ (NSMutableDictionary *)cachedPresenceImages {
    static NSMutableDictionary *cachedPresenceImages = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        cachedPresenceImages = [NSMutableDictionary new];
    });
    return cachedPresenceImages;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit_PresenceView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit_PresenceView];
    }
    return self;
}

/**
 * Draw the initial presence layer.
 *
 * This is called when the view is first added to its super view. By placing the
 * rebuildLayers method call in here, we ensure that when the view is drawn
 * after being added to subview the subview layer will have been drawn.
 */
- (void)willMoveToSuperview:(UIView *)newSuperview {
    if(newSuperview)
        [self rebuildLayers];
}

-(void)commonInit_PresenceView
{
    _presenceType = JCPresenceTypeNone;
    _lineWidth = DEFAULT_LINE_WIDTH;
    _baseColor = DEFAULT_BASE_COLOR;
}

#pragma mark - Setters -

-(void)setPresenceType:(JCPresenceType)presenceType
{
    _presenceType = presenceType;
    
    // If we have a superview, we need to rebuild the layers, and apply the new
    // presence type.
    if(self.superview)
        [self rebuildLayers];
}

#pragma mark - Getters -

- (CALayer *)presenceLayer
{
    if(!_presenceLayer) {
        _presenceLayer = [CALayer layer];
        
        CGSize viewSize = self.bounds.size;
        CGFloat width = MIN(viewSize.width, viewSize.height);
        _presenceLayer.bounds = CGRectMake(0, 0, width, width);
        _presenceLayer.position = CGPointMake(viewSize.width/2, viewSize.height/2);
        _presenceLayer.contentsScale = [UIScreen mainScreen].scale;
        _presenceLayer.contents = (id)[self presenceImageForType:_presenceType].CGImage;
    }
    return _presenceLayer;
}

#pragma mark - Private -

-(void)rebuildLayers
{
    [_presenceLayer removeFromSuperlayer];
    _presenceLayer = nil;
    
    [self.layer addSublayer:self.presenceLayer];
}

-(UIImage *)presenceImageForType:(JCPresenceType)type
{

    NSString *key = [NSString stringWithFormat:@"%i", type];
    UIImage *presenceImage = [[JCPresenceView cachedPresenceImages] objectForKey:key];
    if (!presenceImage)
    {
        NSLog(@"Creating new Image for PresenceView");
        CGSize viewSize = self.bounds.size;
        CGFloat width = MIN(viewSize.width, viewSize.height);
        
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, width), NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // Draw a bordered circle.
        
        width -= (_lineWidth * 2);
        CGRect frame = CGRectMake(_lineWidth, _lineWidth, width, width);
        
        CGContextSaveGState(context);
        //CGContextSetLineWidth(context, _lineWidth);
        UIColor *color = [self colorFromType:type];
        CGColorRef colorRef = CGColorCreateCopyWithAlpha(color.CGColor, 1.0);
        CGContextSetFillColorWithColor(context, colorRef);
        CFRelease(colorRef);
        CGContextSetStrokeColorWithColor(context, color.CGColor);
        CGContextFillEllipseInRect(context, frame);
        CGContextStrokeEllipseInRect(context, frame);
        CGContextRestoreGState(context);
        
        presenceImage = UIGraphicsGetImageFromCurrentImageContext();
        [[JCPresenceView cachedPresenceImages] setObject:presenceImage forKey:key];
        UIGraphicsEndImageContext();
    }
//    else{
//        NSLog(@"Cache Hit For Presence Image");
//    }
    return presenceImage;
}

-(UIColor *)colorFromType:(JCPresenceType)type
{
    switch (type) {
        case JCPresenceTypeAvailable:
            return DEFAULT_AVAILABLE_COLOR;
            
        case JCPresenceTypeAway:
            return DEFAULT_AWAY_COLOR;
            
        case JCPresenceTypeBusy:
            return DEFAULT_BUSY_COLOR;
            
        case JCPresenceTypeDoNotDisturb:
            return DEFAULT_DO_NOT_DISTURB_COLOR;
            
        default:
            return DEFAULT_COLOR;
    }
}

@end
