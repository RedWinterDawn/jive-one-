//
//  JCConversationsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationsTableViewController.h"

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
}

@property (nonatomic, strong) JCMessageGroupsResultsController *messageGroupsResultsController;

@end

@implementation JCConversationsTableViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    JCAuthenticationManager *authenticationManager = self.authenticationManager;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(reloadTable:) name:kJCAuthenticationManagerLineChangedNotification object:authenticationManager];
    [center addObserver:self selector:@selector(reloadTable:) name:kJCAuthenticationManagerUserLoggedOutNotification object:authenticationManager];
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
    
    PBX *pbx = self.authenticationManager.pbx;
    if (pbx && [pbx smsEnabled]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"markForDeletion = %@", @NO];
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
        PBX *pbx = self.authenticationManager.pbx;
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


    

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if([viewController isKindOfClass:[UINavigationController class]])
        viewController = ((UINavigationController *)viewController).topViewController;
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        if ([viewController isKindOfClass:[JCConversationViewController class]]) {
            JCConversationViewController *messagesViewController = (JCConversationViewController *)viewController;
            JCMessageGroup *messageGroup = (JCMessageGroup *)[self objectAtIndexPath:[self.tableView indexPathForCell:sender]];
            messagesViewController.conversationGroup = messageGroup;
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
    PBX *pbx = self.authenticationManager.pbx;
    JCMessageGroup *object = [self objectAtIndexPath:indexPath];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if ([object isKindOfClass:[JCSMSConversationGroup class]]) {
            JCSMSConversationGroup *conversationGroup = (JCSMSConversationGroup *)object;
            NSString *identifier = conversationGroup.conversationGroupId;
            PBX *pbx = self.authenticationManager.pbx;
            [SMSMessage markSMSMessagesWithGroupIdForDeletion:identifier pbx:pbx completion:NULL];
            if(pbx.managedObjectContext.hasChanges) {
                [pbx.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kSMSMessagesDidUpdateNotification object:nil];
                }];
            }
        }
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
            JCConversationTableViewCell *cell = (JCConversationTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            [self configureCell:cell atIndexPath:indexPath];
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
