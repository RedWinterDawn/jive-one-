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

-(IBAction)toggleFilterState:(id)sender
{
    if ([sender isKindOfClass:[UISegmentedControl class]])
    {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
        switch (segmentedControl.selectedSegmentIndex) {
            case 1:
            {
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kMissedCallEntityName];
                fetchRequest.fetchBatchSize = 6;
                
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:false];
                fetchRequest.sortDescriptors = @[sortDescriptor];
            
                _callHistoryTableViewController.fetchRequest = fetchRequest;
                break;
            }
            default:
                _callHistoryTableViewController.fetchRequest = nil;
                break;
        }
        
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCCallHistoryTableViewController class]]){
        _callHistoryTableViewController = (JCCallHistoryTableViewController *)viewController;
    
    }
}


@end
