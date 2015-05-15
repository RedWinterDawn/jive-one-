//
//  JCDebugBlockedContactsTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 5/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"
#import "DID.h"

@interface JCDebugBlockedContactsTableViewController : JCFetchedResultsTableViewController

@property (nonatomic, strong) DID *did;

@end
