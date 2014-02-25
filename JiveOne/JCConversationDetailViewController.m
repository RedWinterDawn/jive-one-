//
//  JCChatDetailViewController.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationDetailViewController.h"
#import "ClientEntities.h"
#import "JCEntryModel.h"
#import "JCSocketDispatch.h"
#import "JCOsgiClient.h"
#import "JCChatMessage.h"
#import "UIImageView+WebCache.h"
#import "ConversationEntry.h"


@interface JCConversationDetailViewController ()
{
    ClientEntities *me;
    UITextView *messageTextView;
    NSMutableArray *chatEntries;
}

@end

@implementation JCConversationDetailViewController

#define kSubtitleJobs @"Jobs"
#define kSubtitleWoz @"Steve Wozniak"
#define kSubtitleCook @"Mr. Cook"


- (void)setConversationId:(NSString *)conversationId
{
    if (!_conversationId || ![_conversationId isEqualToString:conversationId]) {
        _conversationId = conversationId;
        [self loadDatasource];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    me = [[JCOmniPresence sharedInstance] me];
    
    //NSString* fontName = @"Avenir-Book";
    //NSString* boldFontName = @"Avenir-Black";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    messageTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 35)];

    
    UIBarButtonItem *messageBarItemTextView = [[UIBarButtonItem alloc] initWithCustomView:messageTextView];
    UIBarButtonItem *sendBarItemButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleBordered target:self action:@selector(sendMessage:)];
    UIBarButtonItem *fileBarItemButton = [[UIBarButtonItem alloc] initWithTitle:@"File" style:UIBarButtonItemStyleBordered target:self action:@selector(sendFile:)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:fileBarItemButton, messageBarItemTextView, sendBarItemButton, nil]];
    
    [self scrollToBottom];
    
    [self.tableView reloadData];
}

- (void)loadDatasource
{
    chatEntries = [NSMutableArray arrayWithArray:[ConversationEntry MR_findByAttribute:@"conversationId" withValue:_conversationId andOrderBy:@"lastModified" ascending:YES]];
    
    
    [self.tableView reloadData];
    [self.tableView scrollRectToVisible:self.tableView.tableFooterView.frame animated:YES];
}

- (void) keyboardWillShow: (NSNotification *)notification
{
    UIViewAnimationCurve animationCurve = [[[notification userInfo] valueForKey: UIKeyboardAnimationCurveUserInfoKey] intValue];
    NSTimeInterval animationDuration = [[[notification userInfo] valueForKey: UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardBounds = [(NSValue *)[[notification userInfo] objectForKey: UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    [UIView beginAnimations:nil context: nil];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    UIToolbar *toolbar = self.navigationController.toolbar;
    [toolbar setFrame:CGRectMake(0.0f, self.view.frame.size.height - keyboardBounds.size.height - toolbar.frame.size.height,              toolbar.frame.size.width, toolbar.frame.size.height)];
    [UIView commitAnimations];

    [self scrollToBottom];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    UIViewAnimationCurve animationCurve = [[[notification userInfo] valueForKey: UIKeyboardAnimationCurveUserInfoKey] intValue];
    NSTimeInterval animationDuration = [[[notification userInfo] valueForKey: UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    //CGRect keyboardBounds = [(NSValue *)[[notification userInfo] objectForKey: UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    [UIView beginAnimations:nil context: nil];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    UIToolbar *toolbar = self.navigationController.toolbar;
    [toolbar setFrame:CGRectMake(0.0f, self.view.frame.size.height - 46.0f, toolbar.frame.size.width, toolbar.frame.size.height)];
    [UIView commitAnimations];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (chatEntries) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingChatEntry:) name:_conversationId object:nil];
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
//    NSDictionary* entry = (NSDictionary*)notification.object;
    
//    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
//    ConversationEntry *convEntry = [ConversationEntry MR_createInContext:localContext];
//    convEntry.conversationId = entry[@"conversation"];
//    convEntry.entityId = entry[@"entity"];
//    convEntry.createdDate = entry[@"createDate"];
//    convEntry.call = entry[@"call"];
//    convEntry.file = entry[@"file"];
//    convEntry.message = entry[@"message"];
//    convEntry.mentions = entry[@"mentions"];
//    convEntry.tags = entry[@"tags"];
//    convEntry.deliveryDate = entry[@"deliveryDate"];
//    convEntry.type = entry[@"type"];
//    convEntry.urn = entry[@"urn"];
//    convEntry.entryId = entry[@"id"];
//    
//    //Save conversation entry
//    [localContext MR_saveToPersistentStoreAndWait];
//    
//    
//    [chatEntries addObject:convEntry];
    
    [self loadDatasource];
    
    //[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:chatEntries.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
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
    return chatEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    ConversationEntry *entry = chatEntries[indexPath.row];
    NSArray* result = [ClientEntities MR_findByAttribute:@"entityId" withValue:entry.entityId];
    ClientEntities* person = (ClientEntities*)result[0];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", entry.message[@"raw"]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", person.firstLastName];

    
    return cell;
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

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

- (void)sendFile:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"New Photo or Video", @"Existing Photo", @"Existing Video", @"Share Location", @"Share Contact", nil];
    
    [actionSheet showInView:messageTextView];
}

- (IBAction)sendMessage:(id)sender {
    
    //need to refactor this
    //NSDictionary* singleEntry = self.chatEntries[0];
    NSString* entity = me.urn;
    NSString* conversationUrn = _conversationId;
    NSString *message = messageTextView.text;
    
    [[JCOsgiClient sharedClient] SubmitChatMessageForConversation:conversationUrn message:message withEntity:entity success:^(id JSON) {
        // update UI
    } failure:^(NSError *err) {
        // update UI
    }];
    
    [self cleanup];
}

- (void)scrollToBottom
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(chatEntries.count -1) inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)cleanup
{
    messageTextView.text = @"";
}

@end
