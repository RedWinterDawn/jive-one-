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
#import "JCDirectoryDetailViewController.h"
#import "JCDirectoryGroupViewController.h"
#import "ContactGroup.h"
#import "NotificationView.h"
#import <QuartzCore/QuartzCore.h>
#import "Constants.h"
#import "JCAppDelegate.h"
#import "JCStatusViewController.h"

#import "Membership+Custom.h"
#import "PBX+Custom.h"
#import "Lines+Custom.h"
#import "Lines+Custom.h"
#import "JasmineSocket.h"



@interface JCDirectoryViewController ()
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
@property (strong, nonatomic) NSString *star;
@property (strong, nonatomic) UIFont *icomoonFont;
@property (strong, nonatomic) UIColor *theRightShadeOfYellowForOurStar;
@property (strong, nonatomic) NSManagedObjectContext *context;


@property (strong, nonatomic) JCSearchBar *searchBar;

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
//    self.star = @"\ue600";
    self.star = @"\u2605";
    //self.icomoonFont = [UIFont fontWithName:@"icomoon" size:18.0];
    self.theRightShadeOfYellowForOurStar = [UIColor colorWithRed:255.0/255.0 green:212.0/255.0 blue:0.0/255.0 alpha:1.0];
    
    sections = [NSArray arrayWithObjects:self.star, @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", nil];
    self.clientEntitiesArray = [[NSMutableArray alloc] init];
    self.clientEntitiesSearchArray = [[NSMutableArray alloc] init];
    self.doneAnimatingToolbarFromFirstResponderState = YES;
    [self.searchBarView addSubview:self.searchBar];
    [self.searchBar setShowsCancelButton:YES];
    [self.searchBar setDelegate:self];
    self.searchBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.searchBarView];
    
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
    
    
    if (_delegate) {
        self.title = NSLocalizedString(@"To:", nil);
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissViewController:)];
        self.navigationItem.rightBarButtonItem = cancelButton;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subscribeLines:) name:@"socketDidOpen" object:nil];
    [[NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(eventForLine:) name:@"eventForLine" object:nil];

    
    [[JasmineSocket sharedInstance] initSocket];
    
}

- (void)dismissViewController:(id)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(dismissedByCanceling)]) {
        [_delegate dismissedByCanceling];
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        _delegate = nil;
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    personMap = [[NSMutableDictionary alloc] init];
    [self loadCompanyDirectory];
    if (self.searchTableIsActive) {
        [self.searchDisplayController.searchBar resignFirstResponder];
    }
    
    [(JCAppDelegate *)[UIApplication sharedApplication].delegate refreshTabBadges:NO];
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
                     }
                     completion:nil];
    
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    self.doneAnimatingToolbarFromFirstResponderState = NO;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.searchBarView setFrame:CGRectMake(0, 64, self.searchBarView.bounds.size.width, self.searchBarView.bounds.size.height)];
                         
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
//            NSLog(@"1 - Changed sFrame from %f to %f based on SVOffSet:%f", self.searchBarView.frame.origin.y, frame_orgin_y, self.scrollViewOffset);
        }
        self.searchBarView.frame = CGRectMake(self.searchBarView.frame.origin.x,
                                              frame_orgin_y + self.scrollViewOffset + 64,
                                              self.searchBarView.frame.size.width, self.searchBarView.frame.size.height);
        
        
//        if (self.scrollView.contentInset.top != 108) NSLog(@"1 - Set Inset To: %f from: %f", 108.00000, self.scrollView.contentInset.top);
        self.scrollView.contentInset = UIEdgeInsetsMake(108 , 0, 0, 0);
    }
    
}

