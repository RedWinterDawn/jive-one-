//
//  JCConversationsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationsTableViewController.h"

#import <JCPhoneModule/JCProgressHUD.h>

// Models
#import "PBX.h"
#import "BlockedNumber+V5Client.h"
#import "SMSMessage+V5Client.h"

// Views
#import "JCConversationTableViewCell.h"

// Controllers
#import "JCConversationViewController.h"
#import "JCMessageParticipantTableViewController.h"
#import "JCNavigationController.h"
#import "JCMessageGroupsResultsController.h"

NSString *const kJCConversationsTableViewController = @"ConversationCell";

@interface JCConversationsTableViewController () <JCFetchedResultsControllerDelegate, JCConversationTableViewCellDelegate>
{
    JCMessageGroup *_selectedConversationGroup;
    NSIndexPath *_selectedIndexPath;
    
    UIBarButtonItem *_defaultLeftNavigationItem;
    UIBarButtonItem *_defaultRightNavigationItem;
    UIBarButtonItem *_readBarButtonItem;
    BOOL _batchEdit;
}

@property (nonatomic, strong) JCMessageGroupsResultsController *messageGroupsResultsController;

@end

@implementation JCConversationsTableViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Setup long press gesture recognizer on the table view to trigger edit mode.
    self.tableView.allowsMultipleSelectionDuringEditing = TRUE;
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(enterEditMode:)];
    longPressGestureRecognizer.minimumPressDuration = 1.0;
    [self.tableView addGestureRecognizer:longPressGestureRecognizer];
    
    // Save pointers to the default navigation items.
    _defaultLeftNavigationItem = self.navigationItem.leftBarButtonItem;
    _defaultRightNavigationItem = self.navigationItem.rightBarButtonItem;
    
    // Register for authentication manager changes.
    JCUserManager *authenticationManager = self.userManager;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(reloadTable:) name:kJCAuthenticationManagerLineChangedNotification object:authenticationManager];
    [center addObserver:self selector:@selector(reloadTable:) name:kJCAuthenticationManagerUserLoggedOutNotification object:authenticationManager];
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (_batchEdit) {
        if (editing) {
            
            UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            
            _readBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Read All", nil)
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(markMessagesAsRead:)];
            
            UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Delete", nil)
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(deleteMessages:)];
            
            [self setToolbarItems:@[_readBarButtonItem, flexItem, barButtonItem]];
            [self.navigationController setToolbarHidden:NO animated:animated];
            
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                  target:self
                                                                                                  action:@selector(cancelEdit:)];
            self.navigationItem.rightBarButtonItem = nil;
            
        } else {
            [self.navigationController setToolbarHidden:YES animated:animated];
            
            self.navigationItem.leftBarButtonItem = _defaultLeftNavigationItem;
            self.navigationItem.rightBarButtonItem = _defaultRightNavigationItem;
        }
    }
    [super setEditing:editing animated:animated];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Getters -

-(JCMessageGroupsResultsController *)messageGroupsResultsController
{
    if (_messageGroupsResultsController) {
        return _messageGroupsResultsController;
    }
    
    PBX *pbx = self.userManager.pbx;
    if (pbx && [pbx smsEnabled]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"markForDeletion = %@ AND pbxId = %@", @NO, pbx.pbxId];
        NSFetchRequest *fetchRequest = [Message MR_requestAllWithPredicate:predicate inContext:pbx.managedObjectContext];
        fetchRequest.includesSubentities = YES;
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(date)) ascending:NO]];
        _messageGroupsResultsController = [[JCMessageGroupsResultsController alloc] initWithFetchRequest:fetchRequest pbx:pbx];
        _messageGroupsResultsController.delegate = self;
        
        __autoreleasing NSError *error = nil;
        [_messageGroupsResultsController performFetch:&error];
    }
    return _messageGroupsResultsController;
}

#pragma mark - IBActions -

- (IBAction)update:(id)sender
{
    if ([sender isKindOfClass:[UIRefreshControl class]]) {
        PBX *pbx = self.userManager.pbx;
        [SMSMessage downloadMessagesDigestForDIDs:pbx.dids completion:^(BOOL success, NSError *error) {
            [((UIRefreshControl *)sender) endRefreshing];
            if (!success) {
                [self showError:error];
            }
        }];
    }
}

- (IBAction)clear:(id)sender
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        [SMSMessage MR_truncateAllInContext:localContext];
    } completion:^(BOOL success, NSError *error) {
        [self.tableView reloadData];
    }];
}

- (IBAction)cancelEdit:(id)sender
{
    [self setEditing:NO animated:YES];
    _batchEdit = NO;
}

- (IBAction)deleteMessages:(id)sender
{
    PBX *pbx = self.userManager.pbx;
    NSArray *messageIndexPaths = [self.tableView indexPathsForSelectedRows];
    NSMutableArray *objects = [NSMutableArray new];
    if (messageIndexPaths.count > 0) {
        for (NSIndexPath *indexPath in messageIndexPaths) {
            JCMessageGroup *messageGroup = [self objectAtIndexPath:indexPath];
            [objects addObject:messageGroup.groupId];
        }
    }
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        PBX *localPbx = (PBX *)[localContext objectWithID:pbx.objectID];
        for (NSString *messageGroupId in objects) {
            [SMSMessage markSMSMessagesWithGroupIdForDeletion:messageGroupId
                                                          pbx:localPbx
                                                   completion:NULL];
        }
    }];
}

