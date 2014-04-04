//
//  JCMessagesViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCMessagesViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "Conversation+Custom.h"
#import "ConversationEntry+Custom.h"
#import "JCOsgiClient.h"
#import "ClientEntities.h"
#import "JCContactModel.h"
#import "JSMessage.h"
#import "Common.h"

@interface JCMessagesViewController ()
{
    ClientEntities *me;
}

@property (nonatomic) NSArray *contacts;
@property (nonatomic) NSMutableArray *selectedContacts;
@property (weak, nonatomic) IBOutlet MBContactPicker *contactPickerView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contactPickerViewHeightConstraint;

@end

@implementation JCMessagesViewController

#pragma mark - Message Type Setters
- (void)setMessageType:(JCMessageType)messageType
{
    _messageType = messageType;
}

- (void)setPerson:(ClientEntities *)person
{
    if (person && [person isKindOfClass:[ClientEntities class]]) {
        _person = person;
    }
}

- (void)setConversation:(NSString *)conversationId
{
    if (conversationId && [conversationId isKindOfClass:[NSString class]]) {
        _conversationId = conversationId;
    }
}

- (void)setContactGroup:(ContactGroup *)contactGroup
{
    if (contactGroup && [contactGroup isKindOfClass:[ContactGroup class]]) {
        _contactGroup = contactGroup;
    }
}

#pragma mark - UIViewControler life cycle

- (void)viewDidLoad
{
    self.delegate = self;
    self.dataSource = self;
    [super viewDidLoad];
    
    me = [[JCOmniPresence sharedInstance] me];
    
    [self setupDataSources];
    
    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:16.0f]];
    
    self.title = @"Messages";
    self.messageInputView.textView.placeHolder = @"New Message";
    self.sender = [[JCOmniPresence sharedInstance] me].firstLastName;
    
    self.contactPickerView.delegate = self;
    self.contactPickerView.datasource = self;
    self.contactPickerView.allowsCompletionOfSelectedContacts = NO;
    [self.view addSubview:self.contactPickerView];
    
    [self setBackgroundColor:[UIColor lightGrayColor]];
    
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self scrollToBottomAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - View Type
- (void) setupView
{
    switch (_messageType) {
            
        case JCExistingConversation: {
            
            self.contactPickerView.hidden = YES;
            [self subscribeToConversationNotification:YES];
            
            //conversationEntries = [NSMutableArray arrayWithArray:[ConversationEntry RetrieveConversationEntryById:_conversationId]];
            
            if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
                [self.tableView setSeparatorInset:UIEdgeInsetsZero];
            }
            
            break;
        }
        case JCNewConversation: {
            self.title = NSLocalizedString(@"New Message", @"New Message");
            
            break;
        }
        case JCNewConversationWithEntity: {
            if (!self.selectedContacts) {
                self.selectedContacts = [[NSMutableArray alloc] init];
            }
            
            self.title = self.person.firstLastName;
            [self.selectedContacts addObject:self.person];
            [self checkForConversationWithEntities:self.selectedContacts];
            
            break;
        }
        case JCNewConversationWithGroup: {
            self.contactPickerView.hidden = YES;
            break;
        }
    }
    
    if (self.messageType == JCNewConversationWithGroup || self.messageType == JCNewConversationWithEntity) {
        // check if there's a previous conversation with the group or person
        NSMutableArray *entities;
        if (self.messageType == JCNewConversationWithEntity) {
            entities = [[NSMutableArray alloc] initWithObjects:self.person.entityId, nil];
        }
        else if (self.messageType == JCNewConversationWithGroup) {
            entities = [NSMutableArray arrayWithArray:self.contactGroup.clientEntities];
        }
        
        [self checkForConversationWithEntities:entities];
    }
}


