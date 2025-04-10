//
//  JCContactGroupsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 12/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDebugContactGroupsTableViewController.h"
#import "JCDebugContactsTableViewController.h"
#import "InternalExtensionGroup.h"

@implementation JCDebugContactGroupsTableViewController

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        NSFetchRequest *fetchRequest = [InternalExtensionGroup MR_requestAllSortedBy:@"name" ascending:YES];
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                             managedObjectContext:self.managedObjectContext
                                                                               sectionNameKeyPath:nil
                                                                                        cacheName:nil];
    }
    return _fetchedResultsController;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCDebugContactsTableViewController class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ((JCDebugContactsTableViewController *)viewController).contactGroup = (InternalExtensionGroup *)[self objectAtIndexPath:indexPath];
    }
}

-(void)configureCell:(UITableViewCell *)cell withObject:(InternalExtensionGroup *)contactGroup
{
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%lu)", contactGroup.name, (unsigned long)contactGroup.internalExtensions.count];
    cell.detailTextLabel.text = contactGroup.groupId;
}

@end
