//
//  JCChatDetailViewController.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSMessagesViewController.h"

@interface JCConversationDetailViewController : UITableViewController <UIActionSheetDelegate>
@property (strong, nonatomic) NSString *conversationId;
- (IBAction)sendMessage:(id)sender;
- (void)loadDatasource;
@end