#pragma mark - Table view data source
- (void)setupDataSources
{
    // datasource for avatars
    Conversation *conversation = [Conversation MR_findFirstByAttribute:@"conversationId" withValue:_conversationId];
    if (conversation) {
        if(!self.avatars){
            self.avatars = [NSMutableDictionary new];
        }
        
        NSArray *conversationMembers = (NSArray *)conversation.entities;
        
        for (NSString* entityId in conversationMembers) {
            
            ClientEntities *person = [ClientEntities MR_findFirstByAttribute:@"entityId" withValue:entityId];
            if (person) {
                [self.avatars setObject:person.picture forKey:person.firstLastName];
            }
        }
    }
    
    // datasouce for conversation entries
    self.messages = [NSMutableArray array];
    
    NSArray *entries = [ConversationEntry RetrieveConversationEntryById:_conversationId];
    
    for (ConversationEntry *entry in entries) {
        
        NSArray* result = [ClientEntities MR_findByAttribute:@"entityId" withValue:entry.entityId];
        ClientEntities* person = (ClientEntities*)result[0];
        
        JSMessage *message = [[JSMessage alloc] initWithText:entry.message[@"raw"] sender:person.firstLastName date:[Common NSDateFromTimestap:entry.createdDate]];
        
        [self.messages addObject:message];
    }
    
    
    // datasource for contactPicker
    NSArray *array = [ClientEntities MR_findAll];
    
    NSMutableArray *contacts = [[NSMutableArray alloc] initWithCapacity:array.count];
    for (ClientEntities *contact in array)
    {
        JCContactModel *model = [[JCContactModel alloc] init];
        model.contactTitle = contact.firstLastName;
        model.contactSubtitle = contact.email;
        model.person = contact;
        [contacts addObject:model];
    }
    self.contacts = contacts;

}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

#pragma mark - Messages view delegate: REQUIRED

- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date
{
//    if ((self.messages.count - 1) % 2) {
    [JSMessageSoundEffect playMessageSentSound];
//    }
//    else {
//        // for demo purposes only, mimicing received messages
//        [JSMessageSoundEffect playMessageReceivedSound];
//        sender = arc4random_uniform(10) % 2 ? kSubtitleCook : kSubtitleWoz;
//    }
    
    [self.messages addObject:[[JSMessage alloc] initWithText:text sender:sender date:date]];
    [self dispatchMessage:text];
    [self finishSend];
    [self scrollToBottomAnimated:YES];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sender = ((JSMessage *)self.messages[indexPath.row]).sender;
    if ([sender isEqualToString:me.firstLastName]) {
        return JSBubbleMessageTypeOutgoing;
    }
    else {
        return JSBubbleMessageTypeIncoming;
    }
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sender = ((JSMessage *)self.messages[indexPath.row]).sender;
    if ([sender isEqualToString:me.firstLastName]) {
        return [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                                 color:[UIColor js_bubbleLightGrayColor]];
    }
    else {
        return [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                          color:[UIColor js_bubbleBlueColor]];
    }
}

- (JSMessageInputViewStyle)inputViewStyle
{
    return JSMessageInputViewStyleFlat;
}

#pragma mark - Messages view delegate: OPTIONAL

- (BOOL)shouldDisplayTimestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row % 3 == 0) {
        return YES;
    }
    return NO;
}

//  *** Implement to prevent auto-scrolling when message is added
//
- (BOOL)shouldPreventScrollToBottomWhileUserScrolling
{
    return YES;
}

// *** Implemnt to enable/disable pan/tap todismiss keyboard
//
- (BOOL)allowsPanToDismissKeyboard
{
    return YES;
}

#pragma mark - Messages view data source: REQUIRED


-(JSMessage *)messageForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //JCChatMessage *message = [self.messages objectAtIndex:indexPath.row];
    return [self.messages objectAtIndex:indexPath.row];
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath sender:(NSString *)sender
{
    UIImageView *avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kOsgiBaseURL, self.avatars[sender]]];
    [avatarImageView setImageWithURL:imageURL placeholderImage:[UIImage imageNamed:@"avatar.png"]];
    return avatarImageView;
}

