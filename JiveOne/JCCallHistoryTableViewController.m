//
//  JCHistoryTableViewController.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallHistoryTableViewController.h"

// Managers
#import "JCPhoneManager.h"

// Managed objects
#import "Call.h"
#import "MissedCall.h"

@interface JCCallHistoryTableViewController ()
{
    NSFetchRequest *_fetchRequest;
}

@end

@implementation JCCallHistoryTableViewController

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    NSArray *missedCalls = [MissedCall MR_findByAttribute:@"read" withValue:@NO inContext:self.managedObjectContext];
    for (MissedCall *missedCall in missedCalls) {
        missedCall.read = YES;
    }
    [self.managedObjectContext MR_saveOnlySelfAndWait];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

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

#pragma mark - Delegate Handlers

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Call *call = (Call *)[self objectAtIndexPath:indexPath];
    [self dialNumber:call.number sender:tableView];
}

@end
