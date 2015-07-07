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
#import "Contact+V5Client.h"
#import "JCVoicemailNumber.h"
#import "JCPersonDataSource.h"

#import "JCDialerViewController.h"
#import "JCStoryboardLoaderViewController.h"
#import "JCTypeSelectorViewController.h"

#import "JCTypeSelectorViewController.h"

#import "JCContactPhoneNumberTableViewCell.h"
#import "JCContactAddressTableViewCell.h"
#import "JCContactOtherFieldTableViewCell.h"

@interface JCContactDetailViewController () <JCTypeSelectorTableControllerDelegate, JCContactPhoneNumberTableViewCellDelegate> {
    BOOL _addingContact;
}

@end

@implementation JCContactDetailViewController

- (void)viewDidLoad
{
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
        self.refreshControl.enabled = FALSE;
        [self setCells:_editingCells hidden:YES];
    }
    [self layoutForPhoneNumber:self.phoneNumber animated:NO];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCTypeSelectorViewController class]]) {
        JCTypeSelectorViewController *typeSelectorViewController = (JCTypeSelectorViewController *)viewController;
        typeSelectorViewController.sender = sender;
        typeSelectorViewController.delegate = self;
        
        if ([sender isKindOfClass:[JCContactPhoneNumberTableViewCell class]]) {
            JCContactPhoneNumberTableViewCell *cell = (JCContactPhoneNumberTableViewCell *)sender;
            id<JCPhoneNumberDataSource> phoneNumber = cell.phoneNumber;
            typeSelectorViewController.title = phoneNumber.titleText;
            typeSelectorViewController.navigationItem.title = phoneNumber.titleText;
            typeSelectorViewController.types = [JCTypeSelectorViewController phoneTypes];
        } else if ([sender isKindOfClass:[JCContactAddressTableViewCell class]]) {
            typeSelectorViewController.types = [JCTypeSelectorViewController addressTypes];
        } else if ([sender isKindOfClass:[JCContactOtherFieldTableViewCell class]]) {
            typeSelectorViewController.types = [JCTypeSelectorViewController otherTypes];
        }
    }
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (!editing) {
        [self saveContact:^(BOOL success, NSError *error) {
            if (success) {
                [self layoutForEditing:editing animated:YES];
                [super setEditing:editing animated:animated];
            }
        }];
    } else {
        [self convertContact];
        [self layoutForEditing:editing animated:YES];
        [super setEditing:editing animated:animated];
    }
}

-(void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}

