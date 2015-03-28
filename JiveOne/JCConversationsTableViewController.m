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
#import "LocalContact.h"
#import "JCAddressBook.h"

#import "JCConversationGroupsResultsController.h"
#import "JCConversationGroup.h"

NSString *const kJCConversationsTableViewController = @"ConversationCell";

@interface JCConversationsTableViewController () <JCConversationGroupsResultsControllerDelegate>

@property (nonatomic, strong) JCConversationGroupsResultsController *conversationGroupsResultsController;

@end

@implementation JCConversationsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PBX *pbx = [JCAuthenticationManager sharedInstance].pbx;
    if (pbx && [pbx smsEnabled]) {
        NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
        NSFetchRequest *fetchRequest = [Message MR_requestAllInContext:context];
        fetchRequest.includesSubentities = YES;
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(date)) ascending:NO]];
        _conversationGroupsResultsController = [[JCConversationGroupsResultsController alloc] initWithFetchRequest:fetchRequest pbx:pbx managedObjectContext:context];
        _conversationGroupsResultsController.delegate = self;
        
        __autoreleasing NSError *error = nil;
        if (![_conversationGroupsResultsController performFetch:&error]) {
            [self.tableView reloadData];
        };
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForObject:(id<NSObject>)object atIndexPath:(NSIndexPath *)indexPath {
    JCConversationTableViewCell *cell = (JCConversationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kJCConversationsTableViewController];
    [self configureCell:cell withObject:object];
    return cell;
}

-(id<NSObject>)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.conversationGroupsResultsController objectAtIndexPath:indexPath];
}

- (NSIndexPath *)indexPathOfObject:(id<NSObject>)object
{
    return [self.conversationGroupsResultsController indexPathForObject:object];
}

-(void)configureCell:(JCConversationTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [self configureCell:cell withObject:[self objectAtIndexPath:indexPath]];
    if([cell isKindOfClass:[JCTableViewCell class]])
    {
        JCTableViewCell *tableCell = (JCTableViewCell *)cell;
        if ((indexPath.row == 0 && indexPath.section == 0) && _showTopCellSeperator) {
            tableCell.top = true;
        }
    }
}

-(void)configureCell:(JCConversationTableViewCell *)cell withObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[JCConversationGroup class]]) {
        JCConversationGroup *group = (JCConversationGroup *)object;
        
        NSString *name = group.name;
        if (!name) {
            name = group.conversationGroupId.formattedPhoneNumber;
        }
        cell.name.text   = name;
        cell.detail.text = group.lastMessage;
        cell.date.text   = group.formattedModifiedShortDate;
        cell.read = group.isRead;
    }
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
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        UIViewController *viewController = segue.destinationViewController;
        if ([viewController isKindOfClass:[JCConversationViewController class]]) {
            JCConversationViewController *messagesViewController = (JCConversationViewController *)viewController;
            JCConversationGroup *conversationGroup = (JCConversationGroup *)[self objectAtIndexPath:[self.tableView indexPathForCell:sender]];
            messagesViewController.messageGroupId = conversationGroup.conversationGroupId;
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
}


@end
