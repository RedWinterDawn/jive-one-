//
//  JCConversationsTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"
#import "JCConversationGroupObject.h"

@interface JCConversationsTableViewController : UITableViewController

- (IBAction)refreshTable:(id)sender;
- (IBAction)clear:(id)sender;

@property (nonatomic) BOOL showTopCellSeperator;

- (id<JCConversationGroupObject>)objectAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathOfObject:(id<JCConversationGroupObject>)object;

@end
