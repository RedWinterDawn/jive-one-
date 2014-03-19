//
//  JCMessageViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCMessageViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "ClientEntities.h"
#import "Conversation+Custom.h"
#import "ConversationEntry+Custom.h"
#import "ContactGroup.h"
#import "JCOsgiClient.h"
#import "JCContactModel.h"

@interface JCMessageViewController ()
{
    UIView *containerView;
    HPGrowingTextView *textView;
    NSMutableArray *conversationEntries;
}

@property (nonatomic) NSArray *contacts;
@property (nonatomic) NSArray *messages;
@property (nonatomic) NSMutableArray *selectedContacts;
@property (weak, nonatomic) IBOutlet MBContactPicker *contactPickerView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contactPickerViewHeightConstraint;
@property (nonatomic) IBOutlet UITableView *tableView;



- (IBAction)resignFirstResponder:(id)sender;
- (IBAction)takeFirstResponder:(id)sender;
- (IBAction)enabledSwitched:(id)sender;
- (IBAction)completeDuplicatesSwitched:(id)sender;

@end

@implementation JCMessageViewController


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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
//    self.messages = @[
//                      @{@"Name":@"Bryan Reed", @"Title":@"Software Developer"},
//                      @{@"Name":@"Matt Bowman", @"Title":@"Software Developer"},
//                      @{@"Name":@"Matt Hupman", @"Title":@"Software Developer"},
//                      @{@"Name":@"Erica Stein", @"Title":@"Creative"},
//                      @{@"Name":@"Erin Pfiffner", @"Title":@"Creative"},
//                      @{@"Name":@"Ben McGinnis", @"Title":@"Project Manager"},
//                      @{@"Name":@"Lenny Pham", @"Title":@"Product Manager"},
//                      @{@"Name":@"Jason LaFollette", @"Title":@"Project Manager"},
//                      @{@"Name":@"Caleb Everist", @"Title":@"Business Development"},
//                      @{@"Name":@"Kinda long name for a kinda long", @"Title":@"Software Developer"},
//                      @{@"Name":@"Super long name for a super long person with a long name", @"Title":@"Software Developer"}
//                      ];
    
    
    
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
    
    self.contactPickerView.delegate = self;
    self.contactPickerView.datasource = self;
    self.contactPickerView.allowsCompletionOfSelectedContacts = NO;
    
    // setup message textview
    [self setup];
    
    double y = self.contactPickerView.hidden ? 0 : self.contactPickerView.frame.size.height;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, y, self.view.frame.size.width, self.view.frame.size.height - 55.0 - y) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view insertSubview:self.tableView belowSubview:self.contactPickerView];
    
    [self setupView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self subscribeToConversationNotification:NO];
}

- (void) setupView
{
    switch (_messageType) {
            
        case JCExistingConversation: {
            
            self.contactPickerView.hidden = YES;
            [self subscribeToConversationNotification:YES];
            conversationEntries = [NSMutableArray arrayWithArray:[ConversationEntry RetrieveConversationEntryById:_conversationId]];
            
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
            self.contactPickerView.hidden = YES;
            if (!self.selectedContacts) {
                self.selectedContacts = [[NSMutableArray alloc] init];
            }
            
            self.title = self.person.firstLastName;
            [self.selectedContacts addObject:self.person];
            [self checkForConversationWithEntities:self.selectedContacts];
            [textView becomeFirstResponder];
            
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
        [self takeFirstResponder:nil];
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
        [self resignFirstResponder:nil];
        //[self showContactPicker];
    }];
}

- (IBAction)toggleView:(id)sender
{
    if (self.contactPickerView.alpha == 0) {
        [self showContactPicker];
    }
    else {
        [self hideContactPicker];
    }
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
        conversationEntries = [NSMutableArray arrayWithArray:[ConversationEntry MR_findByAttribute:@"conversationId" withValue:_conversationId andOrderBy:@"lastModified" ascending:YES]];
        [self.tableView reloadData];
        [self scrollTableviewToBottom];
    }
}

#pragma mark - Send/Create Conversation
- (IBAction)sendMessage:(id)sender {
    
    NSString* entity = [[JCOmniPresence sharedInstance] me].urn;
    NSString *message = textView.text;
    
    // if conversation exists, then create entry for that conversation
    if (_conversationId != nil && ![_conversationId isEqualToString:@""]) {
        
        [[JCOsgiClient sharedClient] SubmitChatMessageForConversation:_conversationId message:message withEntity:entity success:^(id JSON) {
            // confirm to user message was sent
            textView.text = @"";
        } failure:^(NSError *err) {
            // alert user that message could not be sent. try again.
        }];
        
        //[self cleanup];
    }
    // otherwise, create a converstion first
    else {
        [self createConversation];
    }
}

