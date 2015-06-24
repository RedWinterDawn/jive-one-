//
//  JCContactDetailTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 4/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCStaticTableViewController.h"

#import "JCPhoneNumberDataSource.h"
#import "JCTypeSelectorViewController.h"
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

@property (weak, nonatomic) IBOutlet UITableViewCell *addNumberCell;

// Address Section

@property (weak, nonatomic) IBOutlet UITableViewCell *addAddressCell;

// Other Section

@property (weak, nonatomic) IBOutlet UITableViewCell *addOtherCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *jiveIdCell;


@property (weak, nonatomic) IBOutlet UITableViewCell *deleteCell;

@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *editingCells;

-(IBAction)sync:(id)sender;

@end
