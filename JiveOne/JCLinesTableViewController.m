//
//  JCLinesTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLinesTableViewController.h"
#import "Line.h"
#import "JCLineTableViewController.h"

@implementation JCLinesTableViewController

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        NSFetchRequest *fetchRequest = [Line MR_requestAllSortedBy:@"name" ascending:YES];
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
    if ([viewController isKindOfClass:[JCLineTableViewController class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ((JCLineTableViewController *)viewController).line = [self objectAtIndexPath:indexPath];
    }
}

-(void)configureCell:(UITableViewCell *)cell withObject:(Line *)line
{
    cell.textLabel.text = line.name;
    cell.detailTextLabel.text = line.extension;
}

@end
