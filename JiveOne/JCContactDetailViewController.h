//
//  JCContactDetailTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 4/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCStaticTableViewController.h"

#import "JCPhoneNumberDataSource.h"
#import "JCPhoneTypeSelectorViewController.h"
#import "JCEditableTableViewCell.h"

@interface JCContactDetailViewController : JCStaticTableViewController <UITextFieldDelegate>

@property (strong, nonatomic) id<JCPhoneNumberDataSource> phoneNumber;

// Managed Object Context
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

// Name Section
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *nameSectionCells;

@property (weak, nonatomic) IBOutlet JCEditableTableViewCell *nameCell;
@property (weak, nonatomic) IBOutlet JCEditableTableViewCell *firstNameCell;
@property (weak, nonatomic) IBOutlet JCEditableTableViewCell *lastNameCell;

// Numbers Section

@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *numberSectionCells;

@property (weak, nonatomic) IBOutlet UITableViewCell *extensionCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *numberCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *jiveIdCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *addNumberCell;

@end