- (CGFloat)heightForCell:(UITableViewCell *)cell
{
    if ([cell isKindOfClass:[JCContactPhoneNumberTableViewCell class]]) {
        return 55;
    }
    else if ([cell isKindOfClass:[JCContactAddressTableViewCell class]]) {
        return 120;
    }
    else if ([cell isKindOfClass:[JCContactOtherFieldTableViewCell class]]) {
        return 55;
    }
    return self.tableView.rowHeight;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - IBActions -

-(IBAction)nameChanged:(id)sender
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

-(IBAction)sync:(id)sender
{
    if ([sender isKindOfClass:[UIRefreshControl class]]) {
        id<JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
        if (![phoneNumber isKindOfClass:[Contact class]]) {
            [((UIRefreshControl *)sender) endRefreshing];
            return;
        }
        
        Contact *contact = (Contact *)phoneNumber;
        
        // If we do not have a contact ID, we do not need to sync yet, since we do not exits on the
        // server yet.
        if (!contact.contactId) {
            [((UIRefreshControl *)sender) endRefreshing];
            return;
        }
        
        [Contact syncContact:contact completion:^(BOOL success, NSError *error) {
            [((UIRefreshControl *)sender) endRefreshing];
            if (error) {
                [self showError:error];
            } else {
                [self layoutForPhoneNumber:contact animated:YES];
            }
        }];
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

#pragma mark UITextFieldDelegate

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    Contact *contact = [self contact];
    if (!contact) {
        return NO;
    }
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    Contact *contact = [self contact];
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

#pragma UITableViewDelegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Contact *contact = [self contact];
    UITableViewCell *cell = [self cellAtIndexPath:indexPath];
    switch (editingStyle) {
        case UITableViewCellEditingStyleInsert:
        {
            NSIndexPath *actualIndexPath = [self indexPathForCell:cell];
            if (cell == _addNumberCell) {
                cell = [self newPhoneNumberCellForContact:contact];
            } else if (cell == _addAddressCell) {
                cell = [self newAddressCellForContact:contact];
            } else if (cell == _addOtherCell) {
                cell = [self newOtherFieldCellForContact:contact];
                [self performSegueWithIdentifier:@"SelectPhoneType" sender:cell];
            }
            [self addCell:cell atIndexPath:actualIndexPath];
            break;
        }
        
        case UITableViewCellEditingStyleDelete:
            [self removeCell:cell];
            if ([cell isKindOfClass:[JCContactPhoneNumberTableViewCell class]]) {
                id<JCPhoneNumberDataSource> phoneNumber = ((JCContactPhoneNumberTableViewCell *)cell).phoneNumber;
                if ([phoneNumber isKindOfClass:[PhoneNumber class]]) {
                    [self.managedObjectContext deleteObject:(PhoneNumber *)phoneNumber];
                }
            } else if ([cell isKindOfClass:[JCContactAddressTableViewCell class]]){
                Address *address = ((JCContactAddressTableViewCell *)cell).address;
                [self.managedObjectContext deleteObject:address];
            } else if ([cell isKindOfClass:[JCContactOtherFieldTableViewCell class]]) {
                ContactInfo *info = ((JCContactOtherFieldTableViewCell *)cell).info;
                [self.managedObjectContext deleteObject:info];
            }
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

#pragma mark JCContactPhoneNumberTableViewCellDelegate

-(void)selectTypeForCell:(JCCustomEditTableViewCell *)cell
{
    [self performSegueWithIdentifier:@"SelectPhoneType" sender:cell];
}

-(void)contactPhoneNumberCell:(JCContactPhoneNumberTableViewCell *)cell dialPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    [self dialPhoneNumber:phoneNumber
                usingLine:self.authenticationManager.line
                   sender:cell];
}

#pragma mark JCPhoneTypeSelectorTableViewControllerDelegate

-(void)typeSelectorController:(JCTypeSelectorViewController *)controller didSelectPhoneType:(NSString *)type
{
    id sender = controller.sender;
    if ([sender isKindOfClass:[JCContactPhoneNumberTableViewCell class]]) {
        id<JCPhoneNumberDataSource> phoneNumber = ((JCContactPhoneNumberTableViewCell *)sender).phoneNumber;
        if([phoneNumber isKindOfClass:[PhoneNumber class]]) {
            ((PhoneNumber *)phoneNumber).type = type;
        }
    } else if([sender isKindOfClass:[JCContactAddressTableViewCell class]]) {
        Address *address = ((JCContactAddressTableViewCell *)sender).address;
        address.type = type;
    } else if ([sender isKindOfClass:[JCContactOtherFieldTableViewCell class]]) {
        ContactInfo *info = ((JCContactOtherFieldTableViewCell *)sender).info;
        info.key = type;
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Private -

-(void)updateTitle
{
    id <JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
    self.title = phoneNumber.titleText;
    self.navigationItem.title = phoneNumber.titleText;
    self.nameCell.textField.text = phoneNumber.name;
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

-(void)saveContact:(CompletionHandler)completion
{
    id<JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
    if (![phoneNumber isKindOfClass:[Contact class]]) {
        if (completion) {
            completion(TRUE, nil);
        }
        return;
    }
    
    Contact *contact = (Contact *)phoneNumber;
    NSManagedObjectContext *context = contact.managedObjectContext;
    if (!context.hasChanges) {
        if (contact.contactId || contact.etag) {
            if (completion) {
                completion(TRUE, nil);
            }
            return;
        }
    }
    
    [contact markForUpdate:^(BOOL success, NSError *error) {
        if (error) {
            self.editing = TRUE;
            [self showError:error];
        }
        _addingContact = FALSE;
        if (completion) {
            completion(success, error);
        }
    }];
}

-(void)deleteContact
{
    id<JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
    if (![phoneNumber isKindOfClass:[Contact class]]) {
        return;
    }
    
    [self showStatus:NSLocalizedString(@"Deleting", @"Deleting Contact")];
    Contact *contact = (Contact *)phoneNumber;
    [contact markForDeletion:^(BOOL success, NSError *error) {
        [self hideStatus];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [self performSegueWithIdentifier:@"ShowDefaultDetail" sender:self];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

-(Contact *)contact
{
    id<JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
    if (![phoneNumber isKindOfClass:[Contact class]]) {
        return nil;
    }
    return (Contact *)phoneNumber;
}

-(JCCustomEditTableViewCell *)phoneNumberCellForPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    JCContactPhoneNumberTableViewCell *cell = [JCContactPhoneNumberTableViewCell cellWithParent:self bundle:[NSBundle mainBundle]];
    cell.phoneNumber = phoneNumber;
    cell.delegate = self;
    cell.lastRowOnly = TRUE;
    return cell;
}

-(JCCustomEditTableViewCell *)newPhoneNumberCellForContact:(Contact *)contact
{
    JCContactPhoneNumberTableViewCell *cell = [JCContactPhoneNumberTableViewCell cellWithParent:self bundle:[NSBundle mainBundle]];
    PhoneNumber *phoneNumber = [PhoneNumber MR_createEntityInContext:self.managedObjectContext];
    phoneNumber.contact = contact;
    cell.phoneNumber = phoneNumber;
    cell.delegate = self;
    cell.lastRowOnly = TRUE;
    return cell;
}

-(JCCustomEditTableViewCell *)addressCellForAddress:(Address *)address
{
    JCContactAddressTableViewCell *cell = [JCContactAddressTableViewCell cellWithParent:self bundle:[NSBundle mainBundle]];
    cell.address = address;
    cell.delegate = self;
    cell.lastRowOnly = TRUE;
    return cell;
}

-(JCCustomEditTableViewCell *)newAddressCellForContact:(Contact *)contact
{
    JCContactAddressTableViewCell *cell = [JCContactAddressTableViewCell cellWithParent:self bundle:[NSBundle mainBundle]];
    Address *address = [Address MR_createEntityInContext:self.managedObjectContext];
    address.contact = contact;
    cell.address = address;
    cell.delegate = self;
    cell.lastRowOnly = TRUE;
    return cell;
}

-(JCCustomEditTableViewCell *)contactInfoCellForContactInfo:(ContactInfo *)contactInfo
{
    JCContactOtherFieldTableViewCell *cell = [JCContactOtherFieldTableViewCell cellWithParent:self bundle:[NSBundle mainBundle]];
    cell.info = contactInfo;
    cell.delegate = self;
    cell.lastRowOnly = TRUE;
    return cell;
}

-(JCCustomEditTableViewCell *)newOtherFieldCellForContact:(Contact *)contact
{
    JCContactOtherFieldTableViewCell *cell = [JCContactOtherFieldTableViewCell cellWithParent:self bundle:[NSBundle mainBundle]];
    ContactInfo *info = [ContactInfo MR_createEntityInContext:self.managedObjectContext];
    info.contact = contact;
    cell.info = info;
    cell.delegate = self;
    cell.lastRowOnly = TRUE;
    return cell;
}

#pragma Layout

-(void)layoutForEditing:(BOOL)editing animated:(BOOL)animated
{
    [self startUpdates];
    
    if (!editing) {
        self.navigationItem.leftBarButtonItem = nil;
        [self setCells:_editingCells hidden:YES];
        [self setCell:_nameCell hidden:NO];
    } else {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = item;
        [self setCells:_editingCells hidden:NO];
        [self setCell:_nameCell hidden:YES];
        if (_addingContact) {
            [self setCell:_deleteCell hidden:YES];
        }
    }
    
    [self endUpdates];
}

-(void)layoutForPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber animated:(BOOL)animated
{
    [self startUpdates];
    
    [self reset];
    
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
    
    // Address Section
    [self layoutAddressSection:phoneNumber];
    
    // Info section
    [self layoutInfoSection:phoneNumber];
    
    [self endUpdates];
}

-(void)layoutNameSection:(id<JCPhoneNumberDataSource>)phoneNumber
{
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
    self.nameCell.textField.text = person.name;
}

-(void)layoutNumberSection:(id<JCPhoneNumberDataSource>)phoneNumber
{
    if ([phoneNumber isKindOfClass:[Contact class]]) {
        Contact *contact = (Contact *)phoneNumber;
        NSArray *phoneNumbers = [contact.phoneNumbers.allObjects sortedArrayUsingSelector:@selector(order)];
        NSInteger count = phoneNumbers.count;
        for (int index = 0; index < count; index++) {
            PhoneNumber *number = [phoneNumbers objectAtIndex:index];
            JCCustomEditTableViewCell *cell = [self phoneNumberCellForPhoneNumber:number];
            NSIndexPath *actualIndexPath = [self indexPathForCell:_addNumberCell];
            cell.lastRow = (index+1 == count);
            [self addCell:cell atIndexPath:actualIndexPath];
        }
    } else if ([phoneNumber isKindOfClass:[JCAddressBookPerson class]]) {
        JCAddressBookPerson *person = (JCAddressBookPerson *)phoneNumber;
        NSArray *phoneNumbers = person.phoneNumbers;
        NSInteger count = phoneNumbers.count;
        for (int index = 0; index < count; index++) {
            JCAddressBookNumber *number = [phoneNumbers objectAtIndex:index];
            JCCustomEditTableViewCell *cell = [self phoneNumberCellForPhoneNumber:number];
            cell.lastRow = (index+1 == count);
            NSIndexPath *actualIndexPath = [self indexPathForCell:_addNumberCell];
            [self addCell:cell atIndexPath:actualIndexPath];
        }
    } else {
        JCCustomEditTableViewCell *cell = [self phoneNumberCellForPhoneNumber:phoneNumber];
        cell.lastRow = TRUE;
        NSIndexPath *actualIndexPath = [self indexPathForCell:_addNumberCell];
        [self addCell:cell atIndexPath:actualIndexPath];
    }
}

-(void)layoutAddressSection:(id<JCPhoneNumberDataSource>)phoneNumber
{
    if ([phoneNumber isKindOfClass:[Contact class]]) {
        Contact *contact = (Contact *)phoneNumber;
        NSArray *addresses = [contact.addresses.allObjects sortedArrayUsingSelector:@selector(order)];
        NSInteger count = addresses.count;
        for (int index = 0; index < count; index++) {
            Address *address = [addresses objectAtIndex:index];
            JCCustomEditTableViewCell *cell = [self addressCellForAddress:address];
            cell.lastRow = (index+1 == count);
            NSIndexPath *actualIndexPath = [self indexPathForCell:_addAddressCell];
            [self addCell:cell atIndexPath:actualIndexPath];
        }
    }
}

-(void)layoutInfoSection:(id<JCPhoneNumberDataSource>)phoneNumber
{
    if ([phoneNumber isKindOfClass:[Contact class]]) {
        Contact *contact = (Contact *)phoneNumber;
        NSArray *info = [contact.info.allObjects sortedArrayUsingSelector:@selector(order)];
        NSInteger count = info.count;
        for (int index = 0; index < count; index++) {
            ContactInfo *contactInfo = [info objectAtIndex:index];
            JCCustomEditTableViewCell *cell = [self contactInfoCellForContactInfo:contactInfo];
            cell.lastRow = (index+1 == count);
            NSIndexPath *actualIndexPath = [self indexPathForCell:_addOtherCell];
            [self addCell:cell atIndexPath:actualIndexPath];
        }
    }
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
    JCCustomEditTableViewCell *cell = [self phoneNumberCellForPhoneNumber:extension];
    NSIndexPath *actualIndexPath = [self indexPathForCell:_addNumberCell];
    cell.lastRow = YES;
    [self addCell:cell atIndexPath:actualIndexPath];
    
    // JiveID
    if ([extension isKindOfClass:[InternalExtension class]]) {
        NSString *jiveId = ((InternalExtension *)extension).jiveUserId;
        if (jiveId) {
            JCContactOtherFieldTableViewCell *cell = [JCContactOtherFieldTableViewCell cellWithParent:self bundle:[NSBundle mainBundle]];
            cell.lastRowOnly = TRUE;
            cell.detailTextLabel.text = NSLocalizedString(@"Jive ID", @"Jive Id display in contacts");
            cell.textLabel.text = jiveId;
            cell.lastRow = YES;
            NSIndexPath *actualIndexPath = [self indexPathForCell:_addOtherCell];
            [self addCell:cell atIndexPath:actualIndexPath];
        }
    }
    else if([extension isKindOfClass:[Line class]]) {
        JCContactOtherFieldTableViewCell *cell = [JCContactOtherFieldTableViewCell cellWithParent:self bundle:[NSBundle mainBundle]];
        cell.lastRowOnly = TRUE;
        cell.detailTextLabel.text = NSLocalizedString(@"Jive ID", @"Jive Id display in contacts");
        cell.textLabel.text = ((Line *)extension).pbx.user.jiveUserId;
        cell.lastRow = YES;
        NSIndexPath *actualIndexPath = [self indexPathForCell:_addOtherCell];
        [self addCell:cell atIndexPath:actualIndexPath];
    }
}

-(void)reset
{
    [super reset];
    [self layoutForEditing:self.editing animated:NO];
}

@end
