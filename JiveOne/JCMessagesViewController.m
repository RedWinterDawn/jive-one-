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
#import "JCRESTClient.h"
#import "PersonEntities.h"
#import "JCContactModel.h"
#import "JSMessage.h"
#import "Common.h"
#import "JCAppDelegate.h"
#import "TRVSMonitor.h"
#import "JCPeopleSearchViewController.h"
#import "JCDirectoryViewController.h"

@interface JCMessagesViewController ()
{
    PersonEntities *me;
    NSString *title;
    NSString *subtitle;
    JCRESTClient *osgiClient;
    NSManagedObjectContext *context;
    BOOL addingPeople;
    BOOL needsPatch;
    int existingConversationEntities;
}

@property (nonatomic) NSArray *contacts;
@property (nonatomic) NSMutableArray *selectedContacts;
@property (nonatomic) NSMutableArray *addedContacts;
@property (weak, nonatomic) IBOutlet MBContactPicker *contactPickerView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contactPickerViewHeightConstraint;
@property (nonatomic, strong) Conversation *conversation;


@end

@implementation JCMessagesViewController

#pragma mark - Message Type Setters
- (void)setMessageType:(JCMessageType)messageType
{
    _messageType = messageType;
}

- (void)setPerson:(PersonEntities *)person
{
    if (person && [person isKindOfClass:[PersonEntities class]]) {
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
    CGRect frame = self.contactPickerView.frame;
    frame.size.height = 38.0f;
    [self.contactPickerView setFrame:frame];
    self.contactPickerView.allowsCompletionOfSelectedContacts = NO;
    [self.view addSubview:self.contactPickerView];
    [self.view insertSubview:self.imageViewNewMessage belowSubview:self.contactPickerView]; 
    
    [self setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1] /*#e8e8e8*/];
    
    [self setupView];
    [JCMessagesViewController sendOfflineMessagesQueue:[JCRESTClient sharedClient]];
}

- (NSManagedObjectContext *)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    return context;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [Flurry logEvent:@"Message View"];
    context = [self context];
    [self scrollToBottomAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - PeopleSearchDelegate
- (void)dismissedWithPerson:(PersonEntities *)person
{
    [self addPersonFromPersonPicker:person];
}

- (void)dismissedByCanceling
{
    if (addingPeople && _addedContacts.count == 0 && _messageType == JCNewConversation) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
    
    addingPeople = NO;
}

- (IBAction)showPeopleSearch:(id)sender {
    addingPeople = YES;
    UINavigationController* peopleNavController = [self.storyboard instantiateViewControllerWithIdentifier:@"PeopleNavViewController"];
    JCDirectoryViewController *directory = peopleNavController.childViewControllers[0];
    directory.delegate = self;
    [self presentViewController:peopleNavController animated:YES completion:^{
        //Completed
    }];
}

- (void) addPersonFromPersonPicker:(PersonEntities *)person
{
    if (!self.addedContacts) {
        self.addedContacts = [[NSMutableArray alloc] init];
    }
    
    [self.addedContacts addObject:person];
    
    if (_messageType != JCExistingConversation) {
        [self checkForConversationWithEntities:self.addedContacts];
    }
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:_selectedContacts];
    [tempArray addObjectsFromArray:_addedContacts];
    
    if (tempArray.count == 1) {
        [self setHeaderTitle:person.firstLastName andSubtitle:person.email];
    }
    else {
        
        NSArray *nameArray = [tempArray valueForKeyPath:@"firstName"];
        NSString *groupName = [self composeGroupName:nameArray];
        [self setHeaderTitle:groupName andSubtitle:[NSString stringWithFormat:@"+ me"]];
    }
    
    [self enableSendButtonBasedOnSelectedContacts];
}

#pragma mark - ConversationParticipantDelegate

- (void)didAddPersonFromParticipantView:(PersonEntities *)person
{
    [self addPersonFromPersonPicker:person];
}

