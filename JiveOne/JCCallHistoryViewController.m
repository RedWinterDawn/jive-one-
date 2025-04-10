//
//  JCHistroyContainerViewController.m
//  JiveOne
//
//  Created by P Leonard on 10/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallHistoryViewController.h"
#import "MissedCall.h"
#import "Voicemail.h"

@implementation JCCallHistoryViewController

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
                
            case 2:
                filter = JCRecentLineEventsViewVoicemails;
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCCallHistoryTableViewController class]]){
        _callHistoryTableViewController = (JCCallHistoryTableViewController *)viewController;
        _callHistoryTableViewController.viewFilter = JCRecentLineEventsViewAllCalls;
    }
}

#pragma mark - Actions
- (IBAction)clear:(id)sender
{
    [_callHistoryTableViewController clear:sender];
}
@end
