//
//  JCConversationsTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"
#import "JCMessageGroup.h"

@interface JCConversationsTableViewController : UITableViewController

@property (nonatomic) BOOL showTopCellSeperator;

- (JCMessageGroup *)objectAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathOfObject:(JCMessageGroup *)object;

@end