#pragma mark - View Type
- (void) setupView
{
    
    [self setCustomHeader];
    
    
    UISwipeGestureRecognizer *swipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    [self.tableView addGestureRecognizer:swipeLeftGesture];
    swipeLeftGesture.direction=UISwipeGestureRecognizerDirectionLeft;
    
    // set a different back button for the navigation controller
    UIBarButtonItem *myBackButton = [[UIBarButtonItem alloc]init];
    myBackButton.title = @"";
    self.navigationItem.backBarButtonItem = myBackButton;
    
    
    switch (_messageType) {
            
        case JCExistingConversation: {
            self.imageViewNewMessage.hidden = YES;
            [self.contactPickerView removeFromSuperview];
            [self subscribeToConversationNotification:YES];
            
            if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
                [self.tableView setSeparatorInset:UIEdgeInsetsZero];
            }
            
            if (_selectedContacts.count == 1) {
                [self setHeaderTitle:title andSubtitle:subtitle];
            }
            else {
                NSArray *nameArray = [self.selectedContacts valueForKeyPath:@"firstName"];
                NSString *groupName = [self composeGroupName:nameArray];
                [self setHeaderTitle:groupName andSubtitle:[NSString stringWithFormat:@"+ me"]];
            }
            
            break;
        }
        case JCNewConversation: {
            [self setHeaderTitle:NSLocalizedString(@"New Message", @"New Message") andSubtitle:nil] ;
            self.imageViewNewMessage.hidden = NO;
            //[self.contactPickerView becomeFirstResponder];
            [self showPeopleSearch:nil];
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
    
    [self enableSendButtonBasedOnSelectedContacts];
    
}

-(void)handleSwipeGesture:(UIGestureRecognizer *)sender
{
    NSUInteger touches = sender.numberOfTouches;
    if (touches == 1 )
    {
        if (sender.state == UIGestureRecognizerStateEnded)
        {
            if (_conversationId) {
                [self performSegueWithIdentifier:@"participantsSegue" sender:nil];
            }
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"participantsSegue"]) {
        JCConversationParticipantsTableViewController *conversationViewController = segue.destinationViewController;
        [conversationViewController setConversation:_conversation];
        [conversationViewController setDelegate:self];
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
    titleView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f];
    titleView.textAlignment = NSTextAlignmentCenter;
    titleView.textColor = [UIColor blackColor];
    titleView.text = @"";
    titleView.adjustsFontSizeToFitWidth = YES;
    [_headerTitleSubtitleView addSubview:titleView];
    
    CGRect subtitleFrame = CGRectMake(0, 24, 200, 44-24);
    UILabel *subtitleView = [[UILabel alloc] initWithFrame:subtitleFrame];
    subtitleView.backgroundColor = [UIColor clearColor];
    subtitleView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f];
    subtitleView.textAlignment = NSTextAlignmentCenter;
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
        
            _conversation = [Conversation MR_findFirstByAttribute:@"conversationId" withValue:_conversationId];
            if (_conversation) {
                if(!self.avatars){
                    self.avatars = [NSMutableDictionary new];
                }
                
                NSArray *conversationMembers = (NSArray *)_conversation.entities;
                
                if ([_conversation.isGroup boolValue]) {
                    title = _conversation.name;
                }
                else if(conversationMembers.count > 2){
#if DEBUG
                    NSLog(@"How can you have a nongroup conversation with more than 2 people!?!?!?");
                    //exit(0);
#endif
                }
                
                
            if (self.avatars.count == 0){
                
                if (!_selectedContacts) {
                    _selectedContacts = [[NSMutableArray alloc] init];
                }
                else {
                    [_selectedContacts removeAllObjects];
                }
                
                for (NSString* entityId in conversationMembers) {
                    
                    PersonEntities *person = [PersonEntities MR_findFirstByAttribute:@"entityId" withValue:entityId];
                    if (person) {
                        
                        if (person != me) {
                            [_selectedContacts addObject:person];
                        }
                             
                        [self.avatars setObject:person.picture forKey:person.firstLastName];
                        
                        if (person != me && ![_conversation.isGroup boolValue]) {
                            title = person.firstLastName;
                            subtitle = person.email;
                        }
                    }
                }
                if (_selectedContacts) {
                    existingConversationEntities = _selectedContacts.count;
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
            
            NSArray* result = [PersonEntities MR_findByAttribute:@"entityId" withValue:entry.entityId];
            PersonEntities* person = (PersonEntities*)result[0];
            
            NSString *sender = [NSString stringWithFormat:@"%@ - %@", person.firstLastName, [Common shortDateFromTimestamp:entry.lastModified]];
            
            JSMessage *message = [[JSMessage alloc] initWithText:entry.message[@"raw"] sender:sender date:[Common NSDateFromTimestap:entry.createdDate]];
            
            [self.messages addObject:message];
        }
    }
    
    
    
    // datasource for contactPicker
    if (!self.contacts) {
        NSArray *array = [PersonEntities MR_findAll];
        
        NSMutableArray *contacts = [[NSMutableArray alloc] initWithCapacity:array.count];
        for (PersonEntities *contact in array)
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
    if ([Common stringIsNilOrEmpty:text]) {
        return;
    }
    
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
        
        id conversationObject = notification.object;
        
        if ([conversationObject isKindOfClass:[ConversationEntry class]]) {
            ConversationEntry *entry = (ConversationEntry *) conversationObject;
            if (![entry.entityId isEqualToString:me.entityId]) {
                [JSMessageSoundEffect playMessageReceivedSound];
            }
        }
        else if ([conversationObject isKindOfClass:[Conversation class]]) {
//            Conversation *conversation = (Conversation *) conversationObject;
//            _conversation = conversation;
            [self setupDataSources];
        }
    }
}

#pragma mark - Send/Create Conversation
- (void)dispatchMessage:(NSString *)message {
    
    self.imageViewNewMessage.hidden = YES;
    
    // if conversation exists, then create entry for that conversation
    if (_addedContacts && _messageType != JCNewConversation) {
        if (_addedContacts.count > 0) {
            needsPatch = YES;
        }
    }
    
    
    if (![Common stringIsNilOrEmpty:_conversationId] && !needsPatch) {
        
        __block ConversationEntry *entry = [self createEntryLocallyForConversation:_conversationId withMessage:message withTimestamp:[NSDate date] inContext:[self context]];
        
        [[JCRESTClient sharedClient] SubmitChatMessageForConversation:_conversationId message:entry.message withEntity:entry.entityId withTimestamp:[entry.createdDate longLongValue] withTempUrn:entry.tempUrn success:^(id JSON) {
            // confirm to user message was sent
           [JSMessageSoundEffect playMessageSentSound];
        } failure:^(NSError *err, AFHTTPRequestOperation *operation) {
            NSLog(@"%@", err);
            entry.failedToSend = [NSNumber numberWithBool:YES];
            [[self context] MR_saveToPersistentStoreAndWait];
            
        }];
        
        //[self cleanup];
    }
    // otherwise, create a converstion first
    else {
        [self createConversation:message];
    }
}

- (ConversationEntry*) createEntryLocallyForConversation:(NSString *)conversationId withMessage:(NSString *)message withTimestamp:(NSDate *)timestamp inContext:(NSManagedObjectContext *)currentContext {
    
    if (!currentContext) {
        currentContext = [self context];
    }
    
    ConversationEntry *entry = [ConversationEntry MR_createInContext:currentContext];
    entry.conversationId = conversationId;
    entry.entityId = me.entityId;
    
    //sanity check
    NSDictionary *messageDictionary = [NSDictionary dictionaryWithObjectsAndKeys:message, @"raw", nil];
    NSLog(@"%@", messageDictionary);
    
    entry.message = messageDictionary;
    entry.createdDate = [NSNumber numberWithLongLong:[Common epochFromNSDate:timestamp]];
//    entry.lastModified = [NSNumber numberWithLongLong:[Common epochFromNSDate:timestamp]];
    entry.tempUrn = [[NSUUID UUID] UUIDString];
    
    [currentContext MR_saveToPersistentStoreAndWait];
    
    return entry;
}

- (void)createConversation:(NSString *)message
{
    if (needsPatch && _messageType == JCExistingConversation) {
        [_selectedContacts addObjectsFromArray:_addedContacts];
    }
    else {
        _selectedContacts = [NSMutableArray arrayWithArray:_addedContacts];
    }
    
    
    BOOL isGroup = self.selectedContacts.count >= 2;
    NSArray *nameArray = [self.selectedContacts valueForKeyPath:@"firstName"];
    NSString *groupName = isGroup? [self composeGroupName:nameArray] : @"";
    
    NSMutableArray *entityArray = [[NSMutableArray alloc] initWithArray:[self.selectedContacts valueForKeyPath:@"entityId"]];
    [entityArray addObject:me.entityId];
    
    if (needsPatch) {
        [[JCRESTClient sharedClient] PatchConversationWithName:_conversationId groupName:groupName forEntities:entityArray creator:me.entityId isGroupConversation:isGroup success:^(id JSON) {
            
            // success patching
            [_addedContacts removeAllObjects];
            needsPatch = NO;
            [self dispatchMessage:message];
            
        } failure:^(NSError *err) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Could not patch your message at this time.", nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            self.messageInputView.textView.text = message;
            [alertView show];
        }];
        
    }
    else {
    
        [[JCRESTClient sharedClient] SubmitConversationWithName:groupName forEntities:entityArray creator:me.entityId  isGroupConversation:isGroup success:^(id JSON) {
            // if conversation creation was successful, then subscribe for notifications to that conversationId
            _conversationId = JSON[@"id"];
            if (_conversationId) {
                
                [self subscribeToConversationNotification:YES];
                
                // Add message to table so we provice user imediate feedback
                //NSString *sender = [NSString stringWithFormat:@"%@ - %@", me.firstLastName, [NSDate date]];
                //JSMessage *messageEntry = [[JSMessage alloc] initWithText:message sender:sender date:[NSDate date]];
                //[self.messages addObject:messageEntry];
                [self setupDataSources];            
                [self.tableView reloadData];
                
                
                [self hideContactPicker];
                
                // we can now add entries to the conversation recently created.
                [self dispatchMessage:message];
            }
            
        } failure:^(NSError *err) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Could not send your message at this time. Please try again.", nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            
            self.messageInputView.textView.text = message;
            
            [alertView show];
        }];
    }
}

