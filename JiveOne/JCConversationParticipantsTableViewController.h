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

@interface JCConversationParticipantsTableViewController : UITableViewController <PeopleSearchDelegate>

@property (nonatomic, strong) NSArray *entitiesArray;
@property (nonatomic, strong) Conversation *conversation;

@end
