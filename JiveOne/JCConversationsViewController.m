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
#import "JCConversationDetailViewController.h"
#import "ConversationEntry.h"

@interface JCConversationsViewController ()
{
    //NSMutableArray *entries;
    ClientEntities *me;
    NSMutableArray *conversations;
    NSManagedObjectContext *localContext;
}

@end

@implementation JCConversationsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    me = [[JCOmniPresence sharedInstance] me];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self loadDatasource];
    [self fetchLastConverstions];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!localContext) {
        localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveConversation:) name:@"NewConversation" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) loadDatasource
{
    conversations = [NSMutableArray arrayWithArray:[Conversation MR_findAllSortedBy:@"lastModified" ascending:FALSE]];
    [self.tableView reloadData];

}


- (void)fetchLastConverstions
{
    [[JCOsgiClient sharedClient] RetrieveConversations:^(id JSON) {
       
        [self loadDatasource];
        
    } failure:^(NSError *err) {
        NSLog(@"%@",[err description]);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didReceiveJsonObject:(NSArray*)conversationArray
{
    

}

#pragma mark - Did receive Notication
- (void)didReceiveConversation:(NSNotification*)notification
{
//    NSDictionary *conversation = (NSDictionary*)notification.object;
//    
//    //NSDictionary *entry = conversation[@"data"][@"body"];
//    
//    Conversation *conv = [Conversation MR_createInContext:localContext];
//    conv.createdDate = conversation[@"createdDate"];
//    conv.lastModified = conversation[@"lastModified"];
//    //conv.urn = conversation[@"urn"];
//    conv.conversationId = conversation[@"conversation"];
//    
//    if (conversation[@"group"] && conversation[@"name"]) {
//        conv.isGroup = [NSNumber numberWithBool:YES];
//        conv.group = conversation[@"group"];
//        conv.name = conversation[@"name"];
//        //conv.conversationId = conversation[@"groupId"];
//    }
//    else {
//        //conv.conversationId = conversation[@"_id"];
//        conv.entities = conversation[@"entities"];
//    }   
//    
//    ConversationEntry *convEntry = [ConversationEntry MR_createInContext:localContext];
//    convEntry.conversationId = conversation[@"conversation"];
//    convEntry.entityId = conversation[@"entity"];
//    convEntry.createdDate = conversation[@"createDate"];
//    convEntry.call = conversation[@"call"];
//    convEntry.file = conversation[@"file"];
//    convEntry.message = conversation[@"message"];
//    convEntry.mentions = conversation[@"mentions"];
//    convEntry.tags = conversation[@"tags"];
//    convEntry.deliveryDate = conversation[@"deliveryDate"];
//    convEntry.type = conversation[@"type"];
//    convEntry.urn = conversation[@"urn"];
//    convEntry.entryId = conversation[@"id"];
//    
//    //Save conversation entry
//    [localContext MR_saveToPersistentStoreAndWait];
    
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
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Conversation *conv = conversations[indexPath.row];
    
    if (!conv.isGroup) {
        NSArray *entitiesArray = (NSArray*)conv.entities;
        NSString *firstEntity = nil;
        
        for (NSString* entity in entitiesArray) {
            if (![entity isEqualToString:me.urn]) {
                firstEntity = entity;
            }
        }
        
        NSArray* result = [ClientEntities MR_findByAttribute:@"entityId" withValue:firstEntity];
        ClientEntities * person = (ClientEntities*)result[0];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@", person.firstLastName];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", conv.lastModified];
        [cell.imageView setImageWithURL:[NSURL URLWithString:person.picture] placeholderImage:[UIImage imageNamed:@"avatar.png"]];
        
    }
    else
    {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", conv.name];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", conv.group];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Conversation *conv = conversations[indexPath.row];
    //NSString *conversationId = conv.conversationId;
    [self performSegueWithIdentifier:@"ChatDetailSegue" sender:conv.conversationId];
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
    [segue.destinationViewController setConversationId:sender];
    [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
}



- (IBAction)refreshConversations:(id)sender {
    [self fetchLastConverstions];
}
@end
