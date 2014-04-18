//
//  JCPeopleDetailCell.h
//  JiveOne
//
//  Created by Doug Leonard on 4/7/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCPresenceView.h"

@class JCPeopleDetailCell;


@protocol JCPeopleDetailCellDelegate <NSObject>
-(void)toggleIsFavorite:(JCPeopleDetailCell *)cell;
@end


@interface JCPeopleDetailCell : UITableViewCell <JCPeopleDetailCellDelegate>

@property (strong, nonatomic) IBOutlet UILabel *NameLabel;
@property (strong, nonatomic) IBOutlet JCPresenceView *presenceView;
@property (nonatomic) PersonEntities *person;
@property (strong, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak,nonatomic) id<JCPeopleDetailCellDelegate> delegate;

- (IBAction)toggleIsFavorite:(id)sender;

@end
