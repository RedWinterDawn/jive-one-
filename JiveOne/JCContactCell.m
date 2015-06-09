//
//  JCContactCell.m
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCContactCell.h"

@implementation JCContactCell

NSString *const kJCContactCellFavoriteButtonText = @"★";

-(void)awakeFromNib
{
    //selected star should be yellow unselected star should be gray
    UIColor *selectedStarColor = [UIColor colorWithRed:255.0/255.0 green:212.0/255.0 blue:0.0/255.0 alpha:1.0];
    NSMutableAttributedString *selectedAttributedStarSelectedState = [[NSMutableAttributedString alloc]initWithString:kJCContactCellFavoriteButtonText attributes:@{NSForegroundColorAttributeName : selectedStarColor}];
    UIColor *unselectedStarColor = [UIColor colorWithRed:208.0/255.0 green:208.0/255.0 blue:208.0/255.0 alpha:1.0];
    
    NSMutableAttributedString *unselectedAttributedStarSelectedState = [[NSMutableAttributedString alloc]initWithString:kJCContactCellFavoriteButtonText attributes:@{NSForegroundColorAttributeName : unselectedStarColor}];
    [self.favoriteBtn setAttributedTitle:selectedAttributedStarSelectedState forState:UIControlStateSelected];
    [self.favoriteBtn setAttributedTitle:unselectedAttributedStarSelectedState forState:UIControlStateNormal];
}

#pragma mark - Properties -

-(void)setFavorite:(BOOL)favorite
{
    self.favoriteBtn.selected = favorite;
}

-(BOOL)isFavorite
{
    return self.favoriteBtn.selected;
}

#pragma mark - IBActions -

- (IBAction)toggleFavoriteStatus:(id)sender {
    self.favorite = !self.isFavorite;
    [_delegate contactCell:self didMarkAsFavorite:self.isFavorite];
}

@end
