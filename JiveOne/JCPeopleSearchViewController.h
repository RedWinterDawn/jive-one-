//
//  JCPeopleSearchViewController.h
//  JiveOne
//
//  Created by P Leonard on 5/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>
#import <AddressBook/AddressBook.h>
#import "JCSearchBar.h"

@interface JCPeopleSearchViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ABPeoplePickerNavigationControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate>
{
    NSMutableArray *localContacts;
    NSArray *sections;
}

- (IBAction)refreshDirectory:(id)sender;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *clientEntitiesArray;
@property (nonatomic, strong) NSMutableArray *clientEntitiesSearchArray;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segControl;

- (IBAction)segmentChanged:sender ;
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope;
- (IBAction)searchPeople:(id)sender;


@end
