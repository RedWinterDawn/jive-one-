//
//  JCDebugContactsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 12/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDebugContactsTableViewController.h"
#import "InternalExtension.h"
#import "InternalExtensionGroup.h"

@implementation JCDebugContactsTableViewController

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        
        NSFetchRequest *fetchRequest = nil;
        if (self.contactGroup) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groups contains %@", self.contactGroup];
            fetchRequest = [InternalExtension MR_requestAllSortedBy:@"name" ascending:YES withPredicate:predicate inContext:self.managedObjectContext];
        }
        else {
            fetchRequest = [InternalExtension MR_requestAllSortedBy:@"name" ascending:YES];
        }
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                             managedObjectContext:self.managedObjectContext
                                                                               sectionNameKeyPath:nil
                                                                                        cacheName:nil];
    }
    return _fetchedResultsController;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //    UIViewController *viewController = segue.destinationViewController;
    //    if ([viewController isKindOfClass:[JCLineTableViewController class]]) {
    //        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    //        ((JCLineTableViewController *)viewController).line = [self objectAtIndexPath:indexPath];
    //    }
}

-(void)configureCell:(UITableViewCell *)cell withObject:(InternalExtension *)contact
{
    cell.textLabel.text         = contact.titleText;
    cell.detailTextLabel.text   = contact.detailText;
}

@end
