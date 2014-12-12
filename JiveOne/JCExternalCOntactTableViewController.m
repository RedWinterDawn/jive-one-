
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "JCExternalCOntactTableViewController.h"
#import "JCDialStringLabel.h"
#import "JCCallerViewController.h"

enum TableRowSelected
{
    kUIDisplayPickerRow = 0,
    kUICreateNewContactRow,
    kUIDisplayContactRow,
    kUIEditUnknownContactRow
};

// Height for the Edit Unknown Contact row
#define kUIEditUnknownContactRowHeight 81.0

@interface JCExternalContactTableViewController () < ABPeoplePickerNavigationControllerDelegate,ABPersonViewControllerDelegate,
ABNewPersonViewControllerDelegate, ABUnknownPersonViewControllerDelegate>
@property (nonatomic, assign) ABAddressBookRef addressBook;


@end

@implementation JCExternalContactTableViewController

#pragma mark Load views
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Create an address book object
    _addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
       [self checkAddressBookAccess];
    [self showPeoplePickerController];
}

//-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    UIViewController *viewController = segue.destinationViewController;
//    if ([viewController isKindOfClass:[JCCallerViewController class]]) {
//        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//        id object = [self objectAtIndexPath:indexPath];
//        if ([object isKindOfClass:[Contact class]]) {
//            Contact *contact = (Contact *)object;
//            JCCallerViewController *callerViewController = (JCCallerViewController *)viewController;
//            callerViewController.delegate = self;
//            callerViewController.dialString = contact.extension;
//        }
//    }
//}

#pragma mark -
#pragma mark Address Book Access
// Check the authorization status of our application for Address Book
-(void)checkAddressBookAccess
{
    switch (ABAddressBookGetAuthorizationStatus())
    {
            // Update our UI if the user has granted access to their Contacts
        case  kABAuthorizationStatusAuthorized:
            [self accessGrantedForAddressBook];
            break;
            // Prompt the user for access to Contacts if there is no definitive answer
        case  kABAuthorizationStatusNotDetermined :
            [self requestAddressBookAccess];
            break;
            // Display a message if the user has denied or restricted access to Contacts
        case  kABAuthorizationStatusDenied:
        case  kABAuthorizationStatusRestricted:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Privacy Warning"
                                                            message:@"Permission was not granted for Contacts."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
            break;
        default:
            break;
    }
}

// Prompt the user for access to their Address Book data
-(void)requestAddressBookAccess
{
    JCExternalContactTableViewController * __weak weakSelf = self;
    
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error)
                                             {
                                                 if (granted)
                                                 {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         [weakSelf accessGrantedForAddressBook];
                                                         
                                                     });
                                                 }
                                             });
}

// This method is called when the user has granted access to their address book data.
-(void)accessGrantedForAddressBook
{
    // Load data from the plist file
    [self.tableView reloadData];
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellID";
    UITableViewCell *aCell;
    // Make the Display Picker and Create New Contact rows look like buttons
    if (indexPath.section < 2)
    {
        aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        aCell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    else
    {
        aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        aCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        aCell.detailTextLabel.numberOfLines = 0;
    }
    return aCell;
}



#pragma mark TableViewDelegate method
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Change the height if Edit Unknown Contact is the row selected
    return (indexPath.section==kUIEditUnknownContactRow) ? kUIEditUnknownContactRowHeight : tableView.rowHeight;
}

#pragma mark Show all contacts
// Called when users tap "Display Picker" in the application. Displays a list of contacts and allows users to select a contact from that list.
// The application only shows the phone, email, and birthdate information of the selected contact.
-(void)showPeoplePickerController
{
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    // Display only a person's phone, email, and birthdate
    NSArray *displayedItems = [NSArray arrayWithObjects:[NSNumber numberWithInt:kABPersonPhoneProperty],
                               [NSNumber numberWithInt:kABPersonEmailProperty],
                               [NSNumber numberWithInt:kABPersonBirthdayProperty], nil];
    
    
    picker.displayedProperties = displayedItems;
    
    // Show the picker
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark ABPeoplePickerNavigationControllerDelegate methods
// Displays the information of a selected person
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    return YES;
}



// Does not allow users to perform default actions such as dialing a phone number, when they select a person property.
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    return NO ;
}

//@property(nonatomic,copy) NSPredicate *predicateForSelectionOfProperty

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
                         didSelectPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    NSLog(@"******************************************************DIALSTRINGRETURNING ******************************************************");
    
    
}

// Dismisses the people picker and shows the application when users tap Cancel.
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark ABPersonViewControllerDelegate methods
// Does not allow users to perform default actions such as dialing a phone number, when they select a contact property.
- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person
                    property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifierForValue
{
    return YES;
}

@end
