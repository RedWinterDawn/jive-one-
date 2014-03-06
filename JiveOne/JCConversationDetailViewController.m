//
//  JCChatDetailViewController.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationDetailViewController.h"
#import "ClientEntities.h"
#import "JCEntryModel.h"
#import "JCSocketDispatch.h"
#import "JCOsgiClient.h"
#import "JCChatMessage.h"
#import "UIImageView+WebCache.h"
#import "ConversationEntry.h"


@interface JCConversationDetailViewController ()
{
    ClientEntities *me;
    UITextView *messageTextView;
    NSMutableArray *chatEntries;
    BOOL keyboardIsVisible;
}

@end

@implementation JCConversationDetailViewController

#define kKeyboardHeight 216.0


- (void)setConversationId:(NSString *)conversationId
{
    if (!_conversationId || ![_conversationId isEqualToString:conversationId]) {
        _conversationId = conversationId;
        //[self loadDatasource];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //self.edgesForExtendedLayout = UIRectEdgeNone;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    me = [[JCOmniPresence sharedInstance] me];
    self.contacts = [ClientEntities MR_findAllSortedBy:@"firstLastName" ascending:YES];
    self.selectedContacts = [NSMutableArray array];
    self.filteredContacts = self.contacts;
    
    messageTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 35)];
    messageTextView.delegate = self;
    UIBarButtonItem *messageBarItemTextView = [[UIBarButtonItem alloc] initWithCustomView:messageTextView];
    UIBarButtonItem *sendBarItemButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleBordered target:self action:@selector(sendMessage:)];
    //UIBarButtonItem *fileBarItemButton = [[UIBarButtonItem alloc] initWithTitle:@"File" style:UIBarButtonItemStyleBordered target:self action:nil];
    
    [self setToolbarItems:[NSArray arrayWithObjects:messageBarItemTextView, sendBarItemButton, nil]];
    
    if (!_conversationId) {
        // Initialize and add Contact Picker View
        self.contactPickerView = [[THContactPickerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
        self.contactPickerView.delegate = self;
        //UIToolbar *toobar = self.navigationController.toolbar;
        //self.contactPickerView.textView.inputAccessoryView = toobar;
        [self.contactPickerView setPlaceholderString:@"To:"];
        //[self.contactPickerView.textView becomeFirstResponder];
        
        [self.view insertSubview:self.contactPickerView belowSubview:self.navigationController.toolbar];
        
        // Fill the rest of the view with the table view
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                       self.contactPickerView.frame.size.height,
                                                                       self.view.frame.size.width,
                                                                       self.view.frame.size.height - self.contactPickerView.frame.size.height - kKeyboardHeight) style:UITableViewStylePlain];
    }
    else
    {
        
        NSLog(@"View Width: %f", self.view.frame.size.width);
        NSLog(@"View Height: %f", self.view.frame.size.height);
        
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        chatEntries = [NSMutableArray arrayWithArray:[ConversationEntry MR_findByAttribute:@"conversationId" withValue:_conversationId andOrderBy:@"lastModified" ascending:YES]];
        
        
        NSLog(@"Table Width: %f", self.tableView.frame.size.width);
        NSLog(@"Table Width: %f", self.tableView.frame.size.height);
    }
    
    UIEdgeInsets inset = UIEdgeInsetsMake(64, 0, 0, 0);
    self.tableView.contentInset = inset;
    self.tableView.scrollIndicatorInsets = inset;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    if (!_conversationId) {
        [self.view insertSubview:self.tableView belowSubview:self.contactPickerView];
    }
    else {
        [self.view addSubview:self.tableView];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_conversationId) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingChatEntry:) name:_conversationId object:nil];
    }
    
    //self.navigationController.tabBarController.tabBar.hidden = YES;
    self.navigationController.toolbarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (_conversationId) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:_conversationId object:nil];
    }
    
    self.navigationController.tabBarController.tabBar.hidden = NO;
    self.navigationController.toolbarHidden = YES;
}

