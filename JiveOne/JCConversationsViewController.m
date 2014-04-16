//
//  JCRecentViewController.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationsViewController.h"
#import "JCOsgiClient.h"
#import "JCEntryModel.h"
#import "ClientEntities.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "JCMessagesViewController.h"
#import "ConversationEntry.h"
#import "JCConversationCell.h"
#import "JCGroupConversationCell.h"
@interface JCConversationsViewController ()
{
    //NSMutableArray *entries;
    ClientEntities *me;
    NSMutableArray *conversations;
    NSManagedObjectContext *localContext;
    NSMutableDictionary *personMap;
    int newMessagesCount;
}

@property (nonatomic) NSString *currentConversationId;

@end

@implementation JCConversationsViewController

static NSString *CellIdentifier = @"twoPersonChatCell";
static NSString *GroupCellIdentifier = @"GroupChatCell";


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[JCConversationCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[JCGroupConversationCell class] forCellReuseIdentifier:GroupCellIdentifier];

    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];

    me = [[JCOmniPresence sharedInstance] me];
    
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self fetchLastConverstions];
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]
                                        init];
    [refreshControl addTarget:self action:@selector(updateTable) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadDatasource];
    
    if (!localContext) {
        localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    personMap = [[NSMutableDictionary alloc] init];
    newMessagesCount = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveConversation:) name:kNewConversation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdatePresence:) name:kPresenceChanged object:nil];
    
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:localContext];
    
    // set a different back button for the navigation controller
    UIBarButtonItem *myBackButton = [[UIBarButtonItem alloc]init];
    myBackButton.title = @"";
    self.navigationItem.backBarButtonItem = myBackButton;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)updateTable
{
    [self fetchLastConverstions];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void) loadDatasource
{
    conversations = [NSMutableArray arrayWithArray:[Conversation MR_findByAttribute:@"hasEntries" withValue:[NSNumber numberWithBool:YES] andOrderBy:@"lastModified" ascending:NO]];
    [personMap removeAllObjects];
    [self.tableView reloadData];
}

- (IBAction)startNewConversation:(id)sender {
    
    
    [self performSegueWithIdentifier:@"MessageSegue" sender:kNewConversation];
}


- (void)fetchLastConverstions
{
    [[JCOsgiClient sharedClient] RetrieveConversations:^(id JSON) {
        
        [self loadDatasource];
        
    } failure:^(NSError *err) {
        NSLog(@"%@",[err description]);
        [self loadDatasource];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Update UI on Presence Change
- (void)didUpdatePresence:(NSNotification*)notification
{
//    Presence *presence = (Presence*)notification.object;
//    NSMutableArray *indexPaths = [NSMutableArray array];
//    
//    // first we check in our simple structure
//    if (personMap && personMap[presence.entityId]) {
//        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[personMap[presence.entityId] integerValue] inSection:0];
//        [indexPaths addObject:indexPath];
//    }
//    else
//    {
//        for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:0]; ++i)
//        {
//            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
//            JCPersonCell *cell = (JCPersonCell*)[self.tableView cellForRowAtIndexPath:indexPath];
//            if ([cell.personId isEqualToString:presence.entityId]) {
//                [indexPaths addObject:indexPath];
//                break;
//            }
//        }
//    }
//    
//    if (indexPaths.count != 0) {
//        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
//    }
}

#pragma mark - Did receive Notication
- (void)didReceiveConversation:(NSNotification*)notification
{
    if (!self.view.window) {
        Conversation *conversation = (Conversation *)notification.object;
        if (_currentConversationId && [_currentConversationId isEqualToString:conversation.conversationId]) {
            NSLog(@"Received Conversation that is currently selected. So don't update Back button");
        }
        else
        {
            newMessagesCount++;
            // set a different back button for the navigation controller
            UIBarButtonItem *myBackButton = [[UIBarButtonItem alloc]init];
            myBackButton.title = [NSString stringWithFormat:@"Messages (%i)", newMessagesCount];
            self.navigationItem.backBarButtonItem = myBackButton;

        }
    }
    
    [self loadDatasource];
    [self refreshConversations:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    // Return the number of rows in the section.
    return conversations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Conversation *conv = conversations[indexPath.row];
    
    if(!conv){
        return nil;
    }
    
        if (conv.isGroup) {
            JCGroupConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:GroupCellIdentifier forIndexPath:indexPath];
            cell.conversation = conv;
            return cell;

            
        }else {
            JCConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            cell.conversation = conv;
            return cell;
        
        }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"MessageSegue" sender:indexPath];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        Conversation *conv = conversations[indexPath.row];
        [conversations removeObjectAtIndex:indexPath.row];
        [conv MR_deleteEntity];
        [localContext MR_saveToPersistentStoreAndWait];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (NSString *)getPresence:(NSNumber *)presence
{
    switch ([presence integerValue]) {
        case JCPresenceTypeAvailable:
            return kPresenceAvailable;
            break;
        case JCPresenceTypeAway:
            return kPresenceAway;
            break;
        case JCPresenceTypeBusy:
            return kPresenceBusy;
            break;
        case JCPresenceTypeDoNotDisturb:
            return kPresenceDoNotDisturb;
            break;
        case JCPresenceTypeInvisible:
            return kPresenceInvisible;
            break;
        case JCPresenceTypeOffline:
            return kPresenceOffline;
            break;
            
        default:
            return @"Unknown";
            break;
    }
}



#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([sender isKindOfClass:[NSIndexPath class]]) {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        //Conversation *conv = conversations[indexPath.row];
        JCConversationCell *cell = (JCConversationCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
        NSString *title = cell.conversationTitle.text;
        
        [segue.destinationViewController setMessageType:JCExistingConversation];
        [segue.destinationViewController setConversationId:cell.conversation.conversationId];
        [segue.destinationViewController setTitle:title];
        
        _currentConversationId = cell.conversation.conversationId;
    }
    else if ([sender isKindOfClass:[NSString class]]) {
        [segue.destinationViewController setMessageType:JCNewConversation];
        _currentConversationId = nil;
    }
    [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
}



- (IBAction)refreshConversations:(id)sender {
    [self fetchLastConverstions];
}@end
