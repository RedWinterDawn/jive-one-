//
//  JCContactsTableViewController.h
//  JiveOne
//
//  Created by Eduardo  Gueiros on 10/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"

#define kDataClassContacts NSLocalizedString(@"CONTACTS_SERVICE", @"")

typedef NS_ENUM(NSInteger, JCContactFilter) {
    JCContactFilterAll,
    JCContactFilterFavorites,
    JCContactFilterLocalContacts,
    JCContactFilterGrouped
};

@interface JCContactsTableViewController : JCFetchedResultsTableViewController <UISearchBarDelegate>

@property (nonatomic) JCContactFilter filterType;

@end