#pragma mark - Class Methods
#pragma mark - Subscribe/Unsubcribe to conversation notifications
- (void) subscribeToConversationNotification:(BOOL)subscribe
{
    // if we have a conversationId, subscribe to notifications for that conversation
    if (_conversationId) {
        if (subscribe) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingChatEntry:) name:_conversationId object:nil];
        }
        else {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:_conversationId object:nil];
        }
    }
}

#pragma mark - Incoming chat
- (void)incomingChatEntry:(NSNotification*)notification
{
    if (_conversationId) {
        [self setupDataSources];
        [self.tableView reloadData];
        [self scrollToBottomAnimated:YES];
//        [self.tableView reloadData];
    }
}

#pragma mark - Send/Create Conversation
- (void)dispatchMessage:(NSString *)message {
    
    NSString* entity = me.urn;
    
    // if conversation exists, then create entry for that conversation
    if (_conversationId != nil && ![_conversationId isEqualToString:@""]) {
        
        [[JCOsgiClient sharedClient] SubmitChatMessageForConversation:_conversationId message:message withEntity:entity success:^(id JSON) {
            // confirm to user message was sent
            //[self finishSend];
        } failure:^(NSError *err) {
            // alert user that message could not be sent. try again.
        }];
        
        //[self cleanup];
    }
    // otherwise, create a converstion first
    else {
        [self createConversation:message];
    }
}

- (void)createConversation:(NSString *)message
{
    BOOL isGroup = self.selectedContacts.count >= 2;
    NSArray *nameArray = [self.selectedContacts valueForKeyPath:@"firstName"];
    NSString *groupName = isGroup? [self composeGroupName:nameArray] : @"";
    
    NSMutableArray *entityArray = [[NSMutableArray alloc] initWithArray:[self.selectedContacts valueForKeyPath:@"entityId"]];
    [entityArray addObject:me.entityId];
    
    [[JCOsgiClient sharedClient] SubmitConversationWithName:groupName forEntities:entityArray creator:me.entityId  isGroupConversation:isGroup success:^(id JSON) {
        
        // if conversation creation was successful, then subscribe for notifications to that conversationId
        _conversationId = JSON[@"id"];
        [self subscribeToConversationNotification:YES];
        
        // we can now add entries to the conversation recently created.
        [self dispatchMessage:message];
        
    } failure:^(NSError *err) {
        // alert user that message could not be sent. try again.
        NSLog(@"%@", [err description]);
    }];
}

- (NSString *)composeGroupName:(NSArray *)names
{
    int originalCount = names.count;
    if (names.count > 3) {
        names = [names subarrayWithRange:NSMakeRange(0, 3)];
        return [NSString stringWithFormat:@"%@, +%i", [names componentsJoinedByString:@"," ], (originalCount - names.count)];
    }
    else {
        return [names componentsJoinedByString:@", "];
    }
}

