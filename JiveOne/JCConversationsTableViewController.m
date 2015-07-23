//
//  JCConversationsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationsTableViewController.h"

#import "JCConversationViewController.h"
#import "JCMessageParticipantTableViewController.h"
#import "Message.h"
#import "JCNavigationController.h"
#import "JCConversationTableViewCell.h"
#import "SMSMessage+V5Client.h"
#import "PhoneNumber.h"

#import "Line.h"
#import "PBX.h"
#import "BlockedNumber+V5Client.h"
#import "JCSMSConversationGroup.h"

#import "JCConversationGroupsResultsController.h"

NSString *const kJCConversationsTableViewController = @"ConversationCell";

@interface JCConversationsTableViewController () <JCConversationGroupsResultsControllerDelegate, JCConversationTableViewCellDelegate>
{
    id<JCConversationGroupObject> _selectedConversationGroup;
    NSIndexPath *_selectedIndexPath;
}

@property (nonatomic, strong) JCConversationGroupsResultsController *conversationGroupsResultsController;

@end

@implementation JCConversationsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    JCAuthenticationManager *authenticationManager = [JCAuthenticationManager sharedInstance];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(reloadTable:) name:kJCAuthenticationManagerLineChangedNotification object:authenticationManager];
    [center addObserver:self selector:@selector(reloadTable:) name:kJCAuthenticationManagerUserLoggedOutNotification object:authenticationManager];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(JCConversationGroupsResultsController *)conversationGroupsResultsController
{
    if (_conversationGroupsResultsController) {
        return _conversationGroupsResultsController;
    }
    
    PBX *pbx = self.authenticationManager.pbx;
    if (pbx && [pbx smsEnabled]) {
        NSFetchRequest *fetchRequest = [Message MR_requestAllInContext:pbx.managedObjectContext];
        fetchRequest.includesSubentities = YES;
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(date)) ascending:NO]];
        _conversationGroupsResultsController = [[JCConversationGroupsResultsController alloc] initWithFetchRequest:fetchRequest pbx:pbx];
        _conversationGroupsResultsController.delegate = self;
        
        __autoreleasing NSError *error = nil;
        [_conversationGroupsResultsController performFetch:&error];
    }
    return _conversationGroupsResultsController;
}

-(void)reloadTable:(NSNotification *)notification {
    _conversationGroupsResultsController = nil;
    [self.tableView reloadData];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForObject:(id<JCConversationGroupObject>)object atIndexPath:(NSIndexPath *)indexPath {
    JCConversationTableViewCell *cell = (JCConversationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kJCConversationsTableViewController];
    cell.delegate = self;
    [self configureCell:cell withObject:object];
    return cell;
}

-(id<JCConversationGroupObject>)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.conversationGroupsResultsController objectAtIndexPath:indexPath];
}

- (NSIndexPath *)indexPathOfObject:(id<JCConversationGroupObject>)object
{
    return [self.conversationGroupsResultsController indexPathForObject:object];
}

-(void)configureCell:(JCConversationTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    id<JCConversationGroupObject> object = [self objectAtIndexPath:indexPath];
    [self configureCell:cell withObject:object];
    if([cell isKindOfClass:[JCTableViewCell class]])
    {
        JCTableViewCell *tableCell = (JCTableViewCell *)cell;
        if ((indexPath.row == 0 && indexPath.section == 0) && _showTopCellSeperator) {
            tableCell.top = true;
        }
    }
}

-(void)configureCell:(JCConversationTableViewCell *)cell withObject:(id<JCConversationGroupObject>)object
{
    cell.name.text   = object.titleText;
    cell.detail.text = object.detailText;
    cell.date.text   = object.formattedModifiedShortDate;
    cell.read        = object.isRead;
    //cell.imageView.image = [UIImage imageNamed:@"avatar"];
}

- (IBAction)refreshTable:(id)sender {
    if ([sender isKindOfClass:[UIRefreshControl class]]) {
        PBX *pbx = [JCAuthenticationManager sharedInstance].pbx;
        [SMSMessage downloadMessagesDigestForDIDs:pbx.dids completion:^(BOOL success, NSError *error) {
            [((UIRefreshControl *)sender) endRefreshing];
            if (!success) {
                [self showError:error];
            }
        }];
    }
}

- (IBAction)clear:(id)sender {
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        [SMSMessage MR_truncateAllInContext:localContext];
    } completion:^(BOOL success, NSError *error) {
        [self.tableView reloadData];
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    UIViewController *viewController = segue.destinationViewController;
    if([viewController isKindOfClass:[UINavigationController class]])
        viewController = ((UINavigationController *)viewController).topViewController;
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        if ([viewController isKindOfClass:[JCConversationViewController class]]) {
            JCConversationViewController *messagesViewController = (JCConversationViewController *)viewController;
            id<JCConversationGroupObject> conversationGroup = (id<JCConversationGroupObject>)[self objectAtIndexPath:[self.tableView indexPathForCell:sender]];
            messagesViewController.conversationGroup = conversationGroup;
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
    return self.conversationGroupsResultsController.fetchedObjects.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self objectAtIndexPath:indexPath];
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

#pragma mark NSFetchedResultsControllerDelegate

-(void)conversationGroupResultsControllerWillChangeContent:(JCConversationGroupsResultsController *)controller
{
    [self.tableView beginUpdates];
    _selectedIndexPath = self.tableView.indexPathForSelectedRow;
    _selectedConversationGroup = [self objectAtIndexPath:_selectedIndexPath];
}

-(void)conversationGroupResultsController:(JCConversationGroupsResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(JCConversationGroupsResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
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
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

-(void)conversationGroupResultsControllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    
    NSIndexPath *indexPath = [self indexPathOfObject:_selectedConversationGroup];
    UITableViewScrollPosition scrollPosition = ![_selectedIndexPath isEqual:indexPath] ? UITableViewScrollPositionTop : UITableViewScrollPositionNone;
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:scrollPosition];
    _selectedIndexPath = nil;
    _selectedConversationGroup = nil;
}

-(void)didBlockConverastionTableViewCell:(JCConversationTableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    id<JCConversationGroupObject> conversationGroup = [self objectAtIndexPath:indexPath];
    if ([conversationGroup isKindOfClass:[JCSMSConversationGroup class]]) {
        DID *did = [DID MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:((JCSMSConversationGroup *)conversationGroup).didJrn];
        [BlockedNumber blockNumber:conversationGroup did:did completion:NULL];
    }
}

@end
