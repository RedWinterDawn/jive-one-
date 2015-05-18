//
//  JCRecentEventsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/25/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentEventsTableViewController.h"

#import "JCConversationGroupsResultsController.h"
#import "JCConversationTableViewCell.h"
#import "Message.h"
#import "PBX.h"
#import "JCAuthenticationManager.h"
#import "JCStoryboardLoaderViewController.h"

NSString *const kJCRecentEventConversationCellResuseIdentifier = @"ConversationCell";

@interface JCRecentEventsTableViewController () <JCConversationGroupsResultsControllerDelegate>
{
    NSMutableArray *_tableData;
}

@property (nonatomic, strong) JCConversationGroupsResultsController *conversationGroupsResultsController;
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
    _conversationGroupsResultsController = nil;
    _tableData = nil;
    [super reloadTable];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    self.tableData = nil;
    self.conversationGroupsResultsController = nil;
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
    if ([object conformsToProtocol:@protocol(JCConversationGroupObject)])
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
    if ([object conformsToProtocol:@protocol(JCConversationGroupObject)] && [cell isKindOfClass:[JCConversationTableViewCell class]])
    {
        id<JCConversationGroupObject> group = (id<JCConversationGroupObject>)object;
        JCConversationTableViewCell *conversationCell = (JCConversationTableViewCell *)cell;
        conversationCell.name.text    = group.titleText;
        conversationCell.detail.text  = group.detailText;
        conversationCell.date.text    = group.formattedModifiedShortDate;
        conversationCell.read         = group.isRead;
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

-(JCConversationGroupsResultsController *)conversationGroupResultsController
{
    if (!_conversationGroupsResultsController){
        PBX *pbx = self.authenticationManager.pbx;
        if (pbx && [pbx smsEnabled])
        {
            NSFetchRequest *fetchRequest = [Message MR_requestAllInContext:pbx.managedObjectContext];
            fetchRequest.includesSubentities = YES;
            fetchRequest.sortDescriptors = self.fetchedResultsController.fetchRequest.sortDescriptors;
            _conversationGroupsResultsController = [[JCConversationGroupsResultsController alloc] initWithFetchRequest:fetchRequest pbx:pbx];
            _conversationGroupsResultsController.delegate = self;
            
            __autoreleasing NSError *error = nil;
            if (![_conversationGroupsResultsController performFetch:&error]) {
                [self.tableView reloadData];
            };
        }
    }
    return _conversationGroupsResultsController;
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
    
    // TODO: translate index path for controller into index path for table, looking up the objects
    // index, and calculate the offset from the indexPath and newIndexPath, and convert into
    // indexPaths relative to the table data.
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
        {
            // Insert the object into where we are told its supposed to go, which may not be
            // correct. Then resort the array it to find the actual index it will be, and update the
            // table view to show the inserted cell at the right index path.
            [tableData addObject:anObject];
            [tableData sortUsingDescriptors:self.fetchedResultsController.fetchRequest.sortDescriptors];
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
//            NSUInteger deleteRow = [_tableData indexOfObject:anObject];
//            indexPath = [NSIndexPath indexPathForRow:deleteRow inSection:indexPath.section];
//            [_tableData sortUsingDescriptors:self.fetchedResultsController.fetchRequest.sortDescriptors];
//            NSUInteger newRow = [_tableData indexOfObject:anObject];
//            newIndexPath = [NSIndexPath indexPathForRow:newRow inSection:newIndexPath.section];
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // Override to do nothing.
}

#pragma mark JCConversationGroupsResultsControllerDelegate

-(void)conversationGroupResultsControllerWillChangeContent:(JCConversationGroupsResultsController *)controller
{
    // Override to do nothing.
}

-(void)conversationGroupResultsController:(JCConversationGroupsResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(JCConversationGroupsResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.tableView;
    NSMutableArray *tableData = self.tableData;
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
        {
            [tableData addObject:anObject];
            [tableData sortUsingDescriptors:self.fetchedResultsController.fetchRequest.sortDescriptors];
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
                [tableData replaceObjectAtIndex:row withObject:anObject];
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
            [tableData sortUsingDescriptors:self.fetchedResultsController.fetchRequest.sortDescriptors];
            NSUInteger newRow = [tableData indexOfObject:anObject];
            newIndexPath = [NSIndexPath indexPathForRow:newRow inSection:newIndexPath.section];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

-(void)conversationGroupResultsControllerDidChangeContent:(JCConversationGroupsResultsController *)controller
{
    // Override to do nothing.
}

@end