- (IBAction)markMessagesAsRead:(id)sender
{
    PBX *pbx = self.userManager.pbx;
    NSArray *messageIndexPaths = [self.tableView indexPathsForSelectedRows];
    NSMutableArray *objects = [NSMutableArray new];
    if (messageIndexPaths.count > 0) {
        for (NSIndexPath *indexPath in messageIndexPaths) {
            JCMessageGroup *object = [self objectAtIndexPath:indexPath];
            [objects addObject:object.groupId];
        }
    }
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        PBX *localPbx = (PBX *)[localContext objectWithID:pbx.objectID];
        for (NSString *conversationGroupId in objects) {
            [SMSMessage markSMSMessagesWithGroupIdAsRead:conversationGroupId
                                                     pbx:localPbx
                                              completion:NULL];
        }
    }];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if (self.isEditing) {
        return NO;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if([viewController isKindOfClass:[UINavigationController class]])
        viewController = ((UINavigationController *)viewController).topViewController;
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        if ([viewController isKindOfClass:[JCConversationViewController class]]) {
            JCConversationViewController *messagesViewController = (JCConversationViewController *)viewController;
            JCMessageGroup *messageGroup = (JCMessageGroup *)[self objectAtIndexPath:[self.tableView indexPathForCell:sender]];
            messagesViewController.messageGroup = messageGroup;
        }
    }
}

#pragma mark - Delegate Handlers -

#pragma mark UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messageGroupsResultsController.fetchedObjects.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JCMessageGroup *object = (JCMessageGroup *)[self objectAtIndexPath:indexPath];
    UITableViewCell *cell = [self tableView:tableView cellForObject:object atIndexPath:indexPath];
    if([cell isKindOfClass:[JCTableViewCell class]])
    {
        JCTableViewCell *tableCell = (JCTableViewCell *)cell;
        if ((indexPath.row == 0 && indexPath.section == 0) && _showTopCellSeperator) {
            tableCell.top = true;
        }
    }
    return cell;
}

-(BOOL)tableView:tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    PBX *pbx = self.userManager.pbx;
    JCMessageGroup *object = [self objectAtIndexPath:indexPath];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            [SMSMessage markSMSMessagesWithGroupIdForDeletion:object.groupId
                                                          pbx:(PBX *)[localContext objectWithID:pbx.objectID]
                                                   completion:NULL];
        } completion:^(BOOL contextDidSave, NSError *error) {
            
        }];
    }
}

#pragma mark JCConversationGroupResultsControllerDelegate

-(void)controllerWillChangeContent:(JCMessageGroupsResultsController *)controller
{
    [self.tableView beginUpdates];
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        _selectedIndexPath = self.tableView.indexPathForSelectedRow;
        _selectedConversationGroup = [self objectAtIndexPath:_selectedIndexPath];
    }
}

-(void)controller:(JCMessageGroupsResultsController *)controller
                          didChangeObject:(id)anObject
                              atIndexPath:(NSIndexPath *)indexPath
                            forChangeType:(NSFetchedResultsChangeType)type
                             newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationTop];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
        {
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        NSIndexPath *indexPath = [self indexPathOfObject:_selectedConversationGroup];
        UITableViewScrollPosition scrollPosition = ![_selectedIndexPath isEqual:indexPath] ? UITableViewScrollPositionTop : UITableViewScrollPositionNone;
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:scrollPosition];
        _selectedIndexPath = nil;
        _selectedConversationGroup = nil;
    }
}

#pragma mark JCConversationTableViewControllerDelegate

-(void)didBlockConverastionTableViewCell:(JCConversationTableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    JCMessageGroup *messageGroup = (JCMessageGroup *)[self objectAtIndexPath:indexPath];
    Message *message = messageGroup.latestMessage;
    if (![message isKindOfClass:[SMSMessage class]]) {
        return;
    }
    
    SMSMessage *smsMessage = (SMSMessage *)message;
    [BlockedNumber blockNumber:messageGroup.phoneNumber did:smsMessage.did completion:NULL];
}

#pragma mark - Private -

-(UITableViewCell *)tableView:(UITableView *)tableView cellForObject:(JCMessageGroup *)object atIndexPath:(NSIndexPath *)indexPath {
    JCConversationTableViewCell *cell = (JCConversationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kJCConversationsTableViewController];
    cell.delegate = self;
    [self configureCell:cell withObject:object];
    return cell;
}

-(void)reloadTable:(NSNotification *)notification {
    _messageGroupsResultsController = nil;
    [self.tableView reloadData];
}

-(JCMessageGroup *)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.messageGroupsResultsController objectAtIndexPath:indexPath];
}

- (NSIndexPath *)indexPathOfObject:(JCMessageGroup *)messageGroup
{
    return [self.messageGroupsResultsController indexPathForObject:messageGroup];
}

-(void)configureCell:(JCConversationTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    JCMessageGroup *messageGroup = (JCMessageGroup *)[self objectAtIndexPath:indexPath];
    [self configureCell:cell withObject:messageGroup];
    if([cell isKindOfClass:[JCTableViewCell class]])
    {
        JCTableViewCell *tableCell = (JCTableViewCell *)cell;
        if ((indexPath.row == 0 && indexPath.section == 0) && _showTopCellSeperator) {
            tableCell.top = true;
        }
    }
}

-(void)configureCell:(JCConversationTableViewCell *)cell withObject:(JCMessageGroup *)messageGroup
{
    cell.name.text   = messageGroup.titleText;
    cell.detail.text = messageGroup.detailText;
    cell.date.text   = messageGroup.formattedModifiedShortDate;
    cell.read        = messageGroup.isRead;
}

-(void)enterEditMode:(UILongPressGestureRecognizer *)longPressGestureRecognizer
{
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (!self.editing) {
            _batchEdit = TRUE;
            [self setEditing:YES animated:YES];
        }
    }
}

@end
