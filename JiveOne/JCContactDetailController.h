//
//  JCContactDetailTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 4/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "StaticDataTableViewController.h"
#import "JCPersonManagedObject.h"

#import "JCEditableTableViewCell.h"

@interface JCContactDetailController : StaticDataTableViewController

@property (strong, nonatomic) id<JCPhoneNumberDataSource> phoneNumber;

// Name Section
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *nameSectionCells;
@property (weak, nonatomic) IBOutlet JCEditableTableViewCell *nameCell;
@property (weak, nonatomic) IBOutlet JCEditableTableViewCell *firstNameCell;
@property (weak, nonatomic) IBOutlet JCEditableTableViewCell *lastNameCell;

// Numbers Section
@property (weak, nonatomic) IBOutlet UITableViewCell *extensionCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *numberCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *jiveIdCell;

@end