- (void)createConversation
{
    BOOL isGroup = self.selectedContacts.count >= 2;
    NSArray *nameArray = [self.selectedContacts valueForKeyPath:@"firstLastName"];
    NSMutableArray *entityArray = [[NSMutableArray alloc] initWithArray:[self.selectedContacts valueForKeyPath:@"entityId"]];
    NSString *me = [[JCOmniPresence sharedInstance] me].entityId;
    [entityArray addObject:me];
    NSString *groupName = isGroup? [nameArray componentsJoinedByString:@", "] : @"";
    
    [[JCOsgiClient sharedClient] SubmitConversationWithName:groupName forEntities:entityArray creator:me isGroupConversation:isGroup success:^(id JSON) {
        
        // if conversation creation was successful, then subscribe for notifications to that conversationId
        _conversationId = JSON[@"id"];
        [self subscribeToConversationNotification:YES];
        
        // we can now add entries to the conversation recently created.
        [self sendMessage:nil];
        
    } failure:^(NSError *err) {
        // alert user that message could not be sent. try again.
        NSLog(@"%@", [err description]);
    }];
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
        if ([entitiesInConversation containsObject:[[JCOmniPresence sharedInstance] me].entityId]) {
            [entitiesInConversation removeObject:[[JCOmniPresence sharedInstance] me].entityId];
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
        conversationEntries = [NSMutableArray arrayWithArray:[ConversationEntry MR_findByAttribute:@"conversationId" withValue:_conversationId andOrderBy:@"lastModified" ascending:YES]];
        [self subscribeToConversationNotification:YES];
        [textView becomeFirstResponder];
    }
    else {
        [self subscribeToConversationNotification:NO];
        _conversationId = nil;
        [conversationEntries removeAllObjects];
        
    }
    
    [self.tableView reloadData];
}

