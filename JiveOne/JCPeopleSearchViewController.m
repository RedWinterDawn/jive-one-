//
//  JCPeopleSearchViewController.m
//  JiveOne
//
//  Created by P Leonard on 5/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPeopleSearchViewController.h"
#import "PersonEntities.h"
#import "PersonMeta.h"
#import "JCRESTClient.h"
#import "JCDirectoryDetailViewController.h"
#import "JCPersonCell.h"
#import "JCDirectoryGroupViewController.h"
#import "JSMessagesViewController.h"
#import "ContactGroup.h"
#import "NotificationView.h"
#import <QuartzCore/QuartzCore.h>
#import "Constants.h"
#import "JCMessagesViewController.h"



@interface JCPeopleSearchViewController ()
{
    NSMutableDictionary *personMap;
    UISearchDisplayController *searchDisplayController;
}
@property (strong, nonatomic) UIView* searchBarView;
@property (strong, nonatomic) UIScrollView* scrollView;
@property BOOL searchTableIsActive;
@property BOOL scrollDirectionIsUp;
@property BOOL doneAnimatingToolbarFromFirstResponderState;
@property float previousOffset;
@property float amountScrolledSinceLastDirectionChange;
@property float scrollViewOffsetReference;
@property float deltaOffsetSinceLastDirectionChange;
@property float deltaSearchBarY_SinceLastDirectionChange;
@property float searchBarY_Reference;
@property float scrollViewOffset;


@property (strong, nonatomic) JCSearchBar *searchBar;

@end

@implementation JCPeopleSearchViewController

static NSString *CellIdentifier = @"DirectoryCell";


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.previousOffset = 0;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"JCPersonCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    NSString *star = @"\u2605";
    sections = [NSArray arrayWithObjects:star, @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", nil];
    self.clientEntitiesArray = [[NSMutableArray alloc] init];
    self.clientEntitiesSearchArray = [[NSMutableArray alloc] init];
    self.doneAnimatingToolbarFromFirstResponderState = YES;
    [self.searchBarView addSubview:self.searchBar];
    [self.searchBar setShowsCancelButton:YES];
    [self.searchBar setDelegate:self];
    self.searchBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.searchBarView];
    [self.view insertSubview:self.searchBarView belowSubview:self.navigationBar];
    
    // detect when user tap's outside the search bar
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTapGesture)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
    
    searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    searchDisplayController.delegate = self;
    searchDisplayController.searchResultsDataSource = self;
    [searchDisplayController.searchResultsTableView setDelegate:self];
    [searchDisplayController.searchResultsTableView setDataSource:self];
    [self.tableView setContentInset:UIEdgeInsetsMake(108, 0, 0, 0)];
    
    
    
    
    
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


- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.searchBarView setFrame:CGRectMake(0, 20, self.searchBarView.bounds.size.width, self.searchBarView.bounds.size.height)];
                         [self.view insertSubview:self.navigationBar belowSubview:self.searchBarView];
                         UIImage *SearchIconImage = [UIImage imageNamed:@"people-search.png"];
                         UIImage *SearchIconImageWithRendering = [SearchIconImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                         [self.searchBar setImage:SearchIconImageWithRendering forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
                         
                     }
                     completion:nil];
    
    
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    self.doneAnimatingToolbarFromFirstResponderState = NO;
    [self.view insertSubview:self.searchBarView belowSubview:self.navigationBar];
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.searchBarView setFrame:CGRectMake(0, 64, self.searchBarView.bounds.size.width, self.searchBarView.bounds.size.height)];
                         
                         UIImage *SearchIconImage = [UIImage imageNamed:@"people-search-nonfocus.png"];
                         UIImage *SearchIconImageWithRendering = [SearchIconImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                         [self.searchBar setImage:SearchIconImageWithRendering forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
                         
                     }
                     completion:^(BOOL finished){
                         self.doneAnimatingToolbarFromFirstResponderState = YES;
                     }];
    [self.searchBar resignFirstResponder];
    return YES;
}

