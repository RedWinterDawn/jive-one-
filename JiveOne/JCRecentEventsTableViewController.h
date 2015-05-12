//
//  JCRecentEventsTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 2/25/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentLineEventsTableViewController.h"

@class JCRecentEventsTableViewController;

@protocol JCRecentEventsTableViewControllerDelegate <NSObject>

-(void)recentEventController:(JCRecentLineEventsTableViewController *)controller didSelectObject:(id)object;

@end


@interface JCRecentEventsTableViewController : JCRecentLineEventsTableViewController

@property (nonatomic, weak) id <JCRecentEventsTableViewControllerDelegate> delegate;

-(IBAction)refreshData:(id)sender;

@end
