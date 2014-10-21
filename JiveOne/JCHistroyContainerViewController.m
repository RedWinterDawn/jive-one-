//
//  JCHistroyContainerViewController.m
//  JiveOne
//
//  Created by P Leonard on 10/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCHistroyContainerViewController.h"
#import "JCHistoryTableViewController.h"
#import <CoreData/CoreData.h>

#import "MissedCall.h"

@interface JCHistroyContainerViewController ()
{
    JCHistoryTableViewController *_historyTableViewController;
}

@end

@implementation JCHistroyContainerViewController

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
            
                _historyTableViewController.fetchRequest = fetchRequest;
                break;
            }
            default:
                _historyTableViewController.fetchRequest = nil;
                break;
        }
        
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *viewController = segue.destinationViewController;
    
    if ([viewController isKindOfClass:[JCHistoryTableViewController class]]){
        _historyTableViewController = (JCHistoryTableViewController *)viewController;
    
    }
}


@end
