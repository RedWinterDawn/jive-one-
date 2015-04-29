//
//  JCHistroyContainerViewController.h
//  JiveOne
//
//  Created by P Leonard on 10/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCCallHistoryTableViewController.h"

@interface JCCallHistoryViewController_iPhone : UIViewController

@property (nonatomic, readonly) JCCallHistoryTableViewController *callHistoryTableViewController;

-(IBAction)toggleFilterState:(id)sender;

@end
