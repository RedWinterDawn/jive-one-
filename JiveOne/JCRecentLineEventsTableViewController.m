//
//  JCRecentActivityTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 10/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentLineEventsTableViewController.h"

#import <JCPhoneModule/JCProgressHUD.h>

// Data Models
#import "Call.h"
#import "Voicemail+V5Client.h"
#import "RecentLineEvent.h"
#import "MissedCall.h"
#import "JCPhoneBook.h"
#import "JCMultiPersonPhoneNumber.h"

// Views
#import "JCCallHistoryCell.h"
#import "JCVoicemailCell.h"

// Managers
#import "JCPresenceManager.h"

// Controllers
#import "JCNonVisualVoicemailViewController.h"
#import "JCVoicemailDetailViewController.h"
#import "JCStoryboardLoaderViewController.h"
#import "JCContactDetailViewController.h"
#import "UIDevice+Additions.h"

NSString *const kJCHistoryCellReuseIdentifier = @"HistoryCell";
NSString *const kJCVoicemailCellReuseIdentifier = @"VoicemailCell";
NSString *const kJCMessageCellReuseIdentifier = @"MessageCell";

@interface JCRecentLineEventsTableViewController () <JCVoicemailDetailViewControllerDelegate>
{
    UIViewController *_voicemailViewController;
}

@end

@implementation JCRecentLineEventsTableViewController

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        JCAuthenticationManager *authenticationManager = self.authenticationManager;
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(reloadTable) name:kJCAuthenticationManagerLineChangedNotification object:authenticationManager];
        [center addObserver:self selector:@selector(reloadTable) name:kJCAuthenticationManagerUserLoggedOutNotification object:authenticationManager];
        [center addObserver:self selector:@selector(reloadTable) name:kJCAuthenticationManagerUserLoadedMinimumDataNotification object:authenticationManager];
        [center addObserver:self selector:@selector(reloadTable) name:kJCPresenceManagerLinesChangedNotification object:[JCPresenceManager sharedManager]];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForObject:(id <NSObject>)object atIndexPath:(NSIndexPath *)indexPath;
{
    if ([object isKindOfClass:[Call class]])
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kJCHistoryCellReuseIdentifier];
        [self configureCell:cell withObject:object];
        return cell;
    }
    else if ([object isKindOfClass:[Voicemail class]])
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kJCVoicemailCellReuseIdentifier];
        [self configureCell:cell withObject:object];
        return cell;
    }
    else
        return [super tableView:tableView cellForObject:object atIndexPath:indexPath];
}

-(void)deleteObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[Voicemail class]]) {
        Voicemail *voicemail = (Voicemail *)object;
        [voicemail markForDeletion:NULL];
    }
    else {
        [super deleteObject:object];
    }
}

- (void)configureCell:(JCTableViewCell *)cell withObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[RecentLineEvent class]] && [cell isKindOfClass:[JCRecentEventCell class]]) {
        RecentLineEvent *recentLineEvent = (RecentLineEvent *)object;
        JCRecentEventCell *recentEventCell = (JCRecentEventCell *)cell;
        recentEventCell.date.text     = recentLineEvent.formattedModifiedShortDate;
        recentEventCell.name.text     = recentLineEvent.titleText;
        recentEventCell.number.text   = recentLineEvent.detailText;
        recentEventCell.read          = recentLineEvent.isRead;
        InternalExtension *internalExtension = recentLineEvent.internalExtension;
        if (internalExtension) {
            recentEventCell.identifier = internalExtension.jrn;
        }
    }
    
    if ([object isKindOfClass:[Call class]] && [cell isKindOfClass:[JCCallHistoryCell class]])
    {
        JCCallHistoryCell *historyCell = (JCCallHistoryCell *)cell;
        historyCell.icon.image = ((Call *)object).icon;
    }
    else if ([object isKindOfClass:[Voicemail class]] && [cell isKindOfClass:[JCVoicemailCell class]])
    {
        JCVoicemailCell *voiceCell = (JCVoicemailCell *)cell;
        Voicemail *voicemail = (Voicemail *)object;
        voiceCell.duration.text = voicemail.displayDuration;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        viewController = ((UINavigationController *)viewController).topViewController;
    }
    
    if ([viewController isKindOfClass:[JCStoryboardLoaderViewController class]]) {
        viewController = ((JCStoryboardLoaderViewController *)viewController).embeddedViewController;
    }
    
    RecentLineEvent *recentLineEvent;
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender];
        recentLineEvent = (RecentLineEvent *)[self objectAtIndexPath:indexPath];
    }
    else if([sender isKindOfClass:[RecentLineEvent class]]) {
        recentLineEvent = (RecentLineEvent *)sender;
    }
    
    if ([viewController isKindOfClass:[JCVoicemailDetailViewController class]] && recentLineEvent && [recentLineEvent isKindOfClass:[Voicemail class]]) {
        JCVoicemailDetailViewController *voicemailDetailViewController = (JCVoicemailDetailViewController *)viewController;
        voicemailDetailViewController.voicemail = (Voicemail *)recentLineEvent;
        voicemailDetailViewController.delegate = self;
    }
    
    else if ([viewController isKindOfClass:[JCContactDetailViewController class]] && recentLineEvent){
        InternalExtension *internalExtension = recentLineEvent.internalExtension;
        NSArray *localContacts = recentLineEvent.phoneNumbers.allObjects;
        id<JCPhoneNumberDataSource> phoneNumber;
        if (internalExtension) {
            phoneNumber = internalExtension;
        }
        else if (localContacts.count > 0) {
            if (localContacts.count > 1) {
                phoneNumber = [JCMultiPersonPhoneNumber multiPersonPhoneNumberWithPhoneNumbers:localContacts];
            } else {
                phoneNumber = localContacts.firstObject;
            }
        }
        else {
            phoneNumber = [self.phoneBook phoneNumberForNumber:recentLineEvent.number
                                                              name:recentLineEvent.name
                                                            forPbx:recentLineEvent.line.pbx
                                                     excludingLine:recentLineEvent.line];
        }
        ((JCContactDetailViewController *)viewController).phoneNumber = phoneNumber;
    }
}

