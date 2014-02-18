//
//  JCAccountViewController.m
//  JiveOne
//
//  Created by Daniel George on 2/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAccountViewController.h"
#import "JCOsgiClient.h"
#import "JCAuthenticationManager.h"
#import "KeychainItemWrapper.h"
#import "ClientEntities.h"
#import "Company.h"


@interface JCAccountViewController ()
{
    ClientEntities *me;
}

@end

@implementation JCAccountViewController



- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    if (!me) {
        me = [[JCOmniPresence sharedInstance] me];
        
        if (!me.entityCompany) {
            [self retrieveCompany:me.company];
        }
    }
    
    [self loadViews];
}

- (void) loadViews
{
    self.userNameDetail.text = me.firstLastName;
    
    if (me.entityCompany) {
        self.pbxDetail.text = me.entityCompany.pbxId;
        self.companyNameDetail.text = me.entityCompany.name;
    }
    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!me) {
        me = [[JCOmniPresence sharedInstance] me];
    }
}

- (void)updateAccountInformation
{
    [[JCOsgiClient sharedClient] RetrieveMyEntitity:^(id JSON) {
        
        NSDictionary *entity = (NSDictionary*)JSON;
        
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        me.presence = entity[@"presence"];
        me.email = entity[@"email"];
        me.externalId = entity[@"externalId"];
        me.company = entity[@"company"];
        me.location = entity[@"location"];
        me.firstLastName = entity[@"name"][@"firstLast"];
        me.groups = entity[@"groups"];
        me.urn = entity[@"urn"];
        me.id = entity[@"id"];
        me.picture = entity[@"picture"];

        [localContext MR_saveToPersistentStoreAndWait];
        
        //TODO: using company id, query to get PBX?
        [self retrieveCompany:[JSON objectForKey:@"company"]];
        
        [self loadViews];
        
    } failure:^(NSError *err) {
        NSLog(@"%@", err);
    }];
}

-(void) retrieveCompany:(NSString*)companyURL{
    [[JCOsgiClient sharedClient] RetrieveMyCompany:companyURL:^(id JSON) {
        
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        Company *company = [Company MR_createInContext:localContext];
        company.lastModified = JSON[@"lastModified"];
        company.pbxId = JSON[@"pbxId"];
        company.timezone = JSON[@"timezone"];
        company.name = JSON[@"name"];
        company.urn = JSON[@"urn"];
        company.companyId = JSON[@"id"];
        
        me.entityCompany = company;
        
        [localContext MR_saveToPersistentStoreAndWait];
        
        [self performSelectorOnMainThread:@selector(loadViews) withObject:nil waitUntilDone:nil];
        
    } failure:^(NSError *err) {
        NSLog(@"%@", err);
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (IBAction)logoutButtonPress:(id)sender {
    
    [[JCAuthenticationManager sharedInstance] logout:self];
   
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

@end
