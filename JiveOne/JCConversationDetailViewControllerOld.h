//
//  JCChatDetailViewController.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THContactPickerView.h"
#import "ContactGroup.h"

@interface JCConversationDetailViewControllerOld : UIViewController <UIActionSheetDelegate, UITextViewDelegate, THContactPickerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) THContactPickerView *contactPickerView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSMutableArray *selectedContacts;
@property (nonatomic, strong) NSArray *filteredContacts;
@property (nonatomic, strong) NSString *conversationId;
@property (nonatomic, strong) ContactGroup *contactGroup;
@property (nonatomic, strong) ClientEntities *person;

- (IBAction)sendMessage:(id)sender;
@end