- (void) keyboardWillShow: (NSNotification *)notification
{
    UIViewAnimationCurve animationCurve = [[[notification userInfo] valueForKey: UIKeyboardAnimationCurveUserInfoKey] intValue];
    NSTimeInterval animationDuration = [[[notification userInfo] valueForKey: UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardBounds = [(NSValue *)[[notification userInfo] objectForKey: UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    [UIView beginAnimations:nil context: nil];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    UIToolbar *toolbar = self.navigationController.toolbar;
    if (!keyboardIsVisible) {
        [toolbar setFrame:CGRectMake(0.0f, self.view.frame.size.height - keyboardBounds.size.height - toolbar.frame.size.height, toolbar.frame.size.width, toolbar.frame.size.height)];
    }
    
    [UIView commitAnimations];
    keyboardIsVisible = YES;
    
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    UIViewAnimationCurve animationCurve = [[[notification userInfo] valueForKey: UIKeyboardAnimationCurveUserInfoKey] intValue];
    NSTimeInterval animationDuration = [[[notification userInfo] valueForKey: UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    //CGRect keyboardBounds = [(NSValue *)[[notification userInfo] objectForKey: UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    [UIView beginAnimations:nil context: nil];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    UIToolbar *toolbar = self.navigationController.toolbar;
    if (keyboardIsVisible) {
        [toolbar setFrame:CGRectMake(0.0f, self.view.frame.size.height - 46.0f, toolbar.frame.size.width, toolbar.frame.size.height)];
    }
    
    [UIView commitAnimations];
    keyboardIsVisible = NO;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat topOffset = 0;
    if ([self respondsToSelector:@selector(topLayoutGuide)]){
        topOffset = self.topLayoutGuide.length;
    }
    CGRect frame = self.contactPickerView.frame;
    frame.origin.y = topOffset;
    self.contactPickerView.frame = frame;
    [self adjustTableViewFrame];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)adjustTableViewFrame {
    if (!_conversationId) {
        
        CGRect frame = self.tableView.frame;
        frame.origin.y = self.contactPickerView.frame.size.height;
        frame.size.height = self.view.frame.size.height - self.contactPickerView.frame.size.height - kKeyboardHeight;
        self.tableView.frame = frame;
    }
}

#pragma mark - Incoming chat
- (void)incomingChatEntry:(NSNotification*)notification
{
    if (_conversationId) {
        chatEntries = [NSMutableArray arrayWithArray:[ConversationEntry MR_findByAttribute:@"conversationId" withValue:_conversationId andOrderBy:@"lastModified" ascending:YES]];
        [self.tableView reloadData];
    }
}

#pragma mark - Send/Create Conversation
- (IBAction)sendMessage:(id)sender {
    
    NSString* entity = me.urn;
    NSString *message = messageTextView.text;
    
    // if conversation exists, then create entry for that conversation
    //
    if (_conversationId != nil && ![_conversationId isEqualToString:@""]) {
        
        [[JCOsgiClient sharedClient] SubmitChatMessageForConversation:_conversationId message:message withEntity:entity success:^(id JSON) {
            // update UI
        } failure:^(NSError *err) {
            // update UI
        }];
    }
    else {
        [self createConversation];
    }
    [self cleanup];
}

- (void)createConversation
{
    BOOL isGroup = self.selectedContacts.count > 2;
    NSArray *nameArray = [self.selectedContacts valueForKeyPath:@"firstLastName"];
    NSMutableArray *entityArray = [[NSMutableArray alloc] initWithArray:[self.selectedContacts valueForKeyPath:@"entityId"]];
    [entityArray addObject:me.entityId];
    NSString *groupName = isGroup? [nameArray componentsJoinedByString:@", "] : @"";
    
    [[JCOsgiClient sharedClient] SubmitConversationWithName:groupName forEntities:entityArray creator:me.urn isGroupConversation:isGroup success:^(id JSON) {
        _conversationId = JSON[@"id"];
        if (_conversationId) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingChatEntry:) name:_conversationId object:nil];
        }
        [self sendMessage:nil];
    } failure:^(NSError *err) {
        NSLog(@"%@", [err description]);
    }];
}

#pragma mark - UITableView Delegate and Datasource functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_conversationId) {
        return chatEntries.count;
    }
    else {
        return self.filteredContacts.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"ContactCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    if (self.conversationId) {
        ConversationEntry *entry = chatEntries[indexPath.row];
        NSArray* result = [ClientEntities MR_findByAttribute:@"entityId" withValue:entry.entityId];
        ClientEntities* person = (ClientEntities*)result[0];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@", entry.message[@"raw"]];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", person.firstLastName];
    }
    else {
        ClientEntities *user = [self.filteredContacts objectAtIndex:indexPath.row];
        
        cell.textLabel.text = user.firstLastName;
        
        if ([self.selectedContacts containsObject:[self.filteredContacts objectAtIndex:indexPath.row]]){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (!_conversationId) {
        
        ClientEntities *user = [self.filteredContacts objectAtIndex:indexPath.row];
        
        if ([self.selectedContacts containsObject:user]) { // contact is already selected so remove it from ContactPickerView
            cell.accessoryType = UITableViewCellAccessoryNone;
            [self.selectedContacts removeObject:user];
            [self.contactPickerView removeContact:user];
        } else {
            // Contact has not been selected, add it to THContactPickerView
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [self.selectedContacts addObject:user];
            [self.contactPickerView addContact:user withName:user.firstLastName];
        }
        
        self.filteredContacts = self.contacts;
        [self.tableView reloadData];
        [self checkForConversationWithEntities:self.selectedContacts];
    }
}

#pragma mark - THContactPickerTextViewDelegate
- (void)contactPickerDidBecomeFirstResponder:(UITextView *)textView
{
    if (_conversationId) {
        _conversationId = nil;
        [self.tableView reloadData];
    }
    
}

- (void)contactPickerTextViewDidChange:(NSString *)textViewText {
    if ([textViewText isEqualToString:@""]){
        self.filteredContacts = self.contacts;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstLastName contains[cd] %@", textViewText];
        self.filteredContacts = [self.contacts filteredArrayUsingPredicate:predicate];
    }
    [self.tableView reloadData];
}

- (void)contactPickerDidResize:(THContactPickerView *)contactPickerView {
    [self adjustTableViewFrame];
}

- (void)contactPickerDidRemoveContact:(id)contact {
    [self.selectedContacts removeObject:contact];
    
    int index = [self.contacts indexOfObject:contact];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (self.selectedContacts.count == 0) {
        _conversationId = nil;
        [self.tableView reloadData];
    }
}

- (void)removeAllContacts:(id)sender
{
    [self.contactPickerView removeAllContacts];
    [self.selectedContacts removeAllObjects];
    self.filteredContacts = self.contacts;
    _conversationId = nil;
    [self.tableView reloadData];
}

#pragma mark - Conversation Loading
- (void)checkForConversationWithEntities:(NSMutableArray*)entities
{
    NSArray *entityArray = [entities valueForKeyPath:@"entityId"];
    //    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"entities IN %@", entityArray];
    //
    //    NSArray *result = [Conversation MR_findAllWithPredicate:predicate];
    //
    //        if (result.count > 0) {
    //            Conversation *conversation = result[0];
    //            NSLog(@"%@",conversation.conversationId);
    //        }
    
    Conversation *existingConversation = nil;
    NSArray *conversations = [Conversation MR_findAll];
    for (Conversation *conv in conversations) {
        NSMutableSet *convEntities = [NSMutableSet setWithArray:(NSArray*)conv.entities];
        [convEntities intersectSet:[NSMutableSet setWithArray:entityArray]];
        
        if (convEntities.count != 0 && convEntities.count == entityArray.count) {
            NSLog(@"found");
            existingConversation = conv;
            break;
        }
    }
    
    if (existingConversation) {
        _conversationId = existingConversation.conversationId;
        chatEntries = [NSMutableArray arrayWithArray:[ConversationEntry MR_findByAttribute:@"conversationId" withValue:_conversationId andOrderBy:@"lastModified" ascending:YES]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingChatEntry:) name:_conversationId object:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:_conversationId object:nil];
        _conversationId = nil;
        [chatEntries removeAllObjects];
        
    }
    
    [messageTextView becomeFirstResponder];
    [self.tableView reloadData];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    CGRect frame = messageTextView.frame;
    frame.size.height = messageTextView.contentSize.height;
    messageTextView.frame = frame;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if (!_conversationId) {
        _conversationId = @"";
    }
    [self.tableView reloadData];
}

- (void)cleanup
{
    messageTextView.text = @"";
    if (self.contactPickerView) {
        self.contactPickerView.hidden = YES;
        self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    }
}
@end
