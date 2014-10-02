//
//  JCCallCards.h
//  JiveOne
//
//  Created by Robert Barclay on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCCallCardView.h"

@interface JCCallCardListView : UIScrollView

@property (nonatomic, readonly) NSUInteger count;

@property (nonatomic) NSInteger minCallCardHeight;
@property (nonatomic) NSInteger callCardOffset;

-(void)addCallCard:(JCCallCardView *)callCard;
-(void)removeCallCard:(JCCallCardView *)callCard;

-(JCCallCardView *)findCallCardByIdentifier:(NSString *)identifier;
-(JCCallCardView *)removeCallCardByIdentifier:(NSString *)identifier;

@end
