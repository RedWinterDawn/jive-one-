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
#import "JCAppDelegate.h"

@interface JCMessagesViewController ()
{
    ClientEntities *me;
    NSString *title;
    NSString *subtitle;
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
    
    [self setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1] /*#e8e8e8*/];
    
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
    
    [self setCustomHeader];
    
    switch (_messageType) {
            
        case JCExistingConversation: {
            
            [self.contactPickerView removeFromSuperview];
            [self subscribeToConversationNotification:YES];
            
            if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
                [self.tableView setSeparatorInset:UIEdgeInsetsZero];
            }
            
            [self setHeaderTitle:title andSubtitle:subtitle];
            
            break;
        }
        case JCNewConversation: {
            [self setHeaderTitle:NSLocalizedString(@"New Message", @"New Message") andSubtitle:nil] ;
            
            break;
        }
        case JCNewConversationWithEntity: {
            [self.contactPickerView removeFromSuperview];
            if (!self.selectedContacts) {
                self.selectedContacts = [[NSMutableArray alloc] init];
            }
            
            [self setHeaderTitle:_person.firstLastName andSubtitle:_person.email] ;
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

- (void) setCustomHeader
{
    // Replace titleView
    CGRect headerTitleSubtitleFrame = CGRectMake(0, 0, 200, 44);
    UIView* _headerTitleSubtitleView = [[UILabel alloc] initWithFrame:headerTitleSubtitleFrame];
    _headerTitleSubtitleView.backgroundColor = [UIColor clearColor];
    _headerTitleSubtitleView.autoresizesSubviews = YES;
    
    CGRect titleFrame = CGRectMake(0, 2, 200, 24);
    UILabel *titleView = [[UILabel alloc] initWithFrame:titleFrame];
    titleView.backgroundColor = [UIColor clearColor];
    titleView.font = [UIFont boldSystemFontOfSize:20];
    titleView.textAlignment = NSTextAlignmentCenter;
    titleView.textColor = [UIColor whiteColor];
    titleView.shadowColor = [UIColor darkGrayColor];
    titleView.shadowOffset = CGSizeMake(0, -1);
    titleView.text = @"";
    titleView.adjustsFontSizeToFitWidth = YES;
    [_headerTitleSubtitleView addSubview:titleView];
    
    CGRect subtitleFrame = CGRectMake(0, 24, 200, 44-24);
    UILabel *subtitleView = [[UILabel alloc] initWithFrame:subtitleFrame];
    subtitleView.backgroundColor = [UIColor clearColor];
    subtitleView.font = [UIFont boldSystemFontOfSize:13];
    subtitleView.textAlignment = NSTextAlignmentCenter;
    subtitleView.textColor = [UIColor whiteColor];
    subtitleView.shadowColor = [UIColor darkGrayColor];
    subtitleView.shadowOffset = CGSizeMake(0, -1);
    subtitleView.text = @"";
    subtitleView.adjustsFontSizeToFitWidth = YES;
    [_headerTitleSubtitleView addSubview:subtitleView];
    
    _headerTitleSubtitleView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                                 UIViewAutoresizingFlexibleRightMargin |
                                                 UIViewAutoresizingFlexibleTopMargin |
                                                 UIViewAutoresizingFlexibleBottomMargin);
    
    self.navigationItem.titleView = _headerTitleSubtitleView;

}

-(void) setHeaderTitle:(NSString*)headerTitle andSubtitle:(NSString*)headerSubtitle {
    assert(self.navigationItem.titleView != nil);
    UIView* headerTitleSubtitleView = self.navigationItem.titleView;
    UILabel* titleView = [headerTitleSubtitleView.subviews objectAtIndex:0];
    UILabel* subtitleView = [headerTitleSubtitleView.subviews objectAtIndex:1];
    assert((titleView != nil) && (subtitleView != nil) && ([titleView isKindOfClass:[UILabel class]]) && ([subtitleView isKindOfClass:[UILabel class]]));
    titleView.text = headerTitle;
    subtitleView.text = headerSubtitle;
}


