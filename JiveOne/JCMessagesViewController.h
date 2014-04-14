//
//  JCMessagesViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSMessagesViewController.h"
#import <MBContactPicker/MBContactPicker.h>
#import "ContactGroup.h"

@interface JCMessagesViewController : JSMessagesViewController <JSMessagesViewDataSource, JSMessagesViewDelegate, UITableViewDataSource, MBContactPickerDelegate, MBContactPickerDataSource>

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableDictionary *avatars;

@property (nonatomic) ClientEntities *person;
@property (nonatomic) NSString *conversationId;
@property (nonatomic) ContactGroup *contactGroup;
@property (nonatomic) JCMessageType messageType;

+(void) sendOfflineMessagesQueue;

@end