-(void)handleScrollUp
{
    const float UPPER_THREASHOLD = -64;// top of the window
    self.deltaOffsetSinceLastDirectionChange = abs(self.scrollViewOffsetReference - self.scrollViewOffset);
    float frame_orgin_y = (self.searchBarView.frame.origin.y <= UPPER_THREASHOLD) ? UPPER_THREASHOLD : (self.searchBarY_Reference - self.deltaOffsetSinceLastDirectionChange);
    if (self.searchBarView.frame.origin.y != frame_orgin_y) {
//        NSLog(@"2 - Changed sFrame from %f to %f", self.searchBarView.frame.origin.y, frame_orgin_y);
    }
    self.searchBarView.frame = CGRectMake(self.searchBarView.frame.origin.x,
                                      frame_orgin_y,
                                      self.searchBarView.frame.size.width, self.searchBarView.frame.size.height);
    self.scrollDirectionIsUp = YES;
    if (self.scrollViewOffset > -64) {
        float inset = (frame_orgin_y + 44) < 64 ? 64 : frame_orgin_y + 44;
//        if (self.scrollView.contentInset.top != inset) NSLog(@"2.1 - Changed Inset from: %f to: %f", self.scrollView.contentInset.top , inset);
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
//        NSLog(@"3 - Changed sFrame from %f to %f", self.searchBarView.frame.origin.y, frame_orgin_y);
    }
    self.searchBarView.frame = CGRectMake(self.searchBarView.frame.origin.x,
                                      frame_orgin_y,
                                      self.searchBarView.frame.size.width, self.searchBarView.frame.size.height);
    self.scrollDirectionIsUp = NO;
    
    //set the inset - to control the position of the section headers.
    if (self.scrollViewOffset > 0) {
        float inset = (frame_orgin_y + 44) < 64 ? 64 : frame_orgin_y + 44;
//        if (self.scrollView.contentInset.top != inset) NSLog(@"3 - Changed Inset from: %f to: %f", self.scrollView.contentInset.top, inset);
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
    }
    return _searchBar;
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
        // retrieve entities where first name starts with letter of alphabet
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(displayName BEGINSWITH[c] %@)", section];
        sectionArray = [Lines MR_findAllWithPredicate:pred];
        

        // sort array with bases on firstLastName property
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
        NSArray *sortedArray= [sectionArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];

        if (noData) {
            noData = sortedArray.count == 0;
        }
        
        [self.clientEntitiesArray addObject:sortedArray];
    
    }
    
    if(noData)
    {
        NSLog(@"NoData - for company Directory");
//        NSArray *allPeople = [PersonEntities MR_findAll];
//        NSLog(@"All People Count = %lu", (unsigned long)allPeople.count);
        [self refreshCompanyDirectory];
    }
    
    [personMap removeAllObjects];
    [self.tableView reloadData];
}

