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


@interface JCHistoryTableViewController () <NSFetchedResultsControllerDelegate, JCCallerViewControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, weak) NSString *cellNumber;

@end

@implementation JCHistoryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"main-logo.png"]];
    imageView.contentMode = UIViewContentModeCenter;
    self.tableView.backgroundView = imageView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
   
    if ([viewController isKindOfClass:[JCCallerViewController class]]) {
        JCCallerViewController *callerViewController = (JCCallerViewController *)viewController;
        callerViewController.delegate = self;
        callerViewController.dialString = _cellNumber;
    }
}

-(void)shouldDismissCallerViewController:(JCCallerViewController *)viewController
{
    [self dismissViewControllerAnimated:NO completion:^{
        
    }];
}



-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
     
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Call"];
        fetchRequest.fetchBatchSize = 6;
        fetchRequest.includesSubentities = TRUE;
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:false];
        fetchRequest.sortDescriptors = @[sortDescriptor];
        
        fetchRequest.predicate = self.predicate;
        
        NSManagedObjectContext *managedObjectContext = [NSManagedObjectContext MR_defaultContext];
        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
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
    JCHistoryCell *cell = (JCHistoryCell *)[tableView dequeueReusableCellWithIdentifier:@"JCHistoryCell" forIndexPath:indexPath];
    
    Call *call = (Call *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    
    //cell.
    cell.name.text = call.name;
    cell.number.text = call.number;
    cell.extension.text = call.extension;
    _cellNumber = call.number;
    cell.timestamp.text = call.formattedShortDate;
    cell.icon.image = call.icon;
   
    
    // Configure the cell...
    
    return cell;
}

#pragma mark Fetched Results Controller

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}


@end
