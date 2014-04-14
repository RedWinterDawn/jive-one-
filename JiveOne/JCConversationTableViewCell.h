//
//  JCConversationTableViewCell.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Conversation+Custom.h"
#import "JCPresenceView.h"

@interface JCConversationTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *conversationTitle;
@property (weak, nonatomic) IBOutlet UILabel *conversationSnippet;
@property (weak, nonatomic) IBOutlet UILabel *conversationTime;
@property (weak, nonatomic) IBOutlet UIView *conversationThumbnailView;
@property (weak, nonatomic) IBOutlet UILabel *conversationUnseenMessages;
@property (weak, nonatomic) IBOutlet JCPresenceView *presenceView;

@property (nonatomic) Conversation *conversation;
@property (nonatomic) ClientEntities *person;

#pragma mark - Cell UI Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *presenceWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *presenceSpacing;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleWidth;

@end