- (IBAction)segmentChanged:sender {
    
    [self.clientEntitiesArray removeAllObjects];
    if ([self.segControl selectedSegmentIndex] == 0) {
        [self loadCompanyDirectory];
//        NSLog(@"First segment!");
    }
//        else {
//        [self loadLocalDirectory];
//        NSLog(@"Second Segment!");
//    }
    
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
//        if(section==0){
//            
//            return self.star;
//        }
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
    //PersonEntities *person;
    Lines *line;
    if(tableView == self.tableView){//redundant, but easier than rearranging all the if statements below.
        //only instantiate the cell this way, if it is not part of the searchResutls Table view.
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        //person = self.clientEntitiesArray[indexPath.section][indexPath.row];
        line = self.clientEntitiesArray[indexPath.section][indexPath.row];
    }
    else{

        if (!cell) {
            cell = [[JCPersonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        NSString *lineId = self.clientEntitiesSearchArray[indexPath.row];
        line = [self getLineFromListByLineId:lineId];
        //[self getPersonFromListByEntityId:entityId];
    }
    
    if (line) {
    
        cell.person = line;
        [cell.personNameLabel sizeToFit];
        [cell.personNameLabel setNumberOfLines:1];
        //check to see if the person is a favorite
//        if ([person.isFavorite boolValue]) {
//            
//            
//            NSMutableString *name = [[NSMutableString alloc]initWithString: cell.personNameLabel.text];
//            NSString *nameAndStarAsAnNSString = [NSString stringWithString:[name stringByAppendingString:[NSString stringWithFormat:@" %@",self.star]]];
//            
//            NSRange starLocation = [nameAndStarAsAnNSString rangeOfString:self.star];
//            NSMutableAttributedString *personAttributedName = [[NSMutableAttributedString alloc]initWithString:nameAndStarAsAnNSString];
//            [personAttributedName setAttributes:@{NSForegroundColorAttributeName : self.theRightShadeOfYellowForOurStar} range:starLocation];
//            cell.personNameLabel.font = self.icomoonFont;
//            cell.personNameLabel.attributedText = personAttributedName;
//        }
    }
    ((JCPersonCell *)cell).delegate = self;

    return cell;
 
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (tableView == self.searchDisplayController.searchResultsTableView) {
//        self.searchTableIsActive = YES;
//        
//    }else{
//        self.searchTableIsActive = NO;
//    }
//    
//    if (_delegate && [_delegate respondsToSelector:@selector(dismissedWithPerson:)]) {
//        
//        PersonEntities *person;
//        
//        if (self.searchTableIsActive) {
//            NSString *entityId = self.clientEntitiesSearchArray[indexPath.row];
//            person = [self getPersonFromListByEntityId:entityId];
//        }
//        else {
//            person = self.clientEntitiesArray[indexPath.section][indexPath.row];
//        }
//        
//        if (person) {
//            [_delegate dismissedWithPerson:person];
//            [self dismissViewControllerAnimated:YES completion:^{
//                _delegate = nil;
//            }];
//        }
//        
//    }
//    else {
//        [self performSegueWithIdentifier:@"directoryDetailView" sender:indexPath];
//    }
//    
//}

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
        //pred = [NSPredicate predicateWithFormat:@"(firstName contains[cd] %@) OR (lastName contains[cd] %@) OR (email contains[cd] %@)"
        pred = [NSPredicate predicateWithFormat:@"(displayName contains[cd] %@) OR (externsionNumber contains[cd] %@)"
                                  //OR (phoneNumber contains[cd] %@)", searchText
                                  , searchText, searchText];;
    } else {
        NSMutableArray *subPredicates = [[NSMutableArray alloc] init];
        for (NSString *term in searchTerms) {
            NSPredicate *p = [NSPredicate predicateWithFormat:@"(displayName contains[cd] %@) OR (externsionNumber contains[cd] %@)", term, term]; // OR (email contains[cd] %@)" OR (phoneNumber contains[cd] %@)", term
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
        results = [results valueForKeyPath:@"lineId"];
        [self.clientEntitiesSearchArray addObjectsFromArray:results];
    }
}

- (IBAction)searchPeople:(id)sender {
    
    [self.searchDisplayController.searchBar becomeFirstResponder];
    
}

//- (IBAction)showStatusView:(id)sender {
//    JCStatusViewController *stvc = [self.storyboard instantiateViewControllerWithIdentifier:@"JCStatusViewController"];
//    [self.navigationController pushViewController:stvc animated:YES];
//}

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

- (Lines *)getLineFromListByLineId:(NSString *)lineId
{
    for (NSArray *section in self.clientEntitiesArray) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lineId ==[c] %@", lineId];
        NSArray *result = [section filteredArrayUsingPredicate:predicate];
        
        if (result.count > 0) {
            Lines *line = result[0];
            return line;
        }
    }
    return nil;
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
    if (![segue.identifier isEqualToString:@"StatusSegue"] && ![segue.identifier isEqualToString:@"GroupSegue"]) {
    
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

#pragma mark - Socket Events Subscription
- (void) subscribeLines:(NSNotification *)notification
{
    for (NSArray * letterArray in self.clientEntitiesArray)
    {
        for (Lines *line in letterArray) {
            [[JasmineSocket sharedInstance] postSubscriptionsToSocketWithId:line.jrn entity:line.jrn type:@"dialog"];
        }
    }
    
}

- (void) eventForLine:(NSNotification *)notification
{
    NSDictionary *message = (NSDictionary *)notification.object;
    
    NSString *type = message[@"type"];
    NSString *subId = message[@"subId"];
    NSString *entity = message[@"entity"];
    
    NSString *dataId;
    NSString *participant;
    NSString *direction;
    NSString *state;
    NSString *remote;
    NSString *display;
    NSString *selfUrl;
    
    if (!self.context) {
        _context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    if (![message[@"data"] isKindOfClass:[NSNull class]]) {
        dataId = message[@"data"][@"id"];
        participant = message[@"data"][@"participant"];
        direction = message[@"data"][@"direction"];
        state = message[@"data"][@"state"];
        remote = message[@"data"][@"remote"];
        display = message[@"data"][@"display"];
        selfUrl = message[@"data"][@"self"];
    }
    
    
    // right now we only care about withdraws and confirmeds
    if ([type isEqualToString:@"withdraw"] || [state isEqualToString:@"confirmed"]) {
        Lines *line = [Lines MR_findFirstByAttribute:@"jrn" withValue:subId inContext:self.context];
        BOOL changed = NO;
        if (line) {
            if (state && [state isEqualToString:@"confirmed"]) {
                line.state = [NSNumber numberWithInt:(int) JCPresenceTypeDoNotDisturb];
                changed = YES;
            }
            else if (type && [type isEqualToString:@"withdraw"]) {
                line.state = [NSNumber numberWithInt:(int) JCPresenceTypeAvailable];
                changed = YES;
            }
            
            if (changed) {
                [self.context MR_saveToPersistentStoreAndWait];
            }            
        }
    }
}

@end







