//
//  JCDebugBlockedContactsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 5/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCDebugBlockedContactsTableViewController.h"
#import "BlockedContact.h"

@interface JCDebugBlockedContactsTableViewController ()

@end

@implementation JCDebugBlockedContactsTableViewController

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"did = %@", self.did];
        NSFetchRequest *fetchRequest = [BlockedContact MR_requestAllWithPredicate:predicate];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES]];
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                             managedObjectContext:self.managedObjectContext
                                                                               sectionNameKeyPath:nil
                                                                                        cacheName:nil];
    }
    return _fetchedResultsController;
}

-(void)configureCell:(UITableViewCell *)cell withObject:(BlockedContact *)blockedContact
{
    cell.textLabel.text = blockedContact.number;
}

@end
