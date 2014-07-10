//
//  JCPersonCell.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCPresenceView.h"
#import "Lines+Custom.h"

@class JCPersonCell;

@protocol JCPersonCellDelegate <NSObject>
-(void)updateTableViewCell:(JCPersonCell*)cell;
@end

@interface JCPersonCell : UITableViewCell

@property (weak,nonatomic) id<JCPersonCellDelegate> delegate;


@property (weak, nonatomic) IBOutlet UILabel *personNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *personDetailLabel;
@property (strong, nonatomic) IBOutlet UIButton *favoriteBut;
@property (weak, nonatomic) IBOutlet UIImageView *personPicture;
@property (weak, nonatomic) IBOutlet JCPresenceView *personPresenceView;
@property (nonatomic) PersonEntities *person;
@property (nonatomic) Lines *line;
@end

