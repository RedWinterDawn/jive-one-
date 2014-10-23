//
//  JCHistoryTableViewController.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCHistoryTableViewController.h"
#import <CoreData/CoreData.h>
#import <MagicalRecord/MagicalRecord.h>
#import "JCHistoryCell.h"
#import "JCCallerViewController.h"
#import "Call.h"

NSString *const kJCHistoryTableViewControllerCellReuseIdentifier = @"JCHistoryCell";

@interface JCHistoryTableViewController () <JCCallerViewControllerDelegate>
{
    NSFetchRequest *_fetchRequest;
}

@end

@implementation JCHistoryTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
   
    if ([viewController isKindOfClass:[JCCallerViewController class]]) {
        JCCallerViewController *callerViewController = (JCCallerViewController *)viewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Call *call = [self.fetchedResultsController objectAtIndexPath:indexPath];
        callerViewController.delegate = self;
        callerViewController.dialString = call.number;
    }
}

-(JCHistoryCell *)tableView:(UITableView *)tableView cellForObject:(id <NSObject>)object atIndexPath:(NSIndexPath*)indexPath;
{
    JCHistoryCell *cell = [tableView dequeueReusableCellWithIdentifier:kJCHistoryTableViewControllerCellReuseIdentifier forIndexPath:indexPath];
    [self configureCell:cell withObject:object];
    return cell;
}


- (void)configureCell:(JCHistoryCell *)cell withObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[Call class]])
    {
        Call *call = (Call *)object;
        cell.name.text = call.name;
        cell.number.text = call.number;
        cell.timestamp.text = call.formattedModifiedShortDate;
        cell.extension.text = call.extension;
        cell.icon.image = call.icon;
    }
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

#pragma mark Caller View Controller Delegate

-(void)shouldDismissCallerViewController:(JCCallerViewController *)viewController
{
    [self dismissViewControllerAnimated:NO completion:^{
        
    }];
}


@end
