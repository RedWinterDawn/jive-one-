//
//  JCCallCards.m
//  JiveOne
//
//  Created by Robert Barclay on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardListView.h"

#define CALL_CARD_MIN_CALL_HEIGHT 100
#define CALL_CARD_OFFSET 10

@implementation JCCallCardListView

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        _minCallCardHeight = CALL_CARD_MIN_CALL_HEIGHT;
        _callCardOffset = CALL_CARD_OFFSET;
    }
    return self;
}

/*-(void)layoutSubviews
{
    NSArray *subviews = self.subviews;
    CGRect bounds = self.bounds;
    
    CGFloat cardHeight = (subviews.count > 1)? MAX((bounds.size.height - _callCardOffset) / 2, _minCallCardHeight) : bounds.size.height;
    CGRect cardFrame = CGRectMake(0, 0, bounds.size.width, cardHeight);
    
    for (JCCallCardViewCell *callCardView in subviews)
    {
        callCardView.frame = cardFrame;
        cardFrame.origin.y += cardHeight + _callCardOffset;
    }
    
    if (cardFrame.origin.y > bounds.size.height)
    {
        self.scrollEnabled = true;
        self.contentSize = CGSizeMake(bounds.size.width, cardFrame.origin.y);
    }
    
    [super layoutSubviews];
}*/

/*-(void)addSubview:(UIView *)view
{
    if ([view isKindOfClass:[JCCallCardViewCell class]])
        [self addCallCard:(JCCallCardViewCell *)view];
}*/

-(void)addCallCard:(JCCallCardViewCell *)callCard
{
    /*[super addSubview:callCard];
    [self setNeedsLayout];*/
}

-(void)removeCallCard:(JCCallCardViewCell *)callCardView
{
    /*[UIView animateWithDuration:0.3
                     animations:^{
                         callCardView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [callCardView removeFromSuperview];
                         [self setNeedsLayout];
                     }];*/
}

/*-(NSUInteger)count
{
    //return self.subviews.count;
}*/


@end
