//
//  JCDirectoryViewController.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDirectoryViewController.h"
#import "PersonEntities.h"
#import "PersonMeta.h"
#import "JCOsgiClient.h"
#import "JCDirectoryDetailViewController.h"
#import "JCPersonCell.h"
#import "JCDirectoryGroupViewController.h"
#import "ContactGroup.h"
#import "NotificationView.h"

#define kUINameRowHeight 100
#define kUIRowHeight 50


@interface JCDirectoryViewController ()


{
    NSMutableDictionary *personMap;
}


@property BOOL searchTableIsActive;


@end

@implementation JCDirectoryViewController

static NSString *CellIdentifier = @"DirectoryCell";


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [self.tableView registerNib:[UINib nibWithNibName:@"JCPersonCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    NSString *star = @"\u2605";
    sections = [NSArray arrayWithObjects:star,@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", nil];
    self.clientEntitiesArray = [[NSMutableArray alloc] init];
    self.clientEntitiesSearchArray = [[NSMutableArray alloc] init];
    
        //TODO: disable search bar if no objects in clientEntitiesArray
    //[[NotificationView sharedInstance] showPanelInView:self.view];
    //[[StatusPanel sharedInstance] showWithTitle:@"no internet" snippet:@"no internet" showProgress:NO];
    //[[StatusPanel sharedInstance] show];

    
    for(UIView *view in [self.tableView subviews])
    {
        //NSLog([[view class] description]);
        if([[[view class] description] isEqualToString:@"UITableViewIndex"])
        {
            CGRect frame = view.frame;
            frame.origin.y = frame.origin.y + 100;
            view.frame = frame;
            break;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    personMap = [[NSMutableDictionary alloc] init];
    [self loadCompanyDirectory];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}



#pragma mark -ABPeoplePickerDelegate methods
- (void)peoplePickerNavigationControllerDidCancel:
(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    
    [self dismissViewControllerAnimated:NO completion:nil];
    return NO;
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}

#pragma mark - Load Directories

- (void)loadLocalDirectory {
    
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                NSLog(@"User granted permission to contacts");
            } else {
                // User denied access
                // Display an alert telling user the contact could not be added
            }
        });
    }
  

    NSArray *allContacts = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFRelease(addressBook);
    NSInteger sectionCount = [sections count];
    NSInteger allContactsCount = [allContacts count];
    for (int i = 0; i < sectionCount; i++) {
        NSMutableArray *section = [[NSMutableArray alloc] init];
        
        for (int j = 0; j < allContactsCount; j++) {
            NSString * firstName = (__bridge_transfer NSString *)(ABRecordCopyValue((__bridge ABRecordRef)(allContacts[j]), kABPersonFirstNameProperty));
            
            if ([firstName hasPrefix:sections[i]] || [firstName hasPrefix:[sections[i] lowercaseString]]) {
                NSString * lastName = (__bridge_transfer NSString *)(ABRecordCopyValue((__bridge ABRecordRef)(allContacts[j]), kABPersonLastNameProperty));
                NSString * email = (__bridge_transfer NSString *)(ABRecordCopyValue((__bridge ABRecordRef)(allContacts[j]), kABPersonEmailProperty));
                NSString * phone = (__bridge_transfer NSString *)(ABRecordCopyValue((__bridge ABRecordRef)(allContacts[j]), kABPersonPhoneProperty));
                
                NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
                [tempDictionary setObject:firstName forKey:@"firstName"];
                [tempDictionary setObject:[self padNilPhoneNames:lastName] forKey:@"lastName"];
                [tempDictionary setObject:[self padNilPhoneNames:[NSString stringWithFormat:@"%@ %@", firstName, lastName] ] forKey:@"firstLast"];
                [tempDictionary setObject:email forKey:@"email"];
                [tempDictionary setObject:phone forKey:@"phone"];
            
            [section addObject:tempDictionary];
                
            }
        }
        
        [self.clientEntitiesArray addObject:section];
    }
    
    [self.tableView reloadData];
}

-(NSString*) padNilPhoneNames:(NSString*)string{
    if(!string)
        return @"";
    else
        return string;
}

- (void)loadCompanyDirectory {
    
    [self.clientEntitiesArray removeAllObjects];
    
    for (int i = 0; i < sections.count; i++) {
        NSString *section = sections[i];
        NSArray *sectionArray = nil;
        if ([section isEqualToString:@"\u2605"]) {
            sectionArray = [PersonEntities MR_findByAttribute:@"isFavorite" withValue:[NSNumber numberWithBool:YES]];
        }
        else {
            // retrieve entities where first name starts with letter of alphabet
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"(firstLastName BEGINSWITH[c] %@)", section];
            sectionArray = [PersonEntities MR_findAllWithPredicate:pred];
        }
        
        // sort array with bases on firstLastName property
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"firstLastName" ascending:YES];
        NSArray *sortedArray= [sectionArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
        
        [self.clientEntitiesArray addObject:sortedArray];
    }
    
    [personMap removeAllObjects];
    [self.tableView reloadData];
}

