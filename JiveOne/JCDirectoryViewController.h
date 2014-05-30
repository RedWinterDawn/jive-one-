//
//  JCDirectoryViewController.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>
#import <AddressBook/AddressBook.h>
#import "JCSearchBar.h"

@class JCPeopleSearchViewController;
@protocol PeopleSearchDelegate <NSObject>

- (void)dismissedWithPerson:(PersonEntities *)person;
- (void)dismissedByCanceling;

@end

@interface JCDirectoryViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ABPeoplePickerNavigationControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate>
{
    NSMutableArray *localContacts;
    NSArray *sections;
}

- (IBAction)refreshDirectory:(id)sender;

@property (nonatomic, assign) id<PeopleSearchDelegate> delegate;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *clientEntitiesArray;
@property (nonatomic, strong) NSMutableArray *clientEntitiesSearchArray;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segControl;

- (IBAction)segmentChanged:sender ;
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope;
- (IBAction)searchPeople:(id)sender;


@end
