//
//  JCVoicemailViewController.m
//  JiveOne
//
//  Created by Doug Leonard on 2/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

/**
 Just some brainstorming notes;
 View loads
 creates query to dropbox
 gets test voicemail from this URL: https://dl.dropboxusercontent.com/u/57157576/data/54321-123.m4a
 */


#import "JCVoicemailViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "JCOsgiClient.h"
#import "Voicemail.h"


@interface JCVoicemailViewController ()
{
    ClientEntities *me;
}

@property (weak, nonatomic) JCOsgiClient *osgiClient;


@end

@implementation JCVoicemailViewController

- (NSMutableArray*)voicemails
{
    if(!_voicemails){
        _voicemails = [[NSMutableArray alloc]init];
    }
    return _voicemails;
}

- (NSMutableArray*)getVoicemails{
    return _voicemails;
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

    if (!me) {
        me = [[JCOmniPresence sharedInstance] me];
    }
    self.osgiClient = [JCOsgiClient sharedClient];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self updateVoicemailData];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]
                                        init];
    [refreshControl addTarget:self action:@selector(updateTable) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

- (void)updateVoicemailData
{
    [self.osgiClient RetrieveVoicemailForEntity:me success:^(id JSON) {
        //clear self.voicemails in case of refresh
        [self.voicemails removeAllObjects];
        
        //parse voicemail objects from server and store in self.voicemails
        NSLog(@"%@",JSON);
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        
        NSDictionary *voicemails = (NSDictionary*)JSON;
        
        for (NSDictionary* vmail in voicemails) {
            //only create/save to core data if this is a new voicemail
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"urn = %@", vmail[@"filePath"]];
            NSArray * arr = [Voicemail MR_findAllWithPredicate:pred];
            Voicemail *aVoicemail;
            if(arr.count==0){
                //create and save
                aVoicemail = [Voicemail MR_createInContext:localContext];
                aVoicemail.urn = vmail[@"filePath"];
                //non modifiable attributes go here
                aVoicemail.callerId = vmail[@"callerid"];
                aVoicemail.origdate = vmail[@"origdate"];
                aVoicemail.duration = [NSNumber numberWithInteger:[vmail[@"duration"] intValue]];
                [localContext MR_saveToPersistentStoreAndWait];
                
            }else if(arr.count==1){
                //fetch and set
                aVoicemail = arr[0];
            }
            else{
                NSLog(@"More than one copy of the same voicemail in coredata.");
            }
            
            //modifiable attributes should be changed here
//            aVoicemail.isRead = vmail[@"flag"];
            [self.voicemails addObject:aVoicemail];
            
        }
        [self.tableView reloadData];
    } failure:^(NSError *err) {
        //TODO: retry later
        NSLog(@"%@",err);
    }];
    
}

- (void)updateTable
{
    
    [self.tableView reloadData];
    
    [self.refreshControl endRefreshing];
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

    return self.voicemails.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"vCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = ((Voicemail*)self.voicemails[indexPath.row]).callerId;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", ((Voicemail*)self.voicemails[indexPath.row]).duration];

    
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

@end