-(void)handleTapGesture{
    self.doneAnimatingToolbarFromFirstResponderState = NO;
    [UIView animateWithDuration:0.25
                          delay:0.15
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.searchBarView setFrame:CGRectMake(0, 64, self.searchBarView.bounds.size.width, self.searchBarView.bounds.size.height)];
                     }
                     completion:^(BOOL finished){
                         self.doneAnimatingToolbarFromFirstResponderState = YES;
                     }];
    [self.searchBar resignFirstResponder];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.scrollViewOffset = scrollView.contentOffset.y;
    
    if (!self.searchDisplayController.isActive){
        [self setSearchBarPosition:scrollView];
        [self handleScrollAtTop];
    }
    else if (self.searchDisplayController.isActive)
    {
        // keep the content view from scrolling off the screen.
        [self.searchBarView setFrame:CGRectMake(0, 20, self.searchBarView.bounds.size.width, self.searchBarView.bounds.size.height)];
        [self.searchDisplayController.searchResultsTableView setContentInset:UIEdgeInsetsMake(self.searchDisplayController.searchResultsTableView.contentInset.top, 0, 0, 0)];
    }
    
    self.previousOffset = self.scrollViewOffset;
}



-(void)handleScrollAtTop
{
    float frame_orgin_y = (-self.scrollViewOffset);
    if (self.scrollViewOffset <= -108) {
        if (self.searchBarView.frame.origin.y != frame_orgin_y) {
            NSLog(@"1 - Changed sFrame from %f to %f based on SVOffSet:%f", self.searchBarView.frame.origin.y, frame_orgin_y, self.scrollViewOffset);
        }
        self.searchBarView.frame = CGRectMake(self.searchBarView.frame.origin.x,
                                              frame_orgin_y + self.scrollViewOffset + 64,
                                              self.searchBarView.frame.size.width, self.searchBarView.frame.size.height);
        
        
        if (self.scrollView.contentInset.top != 108) NSLog(@"1 - Set Inset To: %f from: %f", 108.00000, self.scrollView.contentInset.top);
        self.scrollView.contentInset = UIEdgeInsetsMake(108 , 0, 0, 0);
    }
    
}

-(void)handleScrollUp
{
    const float UPPER_THREASHOLD = -64;// top of the window
    self.deltaOffsetSinceLastDirectionChange = abs(self.scrollViewOffsetReference - self.scrollViewOffset);
    float frame_orgin_y = (self.searchBarView.frame.origin.y <= UPPER_THREASHOLD) ? UPPER_THREASHOLD : (self.searchBarY_Reference - self.deltaOffsetSinceLastDirectionChange);
    if (self.searchBarView.frame.origin.y != frame_orgin_y) {
        NSLog(@"2 - Changed sFrame from %f to %f", self.searchBarView.frame.origin.y, frame_orgin_y);
    }
    self.searchBarView.frame = CGRectMake(self.searchBarView.frame.origin.x,
                                          frame_orgin_y,
                                          self.searchBarView.frame.size.width, self.searchBarView.frame.size.height);
    self.scrollDirectionIsUp = YES;
    if (self.scrollViewOffset > -64) {
        float inset = (frame_orgin_y + 44) < 64 ? 64 : frame_orgin_y + 44;
        if (self.scrollView.contentInset.top != inset) NSLog(@"2.1 - Changed Inset from: %f to: %f", self.scrollView.contentInset.top , inset);
        self.scrollView.contentInset = UIEdgeInsetsMake(inset , 0, 0, 0);
    }
    
}

- (void)scrollDirectionDidChangeToUp
{
    self.scrollViewOffsetReference = self.scrollViewOffset;
    self.searchBarY_Reference = self.searchBarView.frame.origin.y;
    
}

- (void)scrollDirectionDidChangeToDown
{
    self.scrollViewOffsetReference = self.scrollViewOffset;
    self.searchBarY_Reference = self.searchBarView.frame.origin.y;
}

