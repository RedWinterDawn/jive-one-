//
//  JCRecentActivityTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 10/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentLineEventsTableViewController.h"

// Views
#import "JCCallHistoryCell.h"
#import "JCVoicemailCell.h"

// Data Models
#import "Call.h"
#import "Voicemail.h"
#import "RecentLineEvent.h"
#import "MissedCall.h"

// Managers
#import "JCPresenceManager.h"

// Controllers
#import "JCNonVisualVoicemailViewController.h"

NSString *const kJCHistoryCellReuseIdentifier = @"HistoryCell";
NSString *const kJCVoicemailCellReuseIdentifier = @"VoicemailCell";
NSString *const kJCMessageCellReuseIdentifier = @"MessageCell";

@interface JCRecentLineEventsTableViewController ()
{
    NSFetchRequest *_fetchRequest;
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

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForObject:(id <NSObject>)object atIndexPath:(NSIndexPath*)indexPath;
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

- (void)configureCell:(JCTableViewCell *)cell withObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[RecentLineEvent class]] && [cell isKindOfClass:[JCRecentEventCell class]]) {
        RecentLineEvent *recentLineEvent = (RecentLineEvent *)object;
        JCRecentEventCell *recentEventCell = (JCRecentEventCell *)cell;
        recentEventCell.date.text     = recentLineEvent.formattedModifiedShortDate;
        recentEventCell.name.text     = recentLineEvent.titleText;
        recentEventCell.number.text   = recentLineEvent.detailText;
        recentEventCell.read          = recentLineEvent.isRead;
        Contact *contact = recentLineEvent.contact;
        if (contact) {
            recentEventCell.identifier = contact.jrn;
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

#pragma mark - IBActions -

-(IBAction)toggleFilterState:(id)sender
{
    if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
        self.viewFilter = segmentedControl.selectedSegmentIndex;
    }
}

#pragma mark - Setters -

-(void)setViewFilter:(JCRecentLineEventsViewFilters)viewFilter
{
    _viewFilter = viewFilter;
    self.fetchedResultsController = nil;
    [self.tableView reloadData];
    
    PBX *pbx = self.authenticationManager.pbx;
    if (viewFilter == JCRecentLineEventsViewVoicemails && !pbx.isV5) {
        [self showVoicemail];
    }
    else {
        [self hideVoicemail];
    }
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
    JCRecentLineEventsViewFilters viewFilter = self.viewFilter;
    NSFetchRequest *fetchRequest = nil;
    NSManagedObjectContext *context = self.managedObjectContext;
    
    Line *line = self.authenticationManager.line;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"line = %@", line];
    
    switch (viewFilter) {
        case JCRecentLineEventsViewMissedCalls:
            fetchRequest = [MissedCall MR_requestAllWithPredicate:predicate inContext:context];
            break;
         
        case JCRecentLineEventsViewVoicemails:
            fetchRequest = [Voicemail MR_requestAllWithPredicate:predicate inContext:context];
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

@end
