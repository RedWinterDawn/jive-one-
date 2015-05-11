//
//  JCHistroyContainerViewController.m
//  JiveOne
//
//  Created by P Leonard on 10/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallHistoryViewController_iPhone.h"

@implementation JCCallHistoryViewController_iPhone

-(IBAction)toggleFilterState:(id)sender
{
    if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
        _callHistoryTableViewController.viewFilter = segmentedControl.selectedSegmentIndex;
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