-(void)handleScrollDown
{
    
    const float LOWER_THREASHOLD = 64;
    self.deltaOffsetSinceLastDirectionChange = (abs(self.scrollViewOffsetReference - self.scrollViewOffset));
    float frame_orgin_y = (self.searchBarView.frame.origin.y >= LOWER_THREASHOLD) ? LOWER_THREASHOLD : (self.searchBarY_Reference + self.deltaOffsetSinceLastDirectionChange);
    if (self.searchBarView.frame.origin.y != frame_orgin_y) {
        NSLog(@"3 - Changed sFrame from %f to %f", self.searchBarView.frame.origin.y, frame_orgin_y);
    }
    self.searchBarView.frame = CGRectMake(self.searchBarView.frame.origin.x,
                                          frame_orgin_y,
                                          self.searchBarView.frame.size.width, self.searchBarView.frame.size.height);
    self.scrollDirectionIsUp = NO;
    
    //set the inset - to control the position of the section headers.
    if (self.scrollViewOffset > 0) {
        float inset = (frame_orgin_y + 44) < 64 ? 64 : frame_orgin_y + 44;
        if (self.scrollView.contentInset.top != inset) NSLog(@"3 - Changed Inset from: %f to: %f", self.scrollView.contentInset.top, inset);
        self.scrollView.contentInset = UIEdgeInsetsMake(inset, 0, 0, 0);
    }
}


-(void)setSearchBarPosition:(UIScrollView *)scrollView
{
    self.scrollView = scrollView;
    if ((![self.searchBar isFirstResponder]) && (self.doneAnimatingToolbarFromFirstResponderState == YES))
    {
        self.amountScrolledSinceLastDirectionChange = abs(self.scrollViewOffsetReference - self.scrollViewOffset);
        
        if (self.scrollViewOffset > self.previousOffset)
        {// if scroll Direction is up
            if(self.scrollDirectionIsUp == NO)
            {// if this is the first call since the scroll direction changed
                [self scrollDirectionDidChangeToUp];
            }
            [self handleScrollUp];
        }
        else if((self.scrollViewOffset < self.previousOffset) && (self.previousOffset != 0))
        {//if scroll direction is down or this is first call when view loads
            if(self.scrollDirectionIsUp)
            {// if this is the first call since the scroll direction changed
                [self scrollDirectionDidChangeToDown];
            }
            [self handleScrollDown];
        }
    }
}


- (UIView *)searchBarView
{
    if (!_searchBarView) {
        _searchBarView = [[UIView alloc]initWithFrame:CGRectMake(0, 65, 320, 44)];
    }
    
    return _searchBarView;
}

-(JCSearchBar *)searchBar
{
    if (!_searchBar) {
        _searchBar = [[JCSearchBar alloc]initWithFrame:CGRectMake(0,0, self.searchBarView.frame.size.width, self.searchBarView.frame.size.height)];
        [_searchBar setBarTintColor:[UIColor whiteColor]];
        [_searchBar layoutSubviews];
        self.scrollViewOffsetReference = -64;
        self.searchBarY_Reference = -64;
        [self.view insertSubview:self.navigationBar belowSubview:self.searchBarView];
        
    }
    return _searchBar;
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
//    [[JCRESTClient sharedClient] RetrieveClientEntitites:^(id JSON) {
//        [self loadCompanyDirectory];
//        
//    } failure:^(NSError *err) {
//        NSLog(@"%@",[err description]);
//    }];
//    
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
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (self.searchDisplayController.active) {
        return nil;
    } else {
        return sections;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)index
{
    return index;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return @"Search Results";
    }else{
        return [sections objectAtIndex:section];
    }
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
    Lines *line;
    if(tableView == self.tableView){//redundant, but easier than rearranging all the if statements below.
        //only instantiate the cell this way, if it is not part of the searchResutls Table view.
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        line = self.clientEntitiesArray[indexPath.section][indexPath.row];
    }
    else{
        
        if (!cell) {
            cell = [[JCPersonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        NSString *entityId = self.clientEntitiesSearchArray[indexPath.row];
        line = [self getPersonFromListByEntityId:entityId];
    }
    
    if (line) {
        
        cell.line = line;
        
        //check to see if the person is a favorite
        if ([line.isFavorite boolValue]) {
            
            
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
   // [self performSegueWithIdentifier:@"JSMessagesViewController" sender:indexPath];
    [self dismissView:nil];
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


- (Lines *)getPersonFromListByEntityId:(NSString *)entityId
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
        [segue.destinationViewController setMessageType:JCNewConversationWithEntity];
    }
}

- (IBAction)refreshDirectory:(id)sender {
    [self refreshCompanyDirectory];
}
- (IBAction)dismissView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        //dismiss People search popup
    }];
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