#pragma mark - Table view data source
- (void)setupDataSources
{
    if (_conversationId) {
        
        // clear badges for this conversation
        [(JCAppDelegate *)[UIApplication sharedApplication].delegate clearBadgeCountForConversation:_conversationId];
            
        // datasource for avatars
        if (!self.avatars){
            Conversation *conversation = [Conversation MR_findFirstByAttribute:@"conversationId" withValue:_conversationId];
            if (conversation) {
                if(!self.avatars){
                    self.avatars = [NSMutableDictionary new];
                }
                
                NSArray *conversationMembers = (NSArray *)conversation.entities;
                
                if ([conversation.isGroup boolValue]) {
                    title = conversation.name;
                }
                
                
                for (NSString* entityId in conversationMembers) {
                    
                    ClientEntities *person = [ClientEntities MR_findFirstByAttribute:@"entityId" withValue:entityId];
                    if (person) {
                        [self.avatars setObject:person.picture forKey:person.firstLastName];
                        
                        if (person != me && ![conversation.isGroup boolValue]) {
                            title = person.firstLastName;
                            subtitle = person.email;
                        }
                    }
                }
            }
        }
        
        
        
        // datasouce for conversation entries
        if (!self.messages) {
            self.messages = [NSMutableArray array];
        }
        
        [self.messages removeAllObjects];
        
        NSArray *entries = [ConversationEntry RetrieveConversationEntryById:_conversationId];
        
        for (ConversationEntry *entry in entries) {
            
            NSArray* result = [ClientEntities MR_findByAttribute:@"entityId" withValue:entry.entityId];
            ClientEntities* person = (ClientEntities*)result[0];
            
            NSString *sender = [NSString stringWithFormat:@"%@ - %@", person.firstLastName, [Common shortDateFromTimestamp:entry.lastModified]];
            
            JSMessage *message = [[JSMessage alloc] initWithText:entry.message[@"raw"] sender:sender date:[Common NSDateFromTimestap:entry.createdDate]];
            
            [self.messages addObject:message];
        }
    }
    
    
    
    // datasource for contactPicker
    if (!self.contacts) {
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
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

#pragma mark - Messages view delegate: REQUIRED

- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date
{
    [self.messages addObject:[[JSMessage alloc] initWithText:text sender:sender date:date]];
    [self dispatchMessage:text];
    [self finishSend];
    [self scrollToBottomAnimated:YES];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sender = ((JSMessage *)self.messages[indexPath.row]).sender;
    
    NSRange range = [sender rangeOfString:me.firstLastName];
    
    if (range.location == NSNotFound) {
        return JSBubbleMessageTypeIncoming;
    }
    else {
        return JSBubbleMessageTypeOutgoing;
    }
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSString *sender = ((JSMessage *)self.messages[indexPath.row]).sender;
//    if ([sender isEqualToString:me.firstLastName]) {
//        return [JSBubbleImageViewFactory bubbleImageViewForType:type
//                                                                 color:[UIColor js_bubbleLightGrayColor]];
//    }
//    else {
//        return [JSBubbleImageViewFactory bubbleImageViewForType:type
//                                                          color:[UIColor js_bubbleBlueColor]];
//    }
    
    return [JSBubbleImageViewFactory bubbleImageViewForType:type color:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
    //return [JSBubbleImageViewFactory classicBubbleImageViewForType:type style:JSBubbleImageViewStyleClassicSquareGray];
}

- (JSMessageInputViewStyle)inputViewStyle
{
    return JSMessageInputViewStyleFlat;
}

#pragma mark - Messages view delegate: OPTIONAL

//
//  *** Implement to customize cell further
//
- (void)configureCell:(JSBubbleMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
//    if ([cell messageType] == JSBubbleMessageTypeOutgoing) {
//        cell.bubbleView.textView.textColor = [UIColor whiteColor];
//        
//        if ([cell.bubbleView.textView respondsToSelector:@selector(linkTextAttributes)]) {
//            NSMutableDictionary *attrs = [cell.bubbleView.textView.linkTextAttributes mutableCopy];
//            [attrs setValue:[UIColor blueColor] forKey:NSForegroundColorAttributeName];
//            
//            cell.bubbleView.textView.linkTextAttributes = attrs;
//        }
//    }
    
    if (cell.timestampLabel) {
        cell.timestampLabel.textColor = [UIColor darkGrayColor];
        cell.timestampLabel.font = [UIFont systemFontOfSize:10.0f];
        cell.timestampLabel.shadowOffset = CGSizeZero;
    }
    
    if (cell.subtitleLabel) {
        cell.subtitleLabel.textColor = [UIColor whiteColor];
    }
    
#if TARGET_IPHONE_SIMULATOR
    cell.bubbleView.textView.dataDetectorTypes = UIDataDetectorTypeNone;
#else
    cell.bubbleView.textView.dataDetectorTypes = UIDataDetectorTypeAll;
#endif
}

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
    return [self.messages objectAtIndex:indexPath.row];
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath sender:(NSString *)sender
{
    UIImageView *avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kOsgiBaseURL, self.avatars[sender]]];
    [avatarImageView setImageWithURL:imageURL placeholderImage:[UIImage imageNamed:@"avatar.png"] options:SDWebImageRefreshCached];
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
        
        [(JCAppDelegate *)[UIApplication sharedApplication].delegate clearBadgeCountForConversation:_conversationId];
        
        ConversationEntry *entry = (ConversationEntry *)notification.object;
        if (![entry.entityId isEqualToString:me.entityId]) {
            [JSMessageSoundEffect playMessageReceivedSound];
        }
    }
}

