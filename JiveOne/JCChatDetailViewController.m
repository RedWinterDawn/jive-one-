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

@interface JCChatDetailViewController ()

@end

@implementation JCChatDetailViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

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
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

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
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.chatEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary* singleEntry = self.chatEntries[indexPath.row];
    NSString* firstEntity = [singleEntry objectForKey:@"entity"];
    NSString* message = [[singleEntry objectForKey:@"message"] objectForKey:@"raw"];
    
    //JCEntryModel* entryModel = [[JCEntryModel alloc] initWithDictionary:singleEntry error:nil];
    NSArray* result = [ClientEntities MR_findByAttribute:@"entityId" withValue:firstEntity];
    ClientEntities* person = (ClientEntities*)result[0];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", message ];
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

- (IBAction)sendMessage:(id)sender {
    
    //need to refactor this
    NSDictionary* singleEntry = self.chatEntries[0];
    NSString* entity = [singleEntry objectForKey:@"entity"];
    NSString* conversationUrn = [singleEntry objectForKey:@"conversation"];
    NSString *message = @"this is my message";
    
    [[JCOsgiClient sharedClient] SubmitChatMessageForConversation:conversationUrn message:message withEntity:entity success:^(id JSON) {
        // update UI
    } failure:^(NSError *err) {
        // update UI
    }];
    
}
@end
