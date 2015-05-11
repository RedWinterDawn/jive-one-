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
} JCRecentLineEventsViewFilters;

@interface JCRecentLineEventsTableViewController : JCFetchedResultsTableViewController

@property (nonatomic, strong) NSFetchRequest *fetchRequest;
@property (nonatomic) JCRecentLineEventsViewFilters viewFilter;

- (void)reloadTable;

- (IBAction)toggleFilterState:(id)sender;

@end