#pragma mark - Send/Create Conversation
- (void)dispatchMessage:(NSString *)message {
    
    
    [self hideContactPicker];
    NSString* entity = me.urn;
    
    
    // if conversation exists, then create entry for that conversation
    if (_conversationId != nil && ![_conversationId isEqualToString:@""]) {
        
        [[JCOsgiClient sharedClient] SubmitChatMessageForConversation:_conversationId message:message withEntity:entity success:^(id JSON) {
            // confirm to user message was sent
           [JSMessageSoundEffect playMessageSentSound];
        } failure:^(NSError *err) {
            NSLog(@"%@", err);
            [JCMessagesViewController handleFailedMessageDispatch:_conversationId withMessage:message];
        }];
        
        //[self cleanup];
    }
    // otherwise, create a converstion first
    else {
        [self createConversation:message];
    }
}

//if a message cannot be sent (becuase of no connecitivity) this method is called. this method puts these messages into a queue (saved in user defaults)
+(void) handleFailedMessageDispatch:(NSString*)conversationId withMessage:(NSString*)message{
    //alert the user that message will be sent when connectivity is restored
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message not sent" message:@"Messages will be sent when connectivity is restored" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    
    //build queue for sending unsent messages
    NSDictionary *unsentQueue = [[NSUserDefaults standardUserDefaults] objectForKey:@"unsentMessageQueue"];
    if(!unsentQueue){
        unsentQueue = [[NSMutableDictionary alloc] init];
    }
    NSMutableDictionary *unsentQueueMutable = [[NSMutableDictionary alloc] initWithDictionary:unsentQueue];
    
    NSMutableArray *messages;
    if([unsentQueue objectForKey:conversationId]){
        messages  = [unsentQueueMutable objectForKey:conversationId];
    }
    else{
        messages = [[NSMutableArray alloc] init];
        [unsentQueueMutable setObject:messages forKey:conversationId];
    }
    [messages addObject:message];
    
    //save queue to user defaults
    [[NSUserDefaults standardUserDefaults] setObject:unsentQueueMutable forKey:@"unsentMessageQueue"];

}

