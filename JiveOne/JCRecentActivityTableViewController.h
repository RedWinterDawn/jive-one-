//
//  JCRecentActivityTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 10/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"
#import "RecentEvent.h"

@protocol JCRecentActivityTableViewControllerDelegate <NSObject>

@optional
-(void)recentActivityDidSelectRecentEvent:(RecentEvent *)recentEvent;

@end

@interface JCRecentActivityTableViewController : JCFetchedResultsTableViewController

@property (nonatomic, weak) id <JCRecentActivityTableViewControllerDelegate> delegate;

@end
