//
//  JCDebugPbxsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 12/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDebugPbxsTableViewController.h"
#import "PBX.h"

@implementation JCDebugPbxsTableViewController

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        NSFetchRequest *fetchRequest;
        User *user = self.user;
        if (user) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY user = %@", user];
            fetchRequest = [PBX MR_requestAllWithPredicate:predicate inContext:self.managedObjectContext];
        }
        else {
            fetchRequest = [PBX MR_requestAllSortedBy:@"name" ascending:YES inContext:self.managedObjectContext];
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
//    if ([viewController isKindOfClass:[JCDebugUserTableViewController class]]) {
//        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//        ((JCDebugUserTableViewController *)viewController).user = [self objectAtIndexPath:indexPath];
//    }
}

-(void)configureCell:(UITableViewCell *)cell withObject:(PBX *)pbx
{
    cell.textLabel.text = pbx.name;
}


@end
