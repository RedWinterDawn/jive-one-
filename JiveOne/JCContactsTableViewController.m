//
//  JCContactsTableViewController.m
//  JiveOne
//
//  Created by Eduardo  Gueiros on 10/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCContactsTableViewController.h"
#import "Lines+Custom.h"
#import "JCPersonCell.h"

@interface JCContactsTableViewController ()
{
    UISearchDisplayController *searchDisplayController;
}

@property (nonatomic, strong) NSFetchedResultsController *searchFetchedResultController;
@property (strong, nonatomic) JCSearchBar *searchBar;

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


@end

@implementation JCContactsTableViewController

static NSString *CellIdentifier = @"DirectoryCell";

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[UINib nibWithNibName:@"JCPersonCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
    [self searchViewSetup];
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.searchTableIsActive) {
        [self.searchDisplayController.searchBar resignFirstResponder];
    }
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController)
    {
        NSFetchRequest *fetchRequest = [Lines MR_requestAll];
        fetchRequest.fetchBatchSize = 10;
        
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        NSSortDescriptor *favSort = [NSSortDescriptor sortDescriptorWithKey:@"isFavorite" ascending:NO];
        fetchRequest.sortDescriptors = [NSArray arrayWithObjects:favSort, sort , nil];
        
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"firstLetter" cacheName:nil];
    }
    
    return _fetchedResultsController;
}

- (NSFetchedResultsController *)controllerForTableView:(UITableView *)tableView
{
    return tableView == self.tableView ? self.fetchedResultsController : self.fetchedResultsController;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    NSInteger count = [[[self controllerForTableView:tableView] sections] count];
    return count;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    id <NSFetchedResultsSectionInfo> sectionInfo = [[[self controllerForTableView:tableView] sections] objectAtIndex:section];
    
    NSInteger count = [sectionInfo numberOfObjects];
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];   
    [self configureCell:cell atIndexPath:indexPath forTableView:tableView];
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [self.fetchedResultsController sectionIndexTitles];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self controllerForTableView:tableView] sectionIndexTitles][section];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)tableView
{
    [self configureCell:cell atIndexPath:indexPath];
    ((JCPersonCell *)cell).line = [[self controllerForTableView:tableView] objectAtIndexPath:indexPath];
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    JCPersonCell *personCell = (JCPersonCell *)cell;
    Lines *line = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    if (line) {
        personCell.line = line;
        [personCell.personNameLabel sizeToFit];
        [personCell.personNameLabel setNumberOfLines:1];
    }
}

- (NSArray *)reorderHeaders:(NSArray *)headers
{
    NSMutableArray *sectionTitles = [NSMutableArray arrayWithArray:headers];
    
    if ([sectionTitles containsObject:@"\u2605"]) {
        NSInteger index = [sectionTitles indexOfObject:@"\u2605"];
        [sectionTitles removeObjectAtIndex:index];
        [sectionTitles insertObject:@"\u2605" atIndex:0];
    }
    
    return sectionTitles;
}

#pragma mark - Search Delegates
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    _searchFetchedResultController.delegate = nil;
    _searchFetchedResultController = nil;
}


#pragma mark - Search Bar
- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView;
{
    // search is done so get rid of the search FRC and reclaim memory
    _searchFetchedResultController.delegate = nil;
    _searchFetchedResultController = nil;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text]
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    return YES;
}

#pragma mark - Search View Setup
- (void) searchViewSetup
{
    //setup search view
    self.previousOffset = 0;
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







@end