#pragma mark - IBActions -

-(IBAction)refreshData:(id)sender
{
    if ([sender isKindOfClass:[UIRefreshControl class]]) {
        Line *line = self.authenticationManager.line;
        [Voicemail downloadVoicemailsForLine:line completion:^(BOOL success, NSError *error) {
            [((UIRefreshControl *)sender) endRefreshing];
            if (error) {
                [self showError:error];
            }
        }];
    }
}

-(IBAction)toggleFilterState:(id)sender
{
    if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
        self.viewFilter = segmentedControl.selectedSegmentIndex;
    }
}

#pragma mark - Setters -

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    PBX *pbx = self.authenticationManager.pbx;
    if (self.viewFilter == JCRecentLineEventsViewVoicemails && !pbx.isV5) {
        [self showVoicemail];
    }
    else {
        [self hideVoicemail];
    }
}

-(void)setViewFilter:(JCRecentLineEventsViewFilter)viewFilter
{
    _viewFilter = viewFilter;
    self.fetchedResultsController = nil;
    if ([UIDevice currentDevice].iOS8) {
        [self.tableView reloadData];
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }
}

- (IBAction)clear:(id)sender
{
    NSPredicate *predicate = self.fetchedResultsController.fetchRequest.predicate;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSArray *eventsToDelete = nil;
        
        switch (self.viewFilter) {
            case JCRecentLineEventsViewAllCalls:
                eventsToDelete = [Call MR_findAllWithPredicate:predicate inContext:localContext];
                break;
                
            case JCRecentLineEventsViewMissedCalls:
                eventsToDelete = [MissedCall MR_findAllWithPredicate:predicate inContext:localContext];
                break;
                
            case JCRecentLineEventsViewVoicemails:
                eventsToDelete = [Voicemail MR_findAllWithPredicate:predicate inContext:localContext];
                break;
                
            default:
                break;
        }
        
        for (MissedCall *event in eventsToDelete) {
            [event markForDeletion:NULL];
        }
    }];
}

#pragma mark - Getters -

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController)
    {
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                                             managedObjectContext:self.managedObjectContext
                                                                               sectionNameKeyPath:nil
                                                                                        cacheName:nil];
    }
    return _fetchedResultsController;
}

-(NSFetchRequest *)fetchRequest
{
    JCRecentLineEventsViewFilter viewFilter = self.viewFilter;
    NSFetchRequest *fetchRequest = nil;
    NSManagedObjectContext *context = self.managedObjectContext;
    
    Line *line = self.authenticationManager.line;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"line = %@ && markForDeletion = %@", line, @NO];
    
    switch (viewFilter) {
        case JCRecentLineEventsViewMissedCalls:
            fetchRequest = [MissedCall MR_requestAllWithPredicate:predicate inContext:context];
            break;
         
        case JCRecentLineEventsViewVoicemails:
            fetchRequest = [Voicemail MR_requestAllWithPredicate:predicate inContext:context];
            break;
            
        case JCRecentLineEventsViewAllCalls:
            fetchRequest = [Call MR_requestAllWithPredicate:predicate inContext:context];
            break;
            
        default:
            fetchRequest = [RecentLineEvent MR_requestAllWithPredicate:predicate inContext:context];
            fetchRequest.includesSubentities = TRUE;
            break;
    }
    
    fetchRequest.fetchBatchSize = 6;
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:false];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    return fetchRequest;
}

-(void)showVoicemail
{
    UIViewController *viewController = self.voicemailViewController;
    [self addChildViewController:viewController];
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    viewController.view.frame = self.view.bounds;
    viewController.view.translatesAutoresizingMaskIntoConstraints = TRUE;
    viewController.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:viewController.view];
    [self.view bringSubviewToFront:viewController.view];
}

-(void)hideVoicemail
{
    if (!_voicemailViewController) {
        return;
    }
    
    UIViewController *viewController = self.voicemailViewController;
    [viewController removeFromParentViewController];
    [viewController.view removeFromSuperview];
    _voicemailViewController = nil;
}

-(UIViewController *)voicemailViewController {
    if (!_voicemailViewController) {
        _voicemailViewController = [[JCNonVisualVoicemailViewController alloc] initWithNibName:nil bundle:nil];
    }
    return _voicemailViewController;
}

#pragma mark - Notification Handlers -
         
- (void)reloadTable
{
    self.fetchedResultsController = nil;
    [self.tableView reloadData];
}

- (void)voicemailDetailViewControllerDidDeleteVoicemail:(JCVoicemailDetailViewController *)controller
{
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        [self performSegueWithIdentifier:@"Dialer" sender:self];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
