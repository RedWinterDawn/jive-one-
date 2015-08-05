//
//  JCConversationTableViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 2/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCTableViewCell.h"

@protocol JCConversationTableViewCellDelegate;

@interface JCConversationTableViewCell : JCTableViewCell

@property (weak, nonatomic) id<JCConversationTableViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *detail;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UIView *unreadCircle;


@property (nonatomic, getter=isRead) BOOL read;
@end

@protocol JCConversationTableViewCellDelegate <NSObject>

-(void)didBlockConverastionTableViewCell:(JCConversationTableViewCell *)cell;
@end