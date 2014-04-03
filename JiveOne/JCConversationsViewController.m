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
#import "JCMessageViewController.h"
#import "ConversationEntry.h"
#import "JCConversationTableViewCell.h"
@interface JCConversationsViewController ()
{
    //NSMutableArray *entries;
    ClientEntities *me;
    NSMutableArray *conversations;
    NSManagedObjectContext *localContext;
    NSMutableDictionary *personMap;
    int newMessagesCount;
}

@end

@implementation JCConversationsViewController

static NSString *CellIdentifier = @"ConversationCell";

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"JCConversationCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];

    me = [[JCOmniPresence sharedInstance] me];
    
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self fetchLastConverstions];
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
    myBackButton.title = @"Messages";
    self.navigationItem.backBarButtonItem = myBackButton;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
        newMessagesCount++;
        // set a different back button for the navigation controller
        UIBarButtonItem *myBackButton = [[UIBarButtonItem alloc]init];
        myBackButton.title = [NSString stringWithFormat:@"Messages (%i)", newMessagesCount];
        self.navigationItem.backBarButtonItem = myBackButton;
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
    JCConversationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Conversation *conv = conversations[indexPath.row];
    
    if (conv) {
        cell.conversation = conv;
    }
    
//    if (!conv.isGroup) {
//        NSArray *entitiesArray = (NSArray*)conv.entities;
//        NSString *firstEntity = nil;
//        
//        for (NSString* entity in entitiesArray) {
//            if (![entity isEqualToString:me.urn]) {
//                firstEntity = entity;
//            }
//        }
//        
//        ClientEntities * person = [[JCOmniPresence sharedInstance] entityByEntityId:firstEntity];
//        
//        if (person) {
//            cell.person = person;
//        }
//        else
//        {
//            cell.person = nil;
//            cell.personNameLabel.text = @"Unknown";
//            cell.personDetailLabel.hidden = YES;
//            cell.personPicture.hidden = YES;
//        }
//        
////        cell.personNameLabel.text = [NSString stringWithFormat:@"%@", person.firstLastName];
////        cell.personDetailLabel.text = [NSString stringWithFormat:@"%@", person.email];
////        cell.personPresenceLabel.text = [self getPresence:[NSNumber numberWithInt:[person.entityPresence.interactions[@"chat"][@"code"] integerValue]]];
////        [cell.personPicture setImageWithURL:[NSURL URLWithString:person.picture] placeholderImage:[UIImage imageNamed:@"avatar.png"]];
////        cell.personId = person.entityId;
//        
//        
//        // temporary fix just to make it not crash
//        //if (firstEntity) {
//        //    [personMap setObject:[NSNumber numberWithInteger:indexPath.row] forKey:person.entityId];
//        //}
//        
//    }
//    else
//    {
//        cell.person = nil;
//        cell.personNameLabel.text = [NSString stringWithFormat:@"%@", conv.name];
//        cell.personDetailLabel.text = [NSString stringWithFormat:@"%@", conv.group];
//    }
    
    
    
    return cell;
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


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([sender isKindOfClass:[NSIndexPath class]]) {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        //Conversation *conv = conversations[indexPath.row];
        JCConversationTableViewCell *cell = (JCConversationTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
        NSString *title = cell.conversationTitle.text;
        
        [segue.destinationViewController setMessageType:JCExistingConversation];
        [segue.destinationViewController setConversationId:cell.conversation.conversationId];
        [segue.destinationViewController setTitle:title];
        
    }
    else if ([sender isKindOfClass:[NSString class]]) {
        [segue.destinationViewController setMessageType:JCNewConversation];
    }
    [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
}



- (IBAction)refreshConversations:(id)sender {
    [self fetchLastConverstions];
}@end
