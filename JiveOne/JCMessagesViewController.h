//
//  JCMessagesViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSMessagesViewController.h"
#import "MBContactPicker/MBContactPicker.h"
#import "JCConversationParticipantsTableViewController.h"
#import "JCDirectoryViewController.h"
#import "ContactGroup.h"
#import "JCOsgiClient.h"

@interface JCMessagesViewController : JSMessagesViewController <JSMessagesViewDataSource, JSMessagesViewDelegate, UITableViewDataSource, MBContactPickerDelegate, MBContactPickerDataSource, PeopleSearchDelegate, ConversationParticipantDelegate>

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableDictionary *avatars;

@property (nonatomic) PersonEntities *person;
@property (nonatomic) NSString *conversationId;
@property (nonatomic) ContactGroup *contactGroup;
@property (nonatomic) JCMessageType messageType;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewNewMessage;


+(void) sendOfflineMessagesQueue:(JCOsgiClient*)osgiClient;

@end
