//
//  JCRecentViewController.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentViewController.h"
#import "JCOsgiClient.h"
#import "JCEntryModel.h"
#import "ClientEntities.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "JCChatDetailViewController.h"

@interface JCRecentViewController ()
{
    NSMutableArray *entries;
}

@end

@implementation JCRecentViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    entries = [[NSMutableArray alloc] init];
    [self fetchLastConverstions];
    
}

- (void)fetchLastConverstions
{
    [[JCOsgiClient sharedClient] RetrieveConversations:^(id JSON) {
       
        
        NSArray* entriesResultArray = [(NSDictionary*)JSON objectForKey:@"entries"];
        //NSArray* entriesArray =  [((NSDictionary*)entriesResultArray[0]) objectForKey:@"entries"];
        entries = [[NSMutableArray alloc] initWithArray:entriesResultArray];
        [self.tableView reloadData];
        
        //NSLog(@"%@", [entriesArray description]);
        
        
        
    } failure:^(NSError *err) {
        NSLog([err description]);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    return entries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSArray* entryArray = [(NSDictionary*)entries[indexPath.row] objectForKey:@"entries"];
    NSArray* entitiesArray = [(NSDictionary*)entries[indexPath.row] objectForKey:@"entities"];
    NSString* firstEntity = [NSString stringWithFormat:@"%@", entitiesArray[0]] ;
    //NSDictionary* singleEntry = entryArray[0];
    //JCEntryModel* entryModel = [[JCEntryModel alloc] initWithDictionary:singleEntry error:nil];
    //ClientEntities* person = [ClientEntities MR_findByAttribute:@"id" withValue:firstEntity];
    //NSArray* result = [ClientEntities MR_findByAttribute:@"entityId" withValue:firstEntity];
    //ClientEntities* person = (ClientEntities*)result[0];
    
    //cell.textLabel.text = [NSString stringWithFormat:@"%@", person.firstLastName];
    //cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", entryModel.deliveryDate];
    //NSLog(person.picture);
    //[cell.imageView setImageWithURL:[NSURL URLWithString:person.picture] placeholderImage:[UIImage imageNamed:@"avatar.png"]];
    
    cell.textLabel.text = @"testing";
    cell.detailTextLabel.text = @"testing";
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray* entryArray = [(NSDictionary*)entries[indexPath.row] objectForKey:@"entries"];
    [self performSegueWithIdentifier:@"ChatDetailSegue" sender:entryArray];
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
    [segue.destinationViewController setChatEntries:sender];
}



- (IBAction)refreshConversations:(id)sender {
    [self fetchLastConverstions];
}
@end
