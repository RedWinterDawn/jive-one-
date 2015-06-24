//
//  JCContactsTableViewController.h
//  JiveOne
//
//  Created by Eduardo  Gueiros on 10/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"

@protocol JCContactsTableViewControllerDelegate;
@class InternalExtensionGroup;

typedef NS_ENUM(NSInteger, JCContactFilter) {
    JCContactFilterAll,
    JCContactFilterGrouped
};

@interface JCContactsTableViewController : JCFetchedResultsTableViewController <UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet id<JCContactsTableViewControllerDelegate> delegate;

@property (strong, nonatomic) InternalExtensionGroup *contactGroup;
@property (nonatomic) JCContactFilter filterType;

-(IBAction)sync:(id)sender;

@end

@protocol JCContactsTableViewControllerDelegate <NSObject>

-(void)contactsTableViewController:(JCContactsTableViewController *)contactsViewController didSelectContactGroup:(InternalExtensionGroup *)contactGroup;

@end