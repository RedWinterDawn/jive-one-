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
#import <QuartzCore/QuartzCore.h>

#define kUINameRowHeight 100
#define kUIRowHeight 50


@interface JCDirectoryViewController ()
{
    NSMutableDictionary *personMap;
}
@property (strong, nonatomic) UIView* searchBarView;

@property BOOL searchTableIsActive;
@property BOOL scrollDirectionIsUp;
@property float previousOffset;
@property float amountScrolledSinceLastDirectionChange;
@property float scrollViewOffsetReference;
@property float deltaOffsetSinceLastDirectionChange;
@property float deltaSearchBarY_SinceLastDirectionChange;
@property float searchBarY_Reference;





@end

@implementation JCDirectoryViewController

static NSString *CellIdentifier = @"DirectoryCell";


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.previousOffset = 0;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"JCPersonCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    NSString *star = @"\u2605";
    sections = [NSArray arrayWithObjects:star,@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", nil];
    self.clientEntitiesArray = [[NSMutableArray alloc] init];
    self.clientEntitiesSearchArray = [[NSMutableArray alloc] init];
    
    self.searchBarView.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.searchBarView];
    
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
    
    if (self.searchTableIsActive) {
        [self.searchDisplayController.searchBar resignFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    const int MAX_Y = 87;
    const int MIN_Y = -22;
    
    NSLog(@"offset y: %f viewCenter y: %f", scrollView.contentOffset.y, self.searchBarView.center.y);
    NSLog(@"delta: %f", self.amountScrolledSinceLastDirectionChange);
    self.amountScrolledSinceLastDirectionChange = abs(self.scrollViewOffsetReference - scrollView.contentOffset.y);
    
        // scrolling up
        if (scrollView.contentOffset.y > self.previousOffset) {
            
            //direction changed
            if(self.scrollDirectionIsUp == NO){
                    self.scrollViewOffsetReference = scrollView.contentOffset.y;
                    self.searchBarY_Reference = self.searchBarView.center.y;
                }
            
            self.deltaOffsetSinceLastDirectionChange = abs(self.scrollViewOffsetReference - scrollView.contentOffset.y);
            self.searchBarView.center = CGPointMake(self.searchBarView.center.x, (self.searchBarY_Reference - self.deltaOffsetSinceLastDirectionChange));
            self.scrollDirectionIsUp = YES;
            
        }//scrolling down or - initalizing the first time through
        else if((scrollView.contentOffset.y < self.previousOffset) && (self.previousOffset != 0))
        {
            //direction changed
            if(self.scrollDirectionIsUp){
                self.scrollViewOffsetReference = scrollView.contentOffset.y;
                self.searchBarY_Reference = self.searchBarView.center.y;
            }

            self.deltaOffsetSinceLastDirectionChange = abs(self.scrollViewOffsetReference - scrollView.contentOffset.y);
            self.searchBarView.center = CGPointMake(self.searchBarView.center.x, (self.searchBarY_Reference + self.deltaOffsetSinceLastDirectionChange));
            self.scrollDirectionIsUp = NO;
        }
    
    //set how far down the search bar can go - account for when we are at the top of the view and want it to animate down with the rest of the tableviewcells.
    if ((self.searchBarView.center.y > 87) && (scrollView.contentOffset.y > -64)) {
        self.searchBarView.center = CGPointMake(self.searchBarView.center.x, MAX_Y);
    }
    if (scrollView.contentOffset.y <= -64) {
        self.searchBarView.center = CGPointMake(self.searchBarView.center.x, MAX_Y + abs(scrollView.contentOffset.y + 64));
    }
    
    //set how far up we alow the search bar to go (we allow it to go just off the top of the screen.)
    if ((self.searchBarView.center.y < -(self.searchBarView.frame.size.height/2))) {
            self.searchBarView.center = CGPointMake(self.searchBarView.center.x, MIN_Y);
    }

    self.previousOffset = scrollView.contentOffset.y;
}


- (UIView *)searchBarView
{
    if (!_searchBarView) {
        _searchBarView = [[UIView alloc]initWithFrame:CGRectMake(0, 65, 320, 44)];
    }
    return _searchBarView;
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
    BOOL noData = YES;
    
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
        
        if (noData) {
            noData = sortedArray.count == 0;
        }
        
        [self.clientEntitiesArray addObject:sortedArray];
    }
    
    if(noData)
    {
        NSLog(@"NoData");
        NSArray *allPeople = [PersonEntities MR_findAll];
        NSLog(@"All People Count = %lu", (unsigned long)allPeople.count);
        [self refreshCompanyDirectory];
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
        [self loadCompanyDirectory];
        
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

/**
 This code left intentionally commentend. Uncomment the code bellow for a custom, dashed section 
 headers. 
 **/
//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    if (section == 0 && ((NSArray*)self.clientEntitiesArray[section]).count == 0) {
//        return 20;
//    }
//    return 15;
//}



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

- (IBAction)searchPeople:(id)sender {
    
    [self.searchDisplayController.searchBar becomeFirstResponder];
    
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
}
@end







