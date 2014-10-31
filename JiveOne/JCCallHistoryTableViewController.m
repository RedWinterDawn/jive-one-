//
//  JCHistoryTableViewController.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallHistoryTableViewController.h"

#import "Call.h"

@interface JCCallHistoryTableViewController ()
{
    NSFetchRequest *_fetchRequest;
}

@end

@implementation JCCallHistoryTableViewController

#pragma mark - Setters - 

-(void)setFetchRequest:(NSFetchRequest *)fetchRequest
{
    _fetchRequest = fetchRequest;
    self.fetchedResultsController = nil;
    [self.tableView reloadData];
}

#pragma mark - Getters -

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    }
    return _fetchedResultsController;
}

-(NSFetchRequest *)fetchRequest
{
    if (!_fetchRequest)
    {
        _fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kCallEntityName];
        _fetchRequest.fetchBatchSize = 6;
        _fetchRequest.includesSubentities = TRUE;
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:false];
        _fetchRequest.sortDescriptors = @[sortDescriptor];
    }
    return _fetchRequest;
}

@end
