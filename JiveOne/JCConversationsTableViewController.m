//
//  JCConversationsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationsTableViewController.h"

#import "JCMessagesViewController.h"
#import "JCMessageParticipantTableViewController.h"
#import "Message.h"
#import "JCNavigationController.h"
#import "JCConversationTableViewCell.h"
#import "SMSMessage+SMSClient.h"

NSString *const kJCConversationsTableViewController = @"ConversationCell";

@interface JCConversationsTableViewController ()

@end

@implementation JCConversationsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _fetchedResultsController = nil;
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    _fetchedResultsController = nil;
}

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        
        NSFetchRequest *fetchRequest = [Message MR_requestAllInContext:self.managedObjectContext];
        fetchRequest.includesSubentities = YES;
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(date )) ascending:NO]];
        fetchRequest.resultType = NSDictionaryResultType;
        fetchRequest.propertiesToGroupBy = @[@"messageGroupId"];
        fetchRequest.propertiesToFetch = @[@"messageGroupId"];
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                             managedObjectContext:self.managedObjectContext
                                                                               sectionNameKeyPath:nil
                                                                                        cacheName:nil];
        __autoreleasing NSError *error = nil;
        if ([_fetchedResultsController performFetch:&error]) {
            [self.tableView reloadData];
        }
        
    }
    return _fetchedResultsController;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForObject:(id<NSObject>)object atIndexPath:(NSIndexPath *)indexPath {
    JCConversationTableViewCell *cell = (JCConversationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kJCConversationsTableViewController];
    [self configureCell:cell withObject:object];
    return cell;
}

-(id<NSObject>)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

-(void)configureCell:(JCConversationTableViewCell *)cell withObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *entity = (NSDictionary *)object;
        cell.messageGroupId = [entity stringValueForKey:NSStringFromSelector(@selector(messageGroupId))];
    }
}

- (IBAction)refreshTable:(id)sender {
    if ([sender isKindOfClass:[UIRefreshControl class]]) {
        PBX *pbx = [JCAuthenticationManager sharedInstance].pbx;
        [SMSMessage downloadMessagesForDIDs:pbx.dids completion:^(BOOL success, NSError *error) {
            [((UIRefreshControl *)sender) endRefreshing];
            if (success) {
                _fetchedResultsController = nil;
                [self.tableView reloadData];
            } else {
                [self showError:error];
            }
        }];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        UIViewController *viewController = segue.destinationViewController;
        if ([viewController isKindOfClass:[JCMessagesViewController class]]) {
            JCMessagesViewController *messagesViewController = (JCMessagesViewController *)viewController;
            NSDictionary *entity = (NSDictionary *)[self objectAtIndexPath:[self.tableView indexPathForCell:sender]];
            messagesViewController.messageGroupId = [entity stringValueForKey:NSStringFromSelector(@selector(messageGroupId))];
        }
    }
}

@end
