//
//  JCContactCell.m
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCContactCell.h"

@implementation JCContactCell

NSString *const kJCContactCellFavoritButtonText = @"★";

-(void)awakeFromNib
{
    //selected star should be yellow unselected star should be gray
    UIColor *selectedStarColor = [UIColor colorWithRed:255.0/255.0 green:212.0/255.0 blue:0.0/255.0 alpha:1.0];
    NSMutableAttributedString *selectedAttributedStarSelectedState = [[NSMutableAttributedString alloc]initWithString:kJCContactCellFavoritButtonText attributes:@{NSForegroundColorAttributeName : selectedStarColor}];
    UIColor *unselectedStarColor = [UIColor colorWithRed:208.0/255.0 green:208.0/255.0 blue:208.0/255.0 alpha:1.0];
    
    NSMutableAttributedString *unselectedAttributedStarSelectedState = [[NSMutableAttributedString alloc]initWithString:kJCContactCellFavoritButtonText attributes:@{NSForegroundColorAttributeName : unselectedStarColor}];
    [self.favoriteBtn setAttributedTitle:selectedAttributedStarSelectedState forState:UIControlStateSelected];
    [self.favoriteBtn setAttributedTitle:unselectedAttributedStarSelectedState forState:UIControlStateNormal];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.favoriteBtn.selected = self.contact.isFavorite;
}

#pragma mark - Setters -

-(void)setContact:(Contact *)contact
{
    _contact = contact;
    self.person = contact;
}

#pragma mark - IBActions -

- (IBAction)toggleFavoriteStatus:(id)sender {
    
    self.contact.favorite = !self.contact.isFavorite;
    [self.contact.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [self setNeedsLayout];
    }];
}

@end
