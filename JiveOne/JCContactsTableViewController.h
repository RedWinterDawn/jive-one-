//
//  JCContactsTableViewController.h
//  JiveOne
//
//  Created by Eduardo  Gueiros on 10/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"

@class JCContactsTableViewController;
@class InternalExtensionGroup;

@protocol JCContactsTableViewControllerDelegate <NSObject>

-(void)contactsTableViewController:(JCContactsTableViewController *)contactsViewController didSelectContactGroup:(InternalExtensionGroup *)contactGroup;

@end

typedef NS_ENUM(NSInteger, JCContactFilter) {
    JCContactFilterAll,
    JCContactFilterFavorites,
    JCContactFilterGrouped
};

@interface JCContactsTableViewController : JCFetchedResultsTableViewController <UISearchBarDelegate>

@property (nonatomic, weak) IBOutlet id<JCContactsTableViewControllerDelegate> delegate;

@property (nonatomic, strong) InternalExtensionGroup *contactGroup;
@property (nonatomic) JCContactFilter filterType;

@end
