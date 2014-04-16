//
//  JCGroupConvoTableViewCell.h
//  JiveOne
//
//  Created by Doug Leonard on 4/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Conversation+Custom.h"

@interface JCGroupConversationCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *conversationTitle;
@property (strong, nonatomic) IBOutlet UILabel *conversationTime;
@property (strong, nonatomic) IBOutlet UIView *conversationThumbnailView;
@property (strong, nonatomic) IBOutlet UILabel *conversationUnseenMessages;
@property (strong, nonatomic) IBOutlet UILabel *conversationSnippet;

@property (nonatomic) Conversation *conversation;
@property (nonatomic) ClientEntities *person;

@end
