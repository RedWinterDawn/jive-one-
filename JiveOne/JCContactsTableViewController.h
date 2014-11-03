//
//  JCContactsTableViewController.h
//  JiveOne
//
//  Created by Eduardo  Gueiros on 10/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCFetchedResultsTableViewController.h"
#import "JCSearchBar.h"
#import "JCPersonCell.h"

@interface JCContactsTableViewController : JCFetchedResultsTableViewController <UISearchBarDelegate, UISearchDisplayDelegate, JCPersonCellDelegate>

@end