- (IBAction)segmentChanged:sender {
    
    [self.clientEntitiesArray removeAllObjects];
    if ([self.segControl selectedSegmentIndex] == 0) {
        [self loadCompanyDirectory];
        NSLog(@"First segment!");
    } else {
        [self loadLocalDirectory];
        NSLog(@"Second Segment!");
    }
    
}


- (void)refreshCompanyDirectory
{
    [[JCOsgiClient sharedClient] RetrieveClientEntitites:^(id JSON) {
        
        NSString *me = [JSON objectForKey:@"me"];
        NSArray* entityArray = [JSON objectForKey:@"entries"];
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        
        [PersonEntities MR_truncateAllInContext:localContext];
        [PersonMeta MR_truncateAllInContext:localContext];
        [localContext MR_saveToPersistentStoreAndWait];
        
        for (NSDictionary* entity in entityArray) {
            PersonEntities *c_ent = [PersonEntities MR_createInContext:localContext];
            c_ent.lastModified = [entity objectForKey:@"lastModified"];
            c_ent.presence = [entity objectForKey:@"presence"];
            c_ent.resourceGroupName = [entity objectForKey:@"company"];
            c_ent.tags = [entity objectForKey:@"tags"];
            c_ent.location = [entity objectForKey:@"location"];
            c_ent.firstName = [[entity objectForKey:@"name"] objectForKey:@"first"];
            c_ent.lastName = [[entity objectForKey:@"name"] objectForKey:@"last"];
            c_ent.lastFirstName = [[entity objectForKey:@"name"] objectForKey:@"lastFirst"];
            c_ent.firstLastName = [[entity objectForKey:@"name"] objectForKey:@"firstLast"];
            c_ent.groups = [entity objectForKey:@"groups"];
            c_ent.urn = [entity objectForKey:@"urn"];
            c_ent.id = [entity objectForKey:@"id"];
            c_ent.entityId = [entity objectForKey:@"_id"];
            c_ent.me = [NSNumber numberWithBool:[c_ent.entityId isEqualToString:me]];
            c_ent.picture = [entity objectForKey:@"picture"];
            c_ent.email = [entity objectForKey:@"email"];
            if (c_ent.isFavorite ==nil) {
                c_ent.isFavorite = NO;
            }
            
            PersonMeta *c_meta = [PersonMeta MR_createInContext:localContext];
            c_meta.entityId = entity[@"meta"][@"entity"];
            c_meta.lastModified = entity[@"meta"][@"lastModified"];
            c_meta.createDate = entity[@"meta"][@"createDate"];
            c_meta.pinnedActivityOrder = entity[@"meta"][@"pinnedActivityOrder"];
            c_meta.activityOrder = entity[@"meta"][@"activityOrder"];
            c_meta.urn = entity[@"meta"][@"urn"];
            c_meta.metaId = entity[@"meta"][@"id"];
            
            c_ent.entityMeta = c_meta;
            
            NSLog(@"id:%@ - _id:%@", [entity objectForKey:@"id"], [entity objectForKey:@"_id"]);
            
            [localContext MR_saveToPersistentStoreAndWait];
        }
        
        [self.clientEntitiesArray removeAllObjects];
        
        for (NSString *section in sections) {
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"(firstLastName BEGINSWITH[c] %@)", section];
            
            NSArray *sectionArray = [PersonEntities MR_findAllWithPredicate:pred];
            [self.self.clientEntitiesArray addObject:sectionArray];
            
        }
        
        [self.tableView reloadData];
        
    } failure:^(NSError *err) {
        NSLog(@"%@",[err description]);
    }];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (tableView == self.tableView) {
        return sections.count;
    }
    else {
        return 1;
    }
        
