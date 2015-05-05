//
//  JCDebugBlockedContactsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 5/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCDebugBlockedContactsTableViewController.h"
#import "BlockedNumber.h"

@interface JCDebugBlockedContactsTableViewController ()

@end

@implementation JCDebugBlockedContactsTableViewController

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"did = %@", self.did];
        NSFetchRequest *fetchRequest = [BlockedNumber MR_requestAllWithPredicate:predicate];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES]];
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                             managedObjectContext:self.managedObjectContext
                                                                               sectionNameKeyPath:nil
                                                                                        cacheName:nil];
    }
    return _fetchedResultsController;
}

-(void)configureCell:(UITableViewCell *)cell withObject:(BlockedNumber *)blockedNumber
{
    cell.textLabel.text = blockedNumber.number;
}

@end
