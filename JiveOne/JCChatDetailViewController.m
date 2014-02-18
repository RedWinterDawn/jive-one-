//
//  JCChatDetailViewController.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCChatDetailViewController.h"
#import "ClientEntities.h"
#import "JCEntryModel.h"
#import "JCSocketDispatch.h"
#import "JCOsgiClient.h"
#import "JCChatMessage.h"
#import "UIImageView+WebCache.h"
#import "MyEntity.h"


@interface JCChatDetailViewController ()
{
    MyEntity *me;
}

@end

@implementation JCChatDetailViewController

#define kSubtitleJobs @"Jobs"
#define kSubtitleWoz @"Steve Wozniak"
#define kSubtitleCook @"Mr. Cook"

- (void)setChatEntries:(NSMutableArray *)chatEntries
{
    if (![chatEntries isEqual:_chatEntries]) {
        _chatEntries = chatEntries;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[JCSocketDispatch sharedInstance] requestSession];
    
    me = [MyEntity MR_findFirst];
    
    NSString* fontName = @"Avenir-Book";
    //NSString* boldFontName = @"Avenir-Black";

    
    self.dataSource = self;
    self.delegate = self;
    
    [[JSBubbleView appearance] setFont:[UIFont fontWithName:fontName size:14.0f]];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_chatEntries) {
        NSDictionary *conversation = _chatEntries[0];
        NSString *conversationId = [conversation objectForKey:@"conversation"];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingChatEntry:) name:conversationId object:nil];
    }
    
    //self.navigationController.tabBarController.tabBar.hidden = YES;
    self.navigationController.toolbarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.navigationController.tabBarController.tabBar.hidden = NO;
    self.navigationController.toolbarHidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Incoming chat
- (void)incomingChatEntry:(NSNotification*)notification
{
    NSDictionary* chatEntry = (NSDictionary*)notification.object;
    NSMutableArray* temp = [[NSMutableArray alloc] initWithArray:_chatEntries];
    [temp addObject:chatEntry];
    _chatEntries = [[NSMutableArray alloc] initWithArray:temp];
    
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_chatEntries.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView scrollRectToVisible:self.tableView.tableFooterView.frame animated:YES];
}

#pragma mark - Table view data source



//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    // Return the number of sections.
//    return 1;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.chatEntries.count;
}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *CellIdentifier = @"Cell";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
//    
//    NSDictionary* singleEntry = self.chatEntries[indexPath.row];
//    NSString* firstEntity = [singleEntry objectForKey:@"entity"];
//    NSString* message = [[singleEntry objectForKey:@"message"] objectForKey:@"raw"];
//    
//    //JCEntryModel* entryModel = [[JCEntryModel alloc] initWithDictionary:singleEntry error:nil];
//    NSArray* result = [ClientEntities MR_findByAttribute:@"entityId" withValue:firstEntity];
//    ClientEntities* person = (ClientEntities*)result[0];
//    
//    cell.textLabel.text = [NSString stringWithFormat:@"%@", message ];
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", person.firstLastName];
//
//    
//    return cell;
//}

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

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

- (IBAction)sendMessage:(id)sender {
    
    //need to refactor this
    NSDictionary* singleEntry = self.chatEntries[0];
    NSString* entity = me.urn;
    NSString* conversationUrn = [singleEntry objectForKey:@"conversation"];
    NSString *message = @"this is my message";
    
    [[JCOsgiClient sharedClient] SubmitChatMessageForConversation:conversationUrn message:message withEntity:entity success:^(id JSON) {
        // update UI
    } failure:^(NSError *err) {
        // update UI
    }];
}

#pragma mark - Messages view delegate: REQUIRED

- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date
{
    if ((self.chatEntries.count - 1) % 2) {
        [JSMessageSoundEffect playMessageSentSound];
    }
    else {
        // for demo purposes only, mimicing received messages
        [JSMessageSoundEffect playMessageReceivedSound];
        sender = arc4random_uniform(10) % 2 ? kSubtitleCook : kSubtitleWoz;
    }
    
    [self.chatEntries addObject:[[JCChatMessage alloc] initWithText:@"test" sender:@"me" date:[NSDate date]]];
    [self finishSend];
    [self scrollToBottomAnimated:YES];
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row % 2) {
        return [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                          color:[UIColor js_bubbleLightGrayColor]];
    }
    
    return [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                      color:[UIColor js_bubbleBlueColor]];
}

- (BOOL)shouldDisplayTimestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [NSDate date];
}

#pragma mark - Messages view data source: REQUIRED

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary* singleEntry = self.chatEntries[indexPath.row];
    NSString* firstEntity = [singleEntry objectForKey:@"entity"];
    
    if ([firstEntity isEqualToString:me.urn]) {
        return JSBubbleMessageTypeOutgoing;
    }
    else {
        return JSBubbleMessageTypeIncoming;
    }
}

- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* singleEntry = self.chatEntries[indexPath.row];
    NSString* message = [[singleEntry objectForKey:@"message"] objectForKey:@"raw"];
    return message;
}

- (JSMessagesViewTimestampPolicy)timestampPolicy
{
    return JSMessagesViewTimestampPolicyAll;
}

- (JSMessagesViewAvatarPolicy)avatarPolicy
{
    return JSMessagesViewAvatarPolicyAll;
}

- (JSMessagesViewSubtitlePolicy)subtitlePolicy
{
    return JSMessagesViewSubtitlePolicyAll;
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* singleEntry = self.chatEntries[indexPath.row];
    NSString* firstEntity = [singleEntry objectForKey:@"entity"];
    
    //ClientEntities* person = [ClientEntities MR_findByAttribute:@"id" withValue:firstEntity];
    NSArray* result = [ClientEntities MR_findByAttribute:@"entityId" withValue:firstEntity];
    ClientEntities *person = (ClientEntities*)result[0];
    
    UIImageView *image = [[UIImageView alloc] init];
    [image setImageWithURL:[NSURL URLWithString:person.picture] placeholderImage:[UIImage imageNamed:@"avatar.png"]];    
    return image;
}

- (NSString *)subtitleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"";
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath sender:(NSString *)sender
{
    //UIImage *image = [self.avatars objectForKey:sender];
    return nil; // [[UIImageView alloc] initWithImage:image];
}
@end
