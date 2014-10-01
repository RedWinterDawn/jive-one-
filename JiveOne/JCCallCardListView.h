//
//  JCCallCards.h
//  JiveOne
//
//  Created by Robert Barclay on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCCallCardViewCell.h"

@interface JCCallCardListView : UICollectionView

@property (nonatomic, readonly) NSUInteger count;

@property (nonatomic) NSInteger minCallCardHeight;
@property (nonatomic) NSInteger callCardOffset;

-(void)addCallCard:(JCCallCardViewCell *)callCard;
-(void)removeCallCard:(JCCallCardViewCell *)callCard;

-(JCCallCardViewCell *)findCallCardByIdentifier:(NSString *)identifier;
-(JCCallCardViewCell *)removeCallCardByIdentifier:(NSString *)identifier;

@end
