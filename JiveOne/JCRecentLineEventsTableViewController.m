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

// Managers
#import "JCPresenceManager.h"

NSString *const kJCHistoryCellReuseIdentifier = @"HistoryCell";
NSString *const kJCVoicemailCellReuseIdentifier = @"VoicemailCell";
NSString *const kJCMessageCellReuseIdentifier = @"MessageCell";

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

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController)
    {
        NSManagedObjectContext *context = self.managedObjectContext;
        NSFetchRequest *fetchRequest = [RecentLineEvent MR_requestAllInContext:context];
        fetchRequest.includesSubentities = true;
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:NSStringFromSelector(@selector(date)) ascending:NO];
        fetchRequest.sortDescriptors = @[sortDescriptor];
        
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                             managedObjectContext:context
                                                                               sectionNameKeyPath:nil
                                                                                        cacheName:nil];
    }
    return _fetchedResultsController;
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
    if ([object isKindOfClass:[Call class]] && [cell isKindOfClass:[JCCallHistoryCell class]])
    {
        JCCallHistoryCell *historyCell = (JCCallHistoryCell *)cell;
        historyCell.call = (Call *)object;
    }
    else if ([object isKindOfClass:[Voicemail class]] && [cell isKindOfClass:[JCVoicemailCell class]])
    {
        JCVoicemailCell *voiceCell = (JCVoicemailCell *)cell;
        voiceCell.voicemail = (Voicemail *)object;
    }
}

#pragma mark - Notification Handlers -
         
- (void)reloadTable
{
    self.fetchedResultsController = nil;
    [self.tableView reloadData];
}



@end