#pragma mark - Conversation Loading
- (void)checkForConversationWithEntities:(NSMutableArray*)entities
{
    if  (!entities) {
        return;
    }
    
    if (entities.count == 0) {
        return;
    }
    
    NSArray *entityArray = nil;
    
    if ([entities[0] isKindOfClass:[ClientEntities class]]) {
        entityArray = [entities valueForKeyPath:@"entityId"];
    }
    else {
        entityArray = entities;
    }
    
    Conversation *existingConversation = nil;
    NSMutableSet *entitySet = [NSMutableSet setWithArray:entityArray];
    NSArray *conversations = [Conversation MR_findAll];
    for (Conversation *conv in conversations) {
        
        NSMutableArray *entitiesInConversation = [NSMutableArray arrayWithArray:(NSArray *)conv.entities];
        // remove myself from the entities
        if ([entitiesInConversation containsObject:me.entityId]) {
            [entitiesInConversation removeObject:me.entityId];
        }
        
        NSMutableSet *conversationSet = [NSMutableSet setWithArray:entitiesInConversation];
        
        if ([conv.isGroup boolValue]) {
            if (conversationSet.count < 3) {
                NSLog(@"This is messed up");
            }
        }
        
        [conversationSet intersectSet:entitySet];
        NSArray *result = [conversationSet allObjects];
        
        //NSArray *conversationEntities = (NSArray*)conv.entities;
        //NSMutableSet *convEntities = [NSMutableSet setWithArray:conversationEntities];
        //[convEntities intersectSet:[NSMutableSet setWithArray:entityArray]];
        
        if (result.count != 0 && result.count == entitiesInConversation.count) {
            NSLog(@"found");
            existingConversation = conv;
            break;
        }
        
        if (existingConversation) {
            break;
        }
    }
    
    if (existingConversation) {
        _conversationId = existingConversation.conversationId;
        //conversationEntries = [NSMutableArray arrayWithArray:[ConversationEntry MR_findByAttribute:@"conversationId" withValue:_conversationId andOrderBy:@"lastModified" ascending:YES]];
        [self subscribeToConversationNotification:YES];
        //[textView becomeFirstResponder];
    }
    else {
        [self subscribeToConversationNotification:NO];
        _conversationId = nil;
        //[conversationEntries removeAllObjects];
        
    }
    
    [self.tableView reloadData];
}

#pragma mark - MBContactPickerDataSource

- (NSArray *)contactModelsForContactPicker:(MBContactPicker*)contactPickerView
{
    return self.contacts;
}

#pragma mark - MBContactPickerDelegate

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didSelectContact:(id<MBContactPickerModelProtocol>)model
{
    NSLog(@"Did Select: %@", model.contactTitle);
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didAddContact:(id<MBContactPickerModelProtocol>)model
{
    NSLog(@"Did Add: %@", model.contactTitle);
    if (!self.selectedContacts) {
        self.selectedContacts = [[NSMutableArray alloc] init];
    }
    [self.selectedContacts addObject:((JCContactModel *)model).person];
    
    [self checkForConversationWithEntities:self.selectedContacts];
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didRemoveContact:(id<MBContactPickerModelProtocol>)model
{
    NSLog(@"Did Remove: %@", model.contactTitle);
}

// This delegate method is called to allow the parent view to increase the size of
// the contact picker view to show the search table view
- (void)didShowFilteredContactsForContactPicker:(MBContactPicker*)contactPicker
{
    if (self.contactPickerViewHeightConstraint.constant <= contactPicker.currentContentHeight)
    {
        [UIView animateWithDuration:contactPicker.animationSpeed animations:^{
            CGRect pickerRectInWindow = [self.view convertRect:contactPicker.frame fromView:nil];
            CGFloat newHeight = self.view.window.bounds.size.height - pickerRectInWindow.origin.y - contactPicker.keyboardHeight;
            self.contactPickerViewHeightConstraint.constant = newHeight;
            [self.view layoutIfNeeded];
        }];
    }
}

// This delegate method is called to allow the parent view to decrease the size of
// the contact picker view to hide the search table view
- (void)didHideFilteredContactsForContactPicker:(MBContactPicker*)contactPicker
{
    if (self.contactPickerViewHeightConstraint.constant > contactPicker.currentContentHeight)
    {
        [UIView animateWithDuration:contactPicker.animationSpeed animations:^{
            self.contactPickerViewHeightConstraint.constant = contactPicker.currentContentHeight;
            [self.view layoutIfNeeded];
        }];
    }
}

// This delegate method is invoked to allow the parent to increase the size of the
// collectionview that shows which contacts have been selected. To increase or decrease
// the number of rows visible, change the maxVisibleRows property of the MBContactPicker
- (void)contactPicker:(MBContactPicker*)contactPicker didUpdateContentHeightTo:(CGFloat)newHeight
{
    self.contactPickerViewHeightConstraint.constant = newHeight;
    [UIView animateWithDuration:contactPicker.animationSpeed animations:^{
        [self.view layoutIfNeeded];
    }];
}



@end
