//
//  JCConversationsTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"

@interface JCConversationsTableViewController : UITableViewController

-(IBAction)refreshTable:(id)sender;

@property (nonatomic) BOOL showTopCellSeperator;

@end