//    if (self.clientEntitiesArray.count == 0) {
//        return 0;
//    } else {
//        return sections.count;
//    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)index
{
    return index;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [sections objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //show search results
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.clientEntitiesSearchArray.count;
    }else{
    //show all results
        if (self.clientEntitiesArray.count == 0) {
            return 0;
        } else {
            return [(NSArray*)self.clientEntitiesArray[section] count];
        }
    }
    
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    JCPersonCell *cell;
    PersonEntities *person;
    if(tableView == self.tableView){//redundant, but easier than rearranging all the if statements below.
        //only instantiate the cell this way, if it is not part of the searchResutls Table view.
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        
        person = self.clientEntitiesArray[indexPath.section][indexPath.row];
    
        
    }
    else{
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[JCPersonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        NSString *entityId = self.clientEntitiesSearchArray[indexPath.row];
        person = [self getPersonFromListByEntityId:entityId];
    }
    
    if (person) {
    
        cell.person = person;
        
        //check to see if the person is a favorite
        if ([person.isFavorite boolValue]) {
            
            
            NSMutableString *name = [[NSMutableString alloc]initWithString: cell.personNameLabel.text];
            NSString *star = @"  ★";
            NSString *nameAndStarAsAnNSString = [NSString stringWithString:[name stringByAppendingString:star]];
            
            
            UIColor *theRightShadeOfYellowForOurStar = [UIColor colorWithRed:255.0/255.0 green:212.0/255.0 blue:0.0/255.0 alpha:1.0];
            NSRange starLocation = [nameAndStarAsAnNSString rangeOfString:@"★"];
            NSMutableAttributedString *personAttributedName = [[NSMutableAttributedString alloc]initWithString:nameAndStarAsAnNSString];
            [personAttributedName setAttributes:@{NSForegroundColorAttributeName : theRightShadeOfYellowForOurStar} range:starLocation];
            
            cell.personNameLabel.attributedText = personAttributedName;
        }
    }

    return cell;
    
//    NSArray *section;
//    
//    //no contacts loaded
//    if (self.clientEntitiesArray.count == 0) {
//        cell.textLabel.text = @"No contacts";
//        return cell;
//    }
//    //will show contacts loaded in clientEntitiesArray
//    else {
//            //show search results only
//        if(tableView == self.searchDisplayController.searchResultsTableView){
//            if (self.clientEntitiesSearchArray.count == 0) {
//                return nil;
//            }
//            cell = [[JCPersonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];//can only be used if initWithStyle manually initializes all uilabel properties (since it's not being created by the storyboard)
//            section = 0;
//        }
//        else{
//            //show all results
//            section = self.clientEntitiesArray[indexPath.section];
//        }
//        
//        //Company contacts
//        if([section[indexPath.row] isKindOfClass:[PersonEntities class]]){
//            
//            PersonEntities* person;
//            if(tableView == self.searchDisplayController.searchResultsTableView) {
//                person = self.clientEntitiesSearchArray[indexPath.row];
//            }
//            else {
//                person = section[indexPath.row];
//            }
//            cell.person = person;
//            
//            //check to see if the person is a favorite
//            if ([person.isFavorite boolValue]) {
//                
//                
//                NSMutableString *name = [[NSMutableString alloc]initWithString: cell.personNameLabel.text];
//                NSString *star = @"  ★";
//                NSString *nameAndStarAsAnNSString = [NSString stringWithString:[name stringByAppendingString:star]];
//                
//                
//                UIColor *theRightShadeOfYellowForOurStar = [UIColor colorWithRed:255.0/255.0 green:212.0/255.0 blue:0.0/255.0 alpha:1.0];
//                NSRange starLocation = [nameAndStarAsAnNSString rangeOfString:@"★"];
//                NSMutableAttributedString *personAttributedName = [[NSMutableAttributedString alloc]initWithString:nameAndStarAsAnNSString];
//                [personAttributedName setAttributes:@{NSForegroundColorAttributeName : theRightShadeOfYellowForOurStar} range:starLocation];
//                
//                cell.personNameLabel.attributedText = personAttributedName;
//            }
//            
//        }else{
//            //local contacts
//            NSDictionary * pers = section[indexPath.row];
//            cell.personNameLabel.text = [pers objectForKey:@"firstLast"];
//            cell.personDetailLabel.text = @"";//[person objectForKey:@"email"];
//
//            }
//        return cell;
//    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        self.searchTableIsActive = YES;
        
    }else{
        self.searchTableIsActive = NO;
    }
    [self performSegueWithIdentifier:@"directoryDetailView" sender:indexPath];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}


