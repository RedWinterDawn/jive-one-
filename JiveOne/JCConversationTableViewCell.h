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
@property (weak, nonatomic) IBOutlet UIImageView *conversationImage;
@property (weak, nonatomic) IBOutlet JCPresenceView *presenceView;

@property (nonatomic) Conversation *conversation;
@property (nonatomic) ClientEntities *person;

@end
