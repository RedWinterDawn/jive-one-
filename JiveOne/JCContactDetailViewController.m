//
//  JCContactDetailTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 4/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCContactDetailViewController.h"

#import "JCPhoneManager.h"
#import "JCAuthenticationManager.h"

#import "Extension.h"
#import "InternalExtension.h"
#import "Line.h"
#import "PBX.h"
#import "User.h"
#import "Contact.h"
#import "JCVoicemailNumber.h"
#import "JCPersonDataSource.h"

#import "JCDialerViewController.h"
#import "JCStoryboardLoaderViewController.h"
#import "JCPhoneTypeSelectorViewController.h"

#import "JCPhoneTypeSelectorViewController.h"

@interface JCContactDetailViewController () <JCPhoneTypeSelectorTableControllerDelegate> {
    BOOL _addingContact;
}

@end


@implementation JCContactDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Handling calling from the view.
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    JCPhoneManager *phoneManager = self.phoneManager;
    if (self.isTablet) {
        [center addObserver:self selector:@selector(onActiveCall) name:kJCPhoneManagerShowCallsNotification object:phoneManager];
        [center addObserver:self selector:@selector(onInactiveCall) name:kJCPhoneManagerHideCallsNotification object:phoneManager];
        if (phoneManager.isActiveCall) {
            [self onActiveCall];
        }
    }
   
    // Determine display mode. Extensions do not support editing. If we are adding a contact, we
    id<JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
    if ([phoneNumber isKindOfClass:[Contact class]] || !phoneNumber)
    {
        self.navigationItem.rightBarButtonItem =  self.editButtonItem;
        if (!phoneNumber) {
            
            NSManagedObjectContext *context = self.managedObjectContext;
            Contact *contact = [Contact MR_createEntityInContext:context];
            User *user = self.authenticationManager.user;
            contact.user = (User *)[context existingObjectWithID:user.objectID error:nil];
            self.phoneNumber = contact;
            _addingContact = TRUE;
            [self setEditing:YES animated:NO];
        }
        else
        {
            [self setCells:_editingCells hidden:YES];
        }
    } else {
        [self setCells:_editingCells hidden:YES];
    }
    [self layoutForPhoneNumber:self.phoneNumber animated:NO];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    
    if ([viewController isKindOfClass:[JCPhoneTypeSelectorViewController class]]) {
        JCPhoneTypeSelectorViewController *phoneTypeSelectorViewController = (JCPhoneTypeSelectorViewController *)viewController;
        phoneTypeSelectorViewController.sender = sender;
        phoneTypeSelectorViewController.delegate = self;
    }
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(IBAction)callExtension:(id)sender
{
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UITableViewCell *cell = (UITableViewCell *)((UITapGestureRecognizer *)sender).view;
        if (cell == self.extensionCell) {
            [self dialPhoneNumber:self.phoneNumber
                        usingLine:self.authenticationManager.line
                           sender:sender];
        }
    }
}

-(IBAction)cancel:(id)sender
{
    [self.managedObjectContext reset];
    if (_addingContact) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    self.editing = FALSE;
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (!editing) {
        [self saveContact];
    } else {
        [self convertContact];
    }
    
    [self layoutForEditing:editing animated:YES];
    
    [super setEditing:editing animated:animated];
}

-(void)setEditing:(BOOL)editing
{
    if (!editing) {
        [self saveContact];
    } else {
        [self convertContact];
    }
    
    [self layoutForEditing:editing animated:NO];
    
    [super setEditing:editing];
}



#pragma mark - Notification Handlers -

-(void)onActiveCall
{
    JCCallerViewController *callViewController = self.phoneManager.callViewController;
    if (!callViewController) {
        return;
    }
    
    // If we are the top view controller, we need to push the call view controller onto the view
    // controller stack.
    UINavigationController *navigationController = self.navigationController;
    callViewController.navigationItem.hidesBackButton = TRUE;
    [navigationController pushViewController:callViewController animated:NO];
}

-(void)onInactiveCall
{
    JCCallerViewController *callViewController = self.phoneManager.callViewController;
    if (!callViewController) {
        return;
    }
    
    UINavigationController *navigationController = self.navigationController;
    if (navigationController.topViewController != self) {
        [navigationController popToRootViewControllerAnimated:NO];
    }
}

#pragma mark - Delegate Handlers -

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    id<JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
    if (![phoneNumber isKindOfClass:[Contact class]]) {
        return NO;
    }
    
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    id<JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
    if (![phoneNumber isKindOfClass:[Contact class]]) {
        return;
    }
    
    Contact *contact = (Contact *)phoneNumber;
    if (textField == self.firstNameCell.textField) {
        contact.firstName = textField.text;
        [self updateTitle];
    } else if (textField == self.lastNameCell.textField) {
        contact.lastName = textField.text;
        [self updateTitle];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellAtIndexPath:indexPath];
    if (cell == _addNumberCell || cell == _addAddressCell || cell == _addOtherCell) {
        return UITableViewCellEditingStyleInsert;
    } else if (cell == _deleteCell) {
        return UITableViewCellEditingStyleNone;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellAtIndexPath:indexPath];
    switch (editingStyle) {
        case UITableViewCellEditingStyleInsert:
        {
            NSIndexPath *actualIndexPath = [self indexPathForCell:cell];
            if (cell == _addNumberCell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"NumberCell"];
            } else if (cell == _addAddressCell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"AddressCell"];
            } else {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"OtherCell"];
            }
            
            [self addCell:cell atIndexPath:actualIndexPath];
            break;
        }
        
        case UITableViewCellEditingStyleDelete:
            [self removeCell:cell];
            break;
            
        default:
            break;
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellAtIndexPath:indexPath];
    if (cell == _deleteCell) {
        return NO;
    }
    return YES;
}


