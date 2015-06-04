//
//  JCHistroyContainerViewController.m
//  JiveOne
//
//  Created by P Leonard on 10/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallHistoryViewController_iPhone.h"
#import "MissedCall.h"

@implementation JCCallHistoryViewController_iPhone

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self markMissedAsRead];
}

-(IBAction)toggleFilterState:(id)sender
{
    if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
        JCRecentLineEventsViewFilter filter;
        
        switch (segmentedControl.selectedSegmentIndex) {
            case 1:
                filter = JCRecentLineEventsViewMissedCalls;
                break;
                
            default:
                filter = JCRecentLineEventsViewAllCalls;
                break;
        }
        
        _callHistoryTableViewController.viewFilter = filter;
        
    }
}

-(void)markMissedAsRead {
    NSPredicate *predicate = _callHistoryTableViewController.fetchedResultsController.fetchRequest.predicate;
    NSPredicate *readPredicate = [NSPredicate predicateWithFormat:@"read == %@", @NO];
    predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, readPredicate]];
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSArray *missedCalls = [MissedCall MR_findAllWithPredicate:predicate inContext:localContext];
        for (MissedCall *missedCall in missedCalls) {
            missedCall.read = YES;
        }
    }];
}

-(void)clearAllEvents{
    
    NSPredicate *predicate = _callHistoryTableViewController.fetchedResultsController.fetchRequest.predicate;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSArray *eventsToDelete = nil;
        switch (_callHistoryTableViewController.viewFilter) {
            case JCRecentLineEventsViewAllCalls:
                eventsToDelete = [Call MR_findAllWithPredicate:predicate inContext:localContext];
                break;
                
        case JCRecentLineEventsViewMissedCalls:
                eventsToDelete = [MissedCall MR_findAllWithPredicate:predicate inContext:localContext];
                break;
                
            default:
                break;
        }
        for (MissedCall *event in eventsToDelete) {
            [event markForDeletion:NULL];
        }
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCCallHistoryTableViewController class]]){
        _callHistoryTableViewController = (JCCallHistoryTableViewController *)viewController;
        _callHistoryTableViewController.viewFilter = JCRecentLineEventsViewAllCalls;
    }
}

#pragma mark - Actions
- (IBAction)clearHistBtn:(id)sender {
    [self clearAllEvents];
}
@end