//when connectvitity is restored this method is called. this method retrives a queue of unsent messages from user defaults and begins sending them.
+(void) sendOfflineMessagesQueue{
    NSDictionary *unsentMessagesQueue = [[NSUserDefaults standardUserDefaults] objectForKey:@"unsentMessageQueue"];

    [unsentMessagesQueue enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *messages, BOOL *stop) {
        __block BOOL removeKey = YES;
        for(int i=0;i<messages.count;i++){
            
            [[JCOsgiClient sharedClient] SubmitChatMessageForConversation:key message:messages[i] withEntity:nil success:^(id JSON) {
                [JSMessageSoundEffect playMessageSentSound];
                
            } failure:^(NSError *err) {
                removeKey = NO;
                [self handleFailedMessageDispatch:key withMessage:messages[i]];
            }];
        }
        //remove key from unsentQueue dictionary so long as there were no failures
        if(removeKey){
         //TODO: remove stuff
        }
    }];
    //    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"unsentMessageQueue"];
}

- (void)createConversation:(NSString *)message
{
    BOOL isGroup = self.selectedContacts.count >= 2;
    NSArray *nameArray = [self.selectedContacts valueForKeyPath:@"firstName"];
    NSString *groupName = isGroup? [self composeGroupName:nameArray] : @"";
    
    NSMutableArray *entityArray = [[NSMutableArray alloc] initWithArray:[self.selectedContacts valueForKeyPath:@"entityId"]];
    [entityArray addObject:me.entityId];
    
    [[JCOsgiClient sharedClient] SubmitConversationWithName:groupName forEntities:entityArray creator:me.entityId  isGroupConversation:isGroup success:^(id JSON) {
        
        NSLog(@"%@", JSON);
        
        // if conversation creation was successful, then subscribe for notifications to that conversationId
        _conversationId = JSON[@"id"];
        [self subscribeToConversationNotification:YES];
        
        // we can now add entries to the conversation recently created.
        [self dispatchMessage:message];
        
    } failure:^(NSError *err) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Could not send your message at this time. Please try again.", nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        
        self.messageInputView.textView.text = message;
        
        [alertView show];
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
        
        if (result.count != 0 && result.count == entitiesInConversation.count && entitiesInConversation.count == entityArray.count) {
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
        [self setupDataSources];
        //[textView becomeFirstResponder];
    }
    else {
        [self subscribeToConversationNotification:NO];
        _conversationId = nil;
        [self.messages removeAllObjects];
        [self setupDataSources];
    }
    
    [self.tableView reloadData];
}

#pragma mark - MBContactPickerDataSource

- (NSArray *)contactModelsForContactPicker:(MBContactPicker*)contactPickerView
{
    return self.contacts;
}

- (void) showContactPicker
{
    [UIView animateWithDuration:0.5 animations:^{
        
        self.contactPickerView.hidden = NO;
        self.contactPickerView.alpha = 1;
        CGRect contactFrame = self.contactPickerView.frame;
        // set the y coordinate to the current position minus the height of the view.
        // this will move the view up the height of the bar, essentially moving it off the top of the view.
        //double y = ;
        contactFrame.origin.y = 0;
        // set the position of the view
        self.contactPickerView.frame = contactFrame;
        
        // update conversation table position
        CGRect frame = self.tableView.frame;
        frame.origin.y = self.contactPickerView.frame.size.height;
        frame.size.height = frame.size.height - self.contactPickerView.frame.size.height;
        self.tableView.frame = frame;
        
    } completion:^(BOOL finished) {
    }];
}

- (void)hideContactPicker
{
    [UIView animateWithDuration:0.5 animations:^{
        CGRect contactFrame = self.contactPickerView.frame;
        // set the y coordinate to the current position minus the height of the view.
        // this will move the view up the height of the bar, essentially moving it off the top of the view.
        contactFrame.origin.y = -contactFrame.size.height;
        // set the position of the view
        self.contactPickerView.frame = contactFrame;
        self.contactPickerView.alpha = 0;
        
        // update message table position
        CGRect frame = self.tableView.frame;
        frame.origin.y = 0;
        frame.size.height = frame.size.height + self.contactPickerView.frame.size.height;
        self.tableView.frame = frame;
        
    } completion:^(BOOL finished) {
        self.contactPickerView.hidden = YES;
    }];
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