-(IBAction)valueChanged:(id)sender
{
    if ([sender isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)sender;
        id<JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
        if (![phoneNumber isKindOfClass:[Contact class]]) {
            return;
        }
        
        Contact *contact = (Contact *)phoneNumber;
        if (textField == self.firstNameCell.textField) {
            contact.firstName = textField.text;
            [self updateTitle];
        }
        else if (textField == self.lastNameCell.textField) {
            contact.lastName = textField.text;
            [self updateTitle];
        }
    }
}

-(IBAction)deleteContact:(id)sender
{
    [self deleteContact];
}

#pragma mark JCPhoneTypeSelectorTableViewControllerDelegate

-(void)phoneTypeSelectorController:(JCPhoneTypeSelectorViewController *)controller didSelectPhoneType:(NSString *)phoneType
{
    //id sender = controller.sender;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Private -

-(void)updateTitle
{
    id <JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
    self.title = phoneNumber.titleText;
    self.navigationItem.title = phoneNumber.titleText;
}

-(void)convertContact
{
    id <JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
    if (![phoneNumber isKindOfClass:[Contact class]]) {
        Contact *contact = [Contact MR_createEntityInContext:self.managedObjectContext];
        if ([phoneNumber conformsToProtocol:@protocol(JCPersonDataSource)]) {
            id <JCPersonDataSource> person = (id<JCPersonDataSource>) phoneNumber;
            contact.firstName = person.firstName;
            contact.lastName = person.lastName;
        }
    }
}

-(void)saveContact
{
    
    
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        NSLog(@"%@", [error description]);
        
        _addingContact = FALSE;
    }];
}

-(void)deleteContact
{
    id<JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
    if (![phoneNumber isKindOfClass:[Contact class]]) {
        return;
    }
    
    Contact *contact = (Contact *)phoneNumber;
    [self.managedObjectContext deleteObject:contact];
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma Layout

-(void)layoutForEditing:(BOOL)editing animated:(BOOL)animated
{
    [self startUpdates];
    
    if (!editing) {
        self.navigationItem.leftBarButtonItem = nil;
        [self setCells:_editingCells hidden:YES];
        
    } else {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = item;
        [self setCells:_editingCells hidden:NO];
        if (_addingContact) {
            [self setCell:_deleteCell hidden:YES];
        }
    }
    
    [self endUpdates];
}

-(void)layoutForPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber animated:(BOOL)animated
{
    [self startUpdates];
    
    // We can not edit Extensions.
    if ([phoneNumber isKindOfClass:[Extension class]])
    {
        [self layoutForExtension:(Extension *)phoneNumber];
        [self endUpdates];
        return;
    }
    
    // Name Section
    [self layoutNameSection:phoneNumber];
    
    // Number Section
    [self layoutNumberSection:phoneNumber];
    
    [self endUpdates];
}

-(void)layoutNameSection:(id<JCPhoneNumberDataSource>)phoneNumber
{
    [self setCells:_nameSectionCells hidden:YES];
    
    NSString *name = phoneNumber.titleText;
    [self updateTitle];
    if (phoneNumber && ![phoneNumber conformsToProtocol:@protocol(JCPersonDataSource)]) {
        self.nameCell.textField.text  = name;
        [self setCell:_nameCell hidden:NO];
        return;
    }
    
    // If we are an object that can be a person.
    id<JCPersonDataSource> person = (id<JCPersonDataSource>)phoneNumber;
    if (person.firstName) {
        self.firstNameCell.textField.text = person.firstName;
    }
    if (person.lastName) {
        self.lastNameCell.textField.text = person.lastName;
    }
    
    [self setCell:_firstNameCell hidden:NO];
    [self setCell:_lastNameCell hidden:NO];
}

-(void)layoutNumberSection:(id<JCPhoneNumberDataSource>)phoneNumber
{
    [self setCells:_numberSectionCells hidden:YES];
    self.numberCell.detailTextLabel.text = phoneNumber.formattedNumber;
    self.numberCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"phone-green"]];
    [self setCell:_numberCell hidden:NO];
}

-(void)layoutForExtension:(Extension *)extension
{
    [self updateTitle];
    
    // Name Section. Extensions only have a name.
    self.nameCell.textField.text  = extension.titleText;
    [self setCells:_nameSectionCells hidden:YES];
    [self setCell:_nameCell hidden:NO];
    
    // Numbers Section
    [self setCells:_numberSectionCells hidden:YES];
    self.extensionCell.detailTextLabel.text = extension.number;
    self.extensionCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"phone-green"]];
    
    [self setCell:_extensionCell hidden:NO];
    if ([extension isKindOfClass:[InternalExtension class]]) {
        NSString *jiveId = ((InternalExtension *)extension).jiveUserId;
        if (jiveId) {
            self.jiveIdCell.detailTextLabel.text = jiveId;
            [self setCell:_jiveIdCell hidden:NO];
        }
    }
    else if([extension isKindOfClass:[Line class]]) {
        self.jiveIdCell.detailTextLabel.text = ((Line *)extension).pbx.user.jiveUserId;
        [self setCell:_jiveIdCell hidden:NO];
    }
}

@end
