//
//  JCConversationParticipantsTableViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 5/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Conversation+Custom.h"
#import "JCDirectoryViewController.h"

@class JCConversationParticipantsTableViewController;
@protocol ConversationParticipantDelegate <NSObject>

- (void) didAddPersonFromParticipantView:(PersonEntities *)person;

@end


@interface JCConversationParticipantsTableViewController : UITableViewController 

@property (nonatomic, assign) id<ConversationParticipantDelegate> delegate;
@property (nonatomic, strong) NSArray *entitiesArray;
@property (nonatomic, strong) Conversation *conversation;

@end