#pragma mark Search

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    //    number (phone or extension)
    // TODO:   special characters should not affect the search ()-.
    NSArray *searchTerms = [searchText componentsSeparatedByString:@" "];
    NSPredicate *pred;
    
    if ([searchTerms count] == 1) {
        pred = [NSPredicate predicateWithFormat:@"(firstName contains[cd] %@) OR (lastName contains[cd] %@) OR (email contains[cd] %@)"
                                  //OR (phoneNumber contains[cd] %@)", searchText
                                  , searchText, searchText, searchText];;
    } else {
        NSMutableArray *subPredicates = [[NSMutableArray alloc] init];
        for (NSString *term in searchTerms) {
            NSPredicate *p = [NSPredicate predicateWithFormat:@"(firstName contains[cd] %@) OR (lastName contains[cd] %@) OR (email contains[cd] %@)"
                              //OR (phoneNumber contains[cd] %@)", term
                              , term, term, term];;
            [subPredicates addObject:p];
        }
        pred = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
        
    }
    
    //clear the array or it will accumulate and be an union search instead of intersect
    [self.clientEntitiesSearchArray removeAllObjects];
    for (int i = 0; i < self.clientEntitiesArray.count; i++) {
        
        if (i == 0) {
            continue;
        }
        
        NSArray *sectionArray = self.clientEntitiesArray[i];
        NSArray *results = [sectionArray filteredArrayUsingPredicate:pred];
        results = [results valueForKeyPath:@"entityId"];
        [self.clientEntitiesSearchArray addObjectsFromArray:results];
    }
}

//called by UI delegate to begin constructing clientEntitesSearchArray
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}


- (PersonEntities *)getPersonFromListByEntityId:(NSString *)entityId
{
    for (NSArray *section in self.clientEntitiesArray) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"entityId ==[c] %@", entityId];
        NSArray *result = [section filteredArrayUsingPredicate:predicate];
        
        if (result.count > 0) {
            PersonEntities *person = result[0];
            return person;
        }
    }
    
    return nil;
}




#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    NSIndexPath *indexPath = sender;
    PersonEntities *person;
    
    if (self.searchTableIsActive) {
        NSString *entityId = self.clientEntitiesSearchArray[indexPath.row];
        person = [self getPersonFromListByEntityId:entityId];
    }
    else {
        person = self.clientEntitiesArray[indexPath.section][indexPath.row];
    }
    
    if (person) {
        [segue.destinationViewController setPerson:person];
    }
    

    
    
//    //check if it's a company or local contact
//    if (self.segControl.selectedSegmentIndex == 0) {
//        
//        
//        if ([[segue identifier] isEqualToString:@"groupView"]) {
//            JCDirectoryGroupViewController *groupVC = (JCDirectoryGroupViewController*)segue.destinationViewController;
//            groupVC.person = self.clientEntitiesArray;
//        } else if ([[segue identifier] isEqualToString:@"directoryDetailView"]) {
//        
//            PersonEntities *person = nil; //self.clientEntitiesArray[indexPath.section][indexPath.row];
//            if (self.searchTableIsActive) {
//                indexPath = sender;
//                person = self.clientEntitiesSearchArray[indexPath.section][indexPath.row];
//            }
//            else {
//                person = self.clientEntitiesArray[indexPath.section][indexPath.row];
//            }
//            [segue.destinationViewController setEntityId:person.entityId];
//            //[segue.destinationViewController setPerson:person];
//            //[segue.destinationViewController setABPerson:nil];
//            
//            //[segue.destinationViewController setPersonCell:(JCPersonCell *)[self.tableView cellForRowAtIndexPath:sender]];
//        }
//    }
//    //local contact
//    else
//    {
////        NSDictionary *person = nil;
////        if([segue.identifier isEqualToString:@"showSearchDetail"]) {
////            person = self.clientEntitiesSearchArray[indexPath.section][indexPath.row];
////        }
////        else {
////            person = self.clientEntitiesArray[indexPath.section][indexPath.row];
////        }
//        // get ABDictionary
//        
//        if ([[segue identifier] isEqualToString:@"groupView"]) {
//            NSMutableArray *person = self.clientEntitiesArray;
//            JCDirectoryGroupViewController* groupVC = segue.destinationViewController;
//            groupVC.personDict = person;
//        } else if ([[segue identifier] isEqualToString:@"directoryDetailView"]) {
//            NSDictionary *person = self.clientEntitiesArray[indexPath.section][indexPath.row];
//            JCDirectoryDetailViewController* detailVC = segue.destinationViewController;
//            detailVC.ABPerson = person;
//            detailVC.person = nil;
//        }
//        
//    }
//    
}

- (IBAction)refreshDirectory:(id)sender {
    [self refreshCompanyDirectory];
}

#pragma mark - Update UI on Presence Change
- (void)didUpdatePresence:(NSNotification*)notification
{
    Presence *presence = (Presence*)notification.object;
    NSMutableArray *indexPaths = [NSMutableArray array];
    
    // first we check in our simple structure
    if (personMap && personMap[presence.entityId]) {
        NSArray *rowSection = [personMap[presence.entityId] componentsSeparatedByString:@"|"];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[rowSection[0] integerValue] inSection:[rowSection[1] integerValue]];
        [indexPaths addObject:indexPath];
    }
    
//    if (indexPaths.count != 0) {
//        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
//    }
}
@end







