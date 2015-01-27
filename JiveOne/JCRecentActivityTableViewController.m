//
//  JCRecentActivityTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 10/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentActivityTableViewController.h"

// Views
#import "JCCallHistoryCell.h"
#import "JCVoicemailPlaybackCell.h"

// Data Models
#import "Call.h"
#import "Voicemail.h"
#import "Message.h"

// Managers
#import "JCPresenceManager.h"

NSString *const kJCHistoryCellReuseIdentifier = @"HistoryCell";
NSString *const kJCVoicemailCellReuseIdentifier = @"VoicemailCell";
NSString *const kJCMessageCellReuseIdentifier = @"MessageCell";

@implementation JCRecentActivityTableViewController

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable:) name:kJCPresenceManagerLinesChangedNotification object:[JCPresenceManager sharedManager]];
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
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"RecentEvent"];
        fetchRequest.includesSubentities = true;
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
        fetchRequest.sortDescriptors = @[sortDescriptor];
        
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                             managedObjectContext:self.managedObjectContext
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
    else if ([object isKindOfClass:[Message class]])
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kJCMessageCellReuseIdentifier];
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
    else if ([object isKindOfClass:[Message class]])
    {
        JCRecentEventCell *recentEventCell = (JCRecentEventCell *)cell;
        recentEventCell.recentEvent = (RecentEvent *)object;
        recentEventCell.textLabel.text = ((Message *)object).text;
    }
}

#pragma mark - Notification Handlers -
         
- (void)reloadTable:(NSNotification *)notification
{
    [self.tableView reloadData];
}

#pragma mark - Delegate Handlers -
         
#pragma mark UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RecentEvent *recentEvent = [self objectAtIndexPath:indexPath];
    if (self.delegate && [self.delegate respondsToSelector:@selector(recentActivityDidSelectRecentEvent:)]) {
        [self.delegate recentActivityDidSelectRecentEvent:recentEvent];
    }
}


@end