#pragma mark - UIKeyboard Delegate
-(void) keyboardWillShow:(NSNotification *)note{
    // get keyboard size and loctaion
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    NSNumber *duration = [note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    // Need to translate the bounds to account for rotation.
    keyboardBounds = [self.view convertRect:keyboardBounds toView:nil];
    
    // get a rect for the textView frame
    CGRect containerFrame = containerView.frame;
    containerFrame.origin.y = self.view.bounds.size.height - (keyboardBounds.size.height + containerFrame.size.height);
    // animations settings
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
    
    // set views with new info
    containerView.frame = containerFrame;
    
    // adjust chat table size
    CGRect rect = self.tableView.frame;
    rect.size.height = self.tableView.frame.size.height - keyboardBounds.size.height - containerView.frame.size.height;
    self.tableView.frame = rect;
    
    // commit animations
    [UIView commitAnimations];
}

-(void) keyboardWillHide:(NSNotification *)note{
    
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    NSNumber *duration = [note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    // get a rect for the textView frame
    CGRect containerFrame = containerView.frame;
    containerFrame.origin.y = self.view.bounds.size.height - containerFrame.size.height;
    
    // animations settings
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
    
    // set views with new info
    containerView.frame = containerFrame;
    
    // adjust keyboard size
    CGRect rect = self.tableView.frame;
    rect.size.height = self.tableView.frame.size.height + keyboardBounds.size.height;
    self.tableView.frame = rect;
    
    // commit animations
    [UIView commitAnimations];
}


#pragma makr - HPTextview Setup / Delegate
- (void)setup
{
    //self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    //self.view.backgroundColor = [UIColor colorWithRed:219.0f/255.0f green:226.0f/255.0f blue:237.0f/255.0f alpha:1];
    
    containerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 40, 320, 40)];
    containerView.backgroundColor = [UIColor colorWithRed:219.0f/255.0f green:226.0f/255.0f blue:237.0f/255.0f alpha:1];
    
    textView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(6, 3, 240, 40)];
    textView.isScrollable = NO;
    textView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
    
    textView.minNumberOfLines = 1;
    textView.maxNumberOfLines = 6;
    // you can also set the maximum height in points with maxHeight
    // textView.maxHeight = 200.0f;
    textView.returnKeyType = UIReturnKeyGo; //just as an example
    textView.font = [UIFont systemFontOfSize:15.0f];
    textView.delegate = self;
    textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    textView.backgroundColor = [UIColor whiteColor];
    textView.placeholder = @"Message";
    
    // textView.text = @"test\n\ntest";
    // textView.animateHeightChange = NO; //turns off animation
    
    [self.view addSubview:containerView];
    
    UIImage *rawEntryBackground = [UIImage imageNamed:@"MessageEntryInputField.png"];
    UIImage *entryBackground = [rawEntryBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
    UIImageView *entryImageView = [[UIImageView alloc] initWithImage:entryBackground];
    entryImageView.frame = CGRectMake(5, 0, 248, 40);
    entryImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    UIImage *rawBackground = [UIImage imageNamed:@"MessageEntryBackground.png"];
    UIImage *background = [rawBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:background];
    imageView.frame = CGRectMake(0, 0, containerView.frame.size.width, containerView.frame.size.height);
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    // view hierachy
    [containerView addSubview:imageView];
    [containerView addSubview:textView];
    [containerView addSubview:entryImageView];
    
    UIImage *sendBtnBackground = [[UIImage imageNamed:@"MessageEntrySendButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:0];
    UIImage *selectedSendBtnBackground = [[UIImage imageNamed:@"MessageEntrySendButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:0];
    
    UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    doneBtn.frame = CGRectMake(containerView.frame.size.width - 69, 8, 63, 27);
    doneBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [doneBtn setTitle:@"Send" forState:UIControlStateNormal];
    
    [doneBtn setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.4] forState:UIControlStateNormal];
    doneBtn.titleLabel.shadowOffset = CGSizeMake (0.0, -1.0);
    doneBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
    
    [doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [doneBtn addTarget:self action:@selector(sendMessage:) forControlEvents:UIControlEventTouchUpInside];
    [doneBtn setBackgroundImage:sendBtnBackground forState:UIControlStateNormal];
    [doneBtn setBackgroundImage:selectedSendBtnBackground forState:UIControlStateSelected];
    [containerView addSubview:doneBtn];
    containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
    
    CGRect r = containerView.frame;
    r.size.height -= diff;
    r.origin.y += diff;
    containerView.frame = r;
}

- (void)growingTextViewDidBeginEditing:(HPGrowingTextView *)growingTextView
{
    [self scrollTableviewToBottom];
}

- (void)scrollTableviewToBottom
{
    if (self.tableView.contentSize.height > self.tableView.frame.size.height)
    {
        CGPoint offset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height);
        [self.tableView setContentOffset:offset animated:YES];
    }
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDatasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return conversationEntries.count;
}

#pragma mark - UITableViewDelegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Create first cell
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:14.0];
        cell.detailTextLabel.numberOfLines = 0;
        CGRect imageFrame = cell.imageView.frame;
        [cell.imageView setFrame:CGRectMake(imageFrame.origin.x, imageFrame.origin.y, 30, 30)];
    }
    
    // if we have a conversationId, the we load chat entries
    if (self.conversationId) {
        ConversationEntry *entry = conversationEntries[indexPath.row];
        NSArray* result = [ClientEntities MR_findByAttribute:@"entityId" withValue:entry.entityId];
        ClientEntities* person = (ClientEntities*)result[0];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@", person.firstLastName];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", entry.message[@"raw"]];
        [cell.imageView setImageWithURL:[NSURL URLWithString:person.picture]
                       placeholderImage:[UIImage imageNamed:@"avatar.png"]];
        cell.imageView.frame = CGRectInset(cell.imageView.bounds, 20, 20);
        
    }    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_conversationId) {
        
        ConversationEntry *entry = conversationEntries[indexPath.row];
        
        NSString *cellText = entry.message[@"raw"];
        UIFont *cellFont = [UIFont fontWithName:@"Helvetica" size:17.0];
        CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);
        
        NSAttributedString *attributedText = [[NSAttributedString alloc]
                                              initWithString:cellText
                                              attributes:@{NSFontAttributeName:cellFont}];
        CGRect rect = [attributedText boundingRectWithSize:constraintSize
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                   context:nil];
        
        CGSize labelSize = rect.size;
        
        return labelSize.height + 20;
    }
    else {
        return 44;
    }
}


#pragma mark - MBContactPickerDataSource

- (NSArray *)contactModelsForContactPicker:(MBContactPicker*)contactPickerView
{
    return self.contacts;
}

//- (NSArray *)selectedContactModelsForContactPicker:(MBContactPicker*)contactPickerView
//{
//    return self.selectedContacts;
//}

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

// This delegate method is called to allow hiding the keyboard on scrolling
//- (void)didScrollFilteredContactsForContactPicker:(MBContactPicker *)contactPicker
//{
//    [self.contactPickerView resignFirstResponder];
//    [textView resignFirstResponder];
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


- (IBAction)takeFirstResponder:(id)sender
{
    [self.contactPickerView becomeFirstResponder];
}

- (IBAction)resignFirstResponder:(id)sender
{
    [self.contactPickerView resignFirstResponder];
}

- (IBAction)enabledSwitched:(id)sender
{
    self.contactPickerView.enabled = ((UISwitch *)sender).isOn;
}

- (IBAction)completeDuplicatesSwitched:(id)sender
{
    self.contactPickerView.allowsCompletionOfSelectedContacts = ((UISwitch *)sender).isOn;
}
@end
