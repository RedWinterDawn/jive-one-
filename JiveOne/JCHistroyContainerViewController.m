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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *viewController = segue.destinationViewController;
    
    if ([viewController isKindOfClass:[JCHistoryTableViewController class]]){
        _historyTableViewController = (JCHistoryTableViewController *)viewController;
    
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
