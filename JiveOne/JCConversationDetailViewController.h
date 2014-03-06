//
//  JCChatDetailViewController.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THContactPickerView.h"

@interface JCConversationDetailViewController : UITableViewController <UIActionSheetDelegate, UITextViewDelegate, THContactPickerDelegate>

@property (nonatomic, strong) THContactPickerView *contactPickerView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSMutableArray *selectedContacts;
@property (nonatomic, strong) NSArray *filteredContacts;
@property (nonatomic, strong) NSString *conversationId;

- (IBAction)sendMessage:(id)sender;
- (void)loadDatasource;
@end
