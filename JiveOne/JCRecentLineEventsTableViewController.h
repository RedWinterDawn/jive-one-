//
//  JCRecentActivityTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 10/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"

typedef enum : NSUInteger {
    JCRecentLineEventsViewAll = 0,
    JCRecentLineEventsViewMissedCalls = 1,
    JCRecentLineEventsViewVoicemails = 2,
    JCRecentLineEventsViewAllCalls = 3
} JCRecentLineEventsViewFilter;

@interface JCRecentLineEventsTableViewController : JCFetchedResultsTableViewController

@property (nonatomic) JCRecentLineEventsViewFilter viewFilter;

- (void)reloadTable;

- (IBAction)toggleFilterState:(id)sender;
- (IBAction)clear:(id)sender;

@end
