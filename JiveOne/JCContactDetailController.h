//
//  JCContactDetailTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 4/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "StaticDataTableViewController.h"
#import "JCPhoneNumberDataSource.h"

#import "JCEditableTableViewCell.h"

@interface JCContactDetailController : StaticDataTableViewController <UITextFieldDelegate>

@property (strong, nonatomic) id<JCPhoneNumberDataSource> phoneNumber;

// Name Section
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *nameSectionCells;

// Managed Object Context
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (weak, nonatomic) IBOutlet JCEditableTableViewCell *nameCell;
@property (weak, nonatomic) IBOutlet JCEditableTableViewCell *firstNameCell;
@property (weak, nonatomic) IBOutlet JCEditableTableViewCell *lastNameCell;

// Numbers Section
@property (weak, nonatomic) IBOutlet UITableViewCell *extensionCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *numberCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *jiveIdCell;

@end
