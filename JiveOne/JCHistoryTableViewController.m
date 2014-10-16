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

@interface JCHistoryTableViewController () <NSFetchedResultsControllerDelegate, JCCallerViewControllerDelegate>
{
    NSFetchRequest *_fetchRequest;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;


@end

@implementation JCHistoryTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.fetchedResultsController = nil;
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


-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        NSManagedObjectContext *managedObjectContext = [NSManagedObjectContext MR_defaultContext];
        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                                                                   managedObjectContext:managedObjectContext
                                                                                                     sectionNameKeyPath:nil
                                                                                                              cacheName:nil];
        
        fetchedResultsController.delegate = self;

        __autoreleasing NSError *error;
        [fetchedResultsController performFetch:&error];
        if (error) {
            NSLog(@"%@", [error description]);
        }
        _fetchedResultsController = fetchedResultsController;
        
    }
    return _fetchedResultsController;
}

-(void)setFetchRequest:(NSFetchRequest *)fetchRequest
{
    _fetchRequest = fetchRequest;
    self.fetchedResultsController = nil;
    [self.tableView reloadData];
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


#pragma mark - Delegate Handlers -

#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    if (sectionInfo) {
        return [sectionInfo numberOfObjects];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JCHistoryCell *cell = (JCHistoryCell *)[tableView dequeueReusableCellWithIdentifier:kJCHistoryTableViewControllerCellReuseIdentifier forIndexPath:indexPath];
    
    Call *call = (Call *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.name.text = call.name;
    cell.number.text = call.number;
    cell.timestamp.text = call.formattedModifiedShortDate;
    cell.extension.text = call.extension;
    cell.icon.image = call.icon;
    return cell;
}

#pragma mark Fetched Results Controller Delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}

#pragma mark Caller View Controller Delegate

-(void)shouldDismissCallerViewController:(JCCallerViewController *)viewController
{
    [self dismissViewControllerAnimated:NO completion:^{
        
    }];
}


@end
