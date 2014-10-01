//
//  JCCallCards.m
//  JiveOne
//
//  Created by Robert Barclay on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardListView.h"

#define CALL_CARD_MIN_CALL_HEIGHT 200
#define CALL_CARD_OFFSET 10

@implementation JCCallCardListView

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        _minCallCardHeight = CALL_CARD_MIN_CALL_HEIGHT;
        _callCardOffset = CALL_CARD_OFFSET;
        
        self.scrollEnabled = false;
    }
    return self;
}

-(void)layoutSubviews
{
    NSArray *subviews = self.subviews;
    CGRect bounds = self.bounds;
    
    CGFloat cardHeight = MAX((bounds.size.height - _callCardOffset) / 2, _minCallCardHeight);
    if (cardHeight == _minCallCardHeight)
        self.scrollEnabled = true;
    
    CGRect cardFrame = CGRectMake(0, 0, bounds.size.width, cardHeight);
    
    for (JCCallCardView *callCardView in subviews)
    {
        callCardView.frame = cardFrame;
        cardFrame.origin.y += cardHeight + _callCardOffset;
    }
    
    [super layoutSubviews];
}

-(void)addSubview:(UIView *)view
{
    if ([view isKindOfClass:[JCCallCardView class]])
        [self addCallCard:(JCCallCardView *)view];
}

-(void)addCallCard:(JCCallCardView *)callCard
{
    [super addSubview:callCard];
    [self setNeedsLayout];
}

-(void)removeCallCard:(JCCallCardView *)callCard
{
    [callCard removeFromSuperview];
    [self setNeedsLayout];
}

-(NSUInteger)count
{
    return self.subviews.count;
}


@end
