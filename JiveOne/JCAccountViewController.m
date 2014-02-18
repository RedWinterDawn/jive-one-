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
#import "MyEntity.h"


@interface JCAccountViewController ()
@property (weak, nonatomic) IBOutlet UILabel *userNameDetail;
@property (weak, nonatomic) IBOutlet UILabel *pbxDetail;
@property (weak, nonatomic) IBOutlet UILabel *companyNameDetail;

@end

@implementation JCAccountViewController

-(void)retrieveAccountDetails{
    [[JCOsgiClient sharedClient] RetrieveMyEntitity:^(id JSON) {
        
        NSDictionary *entity = (NSDictionary*)JSON;
        
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        
        [MyEntity MR_truncateAllInContext:localContext];
        [localContext MR_saveToPersistentStoreAndWait];
        
        MyEntity *m_ent = [MyEntity MR_createInContext:localContext];
        m_ent.presence = entity[@"presence"];
        m_ent.email = entity[@"email"];
        m_ent.externalId = entity[@"externalId"];
        m_ent.company = entity[@"company"];
        m_ent.location = entity[@"location"];
        m_ent.firstLastName = entity[@"name"][@"firstLast"];
        m_ent.groups = entity[@"groups"];
        m_ent.urn = entity[@"urn"];
        m_ent.id = entity[@"id"];
        m_ent.picture = entity[@"picture"];
            
        [localContext MR_saveToPersistentStoreAndWait];
        
        NSLog(@"%@", JSON);
        self.userNameDetail.text = m_ent.firstLastName;
        //TODO: using company id, query to get PBX?
        [self retrieveCompany:[JSON objectForKey:@"company"]];
        
        
    } failure:^(NSError *err) {
        NSLog(@"%@", err);
    }];
}
-(void) retrieveCompany:(NSString*)companyURL{
    [[JCOsgiClient sharedClient] RetrieveMyCompany:companyURL:^(id JSON) {
        self.companyNameDetail.text = [JSON objectForKey:@"name"];
    } failure:^(NSError *err) {
        NSLog(@"%@", err);
    }];
    
}


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
    [self retrieveAccountDetails];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
