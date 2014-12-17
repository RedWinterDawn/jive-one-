//
//  JCDebugContactsTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 12/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"

@class ContactGroup;

@interface JCDebugContactsTableViewController : JCFetchedResultsTableViewController

@property (nonatomic, strong) ContactGroup *contactGroup;

@end
