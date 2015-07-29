//
//  JCRecentEventsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/25/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentEventsTableViewController.h"

#import "JCMessageGroupsResultsController.h"
#import "JCConversationTableViewCell.h"
#import "Message.h"
#import "PBX.h"
#import "JCAuthenticationManager.h"
#import "JCStoryboardLoaderViewController.h"
#import "JCMessageGroup.h"

NSString *const kJCRecentEventConversationCellResuseIdentifier = @"ConversationCell";

@interface JCRecentEventsTableViewController () <JCFetchedResultsControllerDelegate>
{
    NSMutableArray *_tableData;
}

@property (nonatomic, strong) JCMessageGroupsResultsController *messageGroupsResultsController;
@property (nonatomic, strong) NSMutableArray *tableData;

@end

@implementation JCRecentEventsTableViewController

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    UIViewController *viewController = segue.destinationViewController;
    
    if ([viewController isKindOfClass:[JCStoryboardLoaderViewController class]]) {
        viewController = ((JCStoryboardLoaderViewController *)viewController).embeddedViewController;
    }
    
    if ([viewController isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *splitViewController = (UISplitViewController *)viewController;
        viewController = splitViewController.viewControllers.firstObject;
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController *)viewController;
            UIColor *barColor = navigationController.navigationBar.barTintColor;
            self.navigationController.navigationBar.barTintColor = barColor;
        }
    }
}

-(void)reloadTable
{
    _messageGroupsResultsController = nil;
    _tableData = nil;
    [super reloadTable];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    self.tableData = nil;
    self.messageGroupsResultsController = nil;
}

-(NSUInteger)count
{
    return self.tableData.count;
}

-(NSUInteger)numberOfSections
{
    return 1;
}

-(NSInteger)numberOfRowsInSection:(NSUInteger)section
{
    return self.count;
}

-(id <NSObject>)objectAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.tableData objectAtIndex:indexPath.row];
}

- (NSIndexPath *)indexPathOfObject:(id<NSObject>)object
{
    NSUInteger row = [self.tableData indexOfObject:object];
    return [NSIndexPath indexPathForRow:row inSection:0];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForObject:(id <NSObject>)object atIndexPath:(NSIndexPath*)indexPath;
{
    if ([object isKindOfClass:[JCMessageGroup class]])
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kJCRecentEventConversationCellResuseIdentifier];
        [self configureCell:cell withObject:object];
        return cell;
    }
    else
        return [super tableView:tableView cellForObject:object atIndexPath:indexPath];
}


- (void)configureCell:(UITableViewCell *)cell withObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[JCMessageGroup class]] && [cell isKindOfClass:[JCConversationTableViewCell class]])
    {
        JCMessageGroup *messageGroup = (JCMessageGroup *)object;
        JCConversationTableViewCell *conversationCell = (JCConversationTableViewCell *)cell;
        conversationCell.name.text    = messageGroup.titleText;
        conversationCell.detail.text  = messageGroup.detailText;
        conversationCell.date.text    = messageGroup.formattedModifiedShortDate;
        conversationCell.read         = messageGroup.isRead;
    }
    else
    {
        [super configureCell:cell withObject:object];
    }
}

-(NSIndexPath *)indexPathOfObject:(id<NSObject>)object relativeToIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = 0;
    
    return [NSIndexPath indexPathForRow:row inSection:indexPath.section];
}


#pragma mark - Getters -

/**
 * Lazy loads the full table data
 */
-(NSMutableArray *)tableData
{
    if (!_tableData) {
        _tableData = [NSMutableArray arrayWithArray:self.fetchedResultsController.fetchedObjects];
        [_tableData addObjectsFromArray:self.conversationGroupResultsController.fetchedObjects];
        [_tableData sortUsingDescriptors:self.fetchedResultsController.fetchRequest.sortDescriptors];
    }
    return _tableData;
}

-(JCMessageGroupsResultsController *)conversationGroupResultsController
{
    if (!_messageGroupsResultsController){
        PBX *pbx = self.authenticationManager.pbx;
        if (pbx && [pbx smsEnabled])
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"markForDeletion = %@", @NO];
            NSFetchRequest *fetchRequest = [Message MR_requestAllWithPredicate:predicate inContext:pbx.managedObjectContext];
            fetchRequest.includesSubentities = YES;
            fetchRequest.sortDescriptors = self.fetchedResultsController.fetchRequest.sortDescriptors;
            _messageGroupsResultsController = [[JCMessageGroupsResultsController alloc] initWithFetchRequest:fetchRequest pbx:pbx];
            _messageGroupsResultsController.delegate = self;
            
            __autoreleasing NSError *error = nil;
            if (![_messageGroupsResultsController performFetch:&error]) {
                NSLog(@"%@", error);
            };
        }
    }
    return _messageGroupsResultsController;
}

#pragma mark - Delegate Handlers -

#pragma mark UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self objectAtIndexPath:indexPath];
    if (self.delegate && [self.delegate respondsToSelector:@selector(recentEventController:didSelectObject:)]) {
        [self.delegate recentEventController:self didSelectObject:object];
    }
}

#pragma mark NSFetchedResultsControllerDelegate

-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // Override to do nothing.
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    NSMutableArray *tableData = self.tableData;
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
        {
            // Insert the object into where we are told its supposed to go, which may not be
            // correct. Then resort the array it to find the actual index it will be, and update the
            // table view to show the inserted cell at the right index path.
            [tableData addObject:anObject];
            [tableData sortUsingDescriptors:controller.fetchRequest.sortDescriptors];
            NSUInteger row = [tableData indexOfObject:anObject];
            newIndexPath = [NSIndexPath indexPathForRow:row inSection:newIndexPath.section];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationTop];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            if ([tableData containsObject:anObject]) {
                NSUInteger row = [tableData indexOfObject:anObject];
                [tableData removeObject:anObject];
                indexPath = [NSIndexPath indexPathForRow:row inSection:indexPath.section];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            break;
        }
        case NSFetchedResultsChangeUpdate:
        {
            if ([tableData containsObject:anObject]) {
                NSUInteger row = [tableData indexOfObject:anObject];
                indexPath = [NSIndexPath indexPathForRow:row inSection:indexPath.section];
                UITableViewCell *cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
                [self configureCell:cell atIndexPath:indexPath];
                
            }
            break;
        }
        case NSFetchedResultsChangeMove:
        {
            // In this case the anObject is a different object, but since the isEqual: compares
            // against the conversationGroupId, we are able to get the index of the object and
            // remove the old object because it is found in removeObject, which compares using the
            // isEqual: method.
            if ([tableData containsObject:anObject]) {
                NSUInteger deleteRow = [tableData indexOfObject:anObject];
                indexPath = [NSIndexPath indexPathForRow:deleteRow inSection:indexPath.section];
                [tableData removeObject:anObject];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            
            [tableData addObject:anObject];
            [tableData sortUsingDescriptors:controller.fetchRequest.sortDescriptors];
            NSUInteger newRow = [tableData indexOfObject:anObject];
            newIndexPath = [NSIndexPath indexPathForRow:newRow inSection:newIndexPath.section];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // Override to do nothing.
}

@end
