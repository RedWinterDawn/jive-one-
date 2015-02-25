//
//  JCRecentActivityTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 10/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"
#import "RecentLineEvent.h"

@class JCRecentLineEventsTableViewController;

@protocol JCRecentLineEventsTableViewControllerDelegate <NSObject>

@optional
-(void)recentLineEventController:(JCRecentLineEventsTableViewController *)controller didSelectRecentLineEvent:(RecentLineEvent *)recentLineEvent;

@end

@interface JCRecentLineEventsTableViewController : JCFetchedResultsTableViewController

@property (nonatomic, weak) id <JCRecentLineEventsTableViewControllerDelegate> delegate;

@end
