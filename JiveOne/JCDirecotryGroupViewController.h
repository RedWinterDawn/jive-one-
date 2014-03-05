//
//  JCDirecotryGroupViewController.h
//  JiveOne
//
//  Created by Ethan Parker on 2/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClientEntities.h"
#import "ContactGroup.h"


@interface JCDirecotryGroupViewController : UITableViewController

// These are used in the prepareForSegue method of DirectoryViewController when you're going from directory view to group view, it needs to know if you want detail view or group view.
@property (nonatomic, strong) NSMutableArray *person;
@property (nonatomic, strong) NSMutableArray *personDict;


//These are for populating the GroupSelectorViewController with people from ClientEntities that you need to select to create a contact group
@property (nonatomic, weak) NSNumber *contactGroup;
@property (nonatomic, strong) NSMutableArray *testArray;


@end
