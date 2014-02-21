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



@interface JCDirectoryViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ABPeoplePickerNavigationControllerDelegate>
{
    NSMutableArray *localContacts;
    NSArray *sections;
}

- (IBAction)refreshDirectory:(id)sender;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *clientEntitiesArray;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segControl;

- (IBAction)segmentChanged:sender ;


@end
