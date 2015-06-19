//
//  JCDebugDidsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 3/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCDebugDIDsTableViewController.h"
#import "JCDebugDIDTableViewController.h"
#import "DID.h"
#import "PBX.h"

@implementation JCDebugDIDsTableViewController

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        NSFetchRequest *fetchRequest = [DID MR_requestAllSortedBy:@"number" ascending:YES];
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
    if ([viewController isKindOfClass:[JCDebugDIDTableViewController class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ((JCDebugDIDTableViewController *)viewController).did = (DID *)[self objectAtIndexPath:indexPath];
    }
}

-(void)configureCell:(UITableViewCell *)cell withObject:(DID *)did
{
    cell.textLabel.text = did.number;
    cell.detailTextLabel.text = did.pbx.name;
}

@end
