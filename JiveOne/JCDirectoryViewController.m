//
//  JCDirectoryViewController.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDirectoryViewController.h"
#import "ClientEntities.h"
#import "ClientMeta.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "JCOsgiClient.h"


@interface JCDirectoryViewController ()
{
    NSArray *clientEntities;
    NSArray *sections;
}
@end

@implementation JCDirectoryViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    sections = [NSArray arrayWithObjects:@"#", @"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j", @"k", @"l", @"m", @"n", @"o", @"p", @"q", @"r", @"s", @"t", @"u", @"v", @"w", @"x", @"y", @"z", nil];
    
    [self refreshCompanyDirectory];
}

- (void)refreshCompanyDirectory
{
    [[JCOsgiClient sharedClient] RetrieveClientEntitites:^(id JSON) {
        
        NSString *me = [JSON objectForKey:@"me"];
        NSArray* entityArray = [JSON objectForKey:@"entries"];
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        
        [ClientEntities MR_truncateAllInContext:localContext];
        [ClientMeta MR_truncateAllInContext:localContext];
        [localContext MR_saveToPersistentStoreAndWait];
        
        for (NSDictionary* entity in entityArray) {
            ClientEntities *c_ent = [ClientEntities MR_createInContext:localContext];
            c_ent.lastModified = [entity objectForKey:@"lastModified"];
            c_ent.presence = [entity objectForKey:@"presence"];
            c_ent.company = [entity objectForKey:@"company"];
            c_ent.tags = [entity objectForKey:@"tags"];
            c_ent.location = [entity objectForKey:@"location"];
            c_ent.firstName = [[entity objectForKey:@"name"] objectForKey:@"first"];
            c_ent.lastName = [[entity objectForKey:@"name"] objectForKey:@"last"];
            c_ent.lastFirstName = [[entity objectForKey:@"name"] objectForKey:@"lastFirst"];
            c_ent.firstLastName = [[entity objectForKey:@"name"] objectForKey:@"firstLast"];
            c_ent.groups = [entity objectForKey:@"groups"];
            c_ent.urn = [entity objectForKey:@"urn"];
            c_ent.id = [entity objectForKey:@"id"];
            c_ent.entityId = [entity objectForKey:@"_id"];
            c_ent.me = [NSNumber numberWithBool:[c_ent.entityId isEqualToString:me]];
            c_ent.picture = [entity objectForKey:@"picture"];
            c_ent.email = [entity objectForKey:@"email"];
            
            ClientMeta *c_meta = [ClientMeta MR_createInContext:localContext];
            c_meta.entityId = entity[@"meta"][@"entity"];
            c_meta.lastModified = entity[@"meta"][@"lastModified"];
            c_meta.createDate = entity[@"meta"][@"createDate"];
            c_meta.pinnedActivityOrder = entity[@"meta"][@"pinnedActivityOrder"];
            c_meta.activityOrder = entity[@"meta"][@"activityOrder"];
            c_meta.urn = entity[@"meta"][@"urn"];
            c_meta.metaId = entity[@"meta"][@"id"];
            
            c_ent.entityMeta = c_meta;
            
            NSLog(@"id:%@ - _id:%@", [entity objectForKey:@"id"], [entity objectForKey:@"_id"]);
            
            [localContext MR_saveToPersistentStoreAndWait];
        }
        
        clientEntities = [ClientEntities MR_findAllSortedBy:@"firstLastName" ascending:YES];
        [self.tableView reloadData];
        
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
    return sections.count;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)index
{
    return index;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [sections objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return clientEntities.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    ClientEntities* person = clientEntities[indexPath.row];
    
    cell.textLabel.text = person.firstLastName;
    cell.detailTextLabel.text = person.email;
    [cell.imageView setImageWithURL:[NSURL URLWithString:person.picture]
                   placeholderImage:[UIImage imageNamed:@"avatar.png"]];
    
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


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UITableViewCell *)sender
//{
//    // Get the new view controller using [segue destinationViewController].
//    // Pass the selected object to the new view controller.
//    UIViewController *DirectoryDetail = [segue destinationViewController];
//    UITableViewCell *cell2 = [self tableView:self.tableView cellForRowAtIndexPath:sender.];
//}



- (IBAction)refreshDirectory:(id)sender {
    [self refreshCompanyDirectory];
}
@end