- (NSString *)composeGroupName:(NSArray *)names
{
    int originalCount = (int)names.count;
    if (names.count > 3) {
        names = [names subarrayWithRange:NSMakeRange(0, 3)];
        return [NSString stringWithFormat:@"%@, +%u", [names componentsJoinedByString:@"," ], (int)(originalCount - names.count)];
    }
    else {
        return [names componentsJoinedByString:@", "];
    }
}


//when connectvitity is restored this method is called. this method retrives a queue of unsent messages from user defaults and begins sending them.
+(void) sendOfflineMessagesQueue:(JCRESTClient*)osgiClient{
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"failedToSend == YES"];
    NSMutableArray *unsentMessages = [NSMutableArray arrayWithArray:[ConversationEntry MR_findAllSortedBy:@"createdDate" ascending:YES withPredicate:pred]];
    //TODO: refactor to send messages serially
    
    if(unsentMessages.count>0){
        ConversationEntry *conv = (ConversationEntry*)unsentMessages[0];
        NSLog(@"Sending...%@", conv.message);
        [osgiClient SubmitChatMessageForConversation:conv.conversationId message:conv.message withEntity:conv.entityId withTimestamp:[conv.createdDate longLongValue] withTempUrn:conv.tempUrn success:^(id JSON) {
            NSLog(@"Sent %@", conv.message);
            [JSMessageSoundEffect playMessageSentSound];
            conv.failedToSend = [NSNumber numberWithBool:NO];
            [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
            [unsentMessages removeObjectAtIndex:0];
            if(unsentMessages.count>0){
                [JCMessagesViewController sendOfflineMessagesQueue:osgiClient];
            }
            NSLog(@"Posted message with tempUrn: %@", conv.tempUrn);
        } failure:^(NSError *err, AFHTTPRequestOperation *operation) {
            NSLog(@"Failed to send message from offline queue: %@. With error:%@", conv.tempUrn,  err);
            if(operation.response.statusCode >=500 && unsentMessages.count>0){
                [JCMessagesViewController sendOfflineMessagesQueue:osgiClient];
            }
        }];
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
    
    if ([entities[0] isKindOfClass:[PersonEntities class]]) {
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
        self.imageViewNewMessage.hidden = YES;
        //conversationEntries = [NSMutableArray arrayWithArray:[ConversationEntry MR_findByAttribute:@"conversationId" withValue:_conversationId andOrderBy:@"lastModified" ascending:YES]];
        [self subscribeToConversationNotification:YES];
        [self setupDataSources];
        //[textView becomeFirstResponder];
    }
    else {
        self.imageViewNewMessage.hidden = NO;
        [self subscribeToConversationNotification:NO];
        _conversationId = nil;
        _selectedContacts = nil;
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
    
    [self enableSendButtonBasedOnSelectedContacts];
    
    [self checkForConversationWithEntities:self.selectedContacts];
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didRemoveContact:(id<MBContactPickerModelProtocol>)model
{
    NSLog(@"Did Remove: %@", model.contactTitle);
    
    PersonEntities *person = ((JCContactModel *)model).person;
    [self.selectedContacts removeObject:person];
    
    [self enableSendButtonBasedOnSelectedContacts];
}
//
//- (NSLayoutConstraint *)contactPickerViewHeightConstraint
//{
//    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint new];
//    heightConstraint.constant = 38.0f;
//    return heightConstraint;
//}

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

- (void)enableSendButtonBasedOnSelectedContacts
{
    if (self.messageInputView.sendButton && _messageType == JCNewConversation) {
        if (self.selectedContacts || _addedContacts) {
            if (self.selectedContacts.count > 0 || _addedContacts.count > 0) {
                self.hasMininumContacts = YES;
            }
            else {
                self.hasMininumContacts = NO;
            }
        }
        else {
            self.hasMininumContacts = NO;
        }
    }
    else {
        self.hasMininumContacts = YES;
    }
}


@end
