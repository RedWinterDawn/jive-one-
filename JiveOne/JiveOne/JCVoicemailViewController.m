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
#import "JCVoicemailCell.h"
#import "MBProgressHUD.h"

@interface JCVoicemailViewController ()
{
    ClientEntities *me;
}

@property (nonatomic,strong) JCVoicemailCell *currentVoicemailCell;
@property (weak, nonatomic) JCOsgiClient *osgiClient;


@end

@implementation JCVoicemailViewController
integer_t const newVoicemails = 0;
integer_t const oldVoicemails = 1;

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


- (JCOsgiClient*)osgiClient
{
    if(!_osgiClient){
        _osgiClient = [JCOsgiClient sharedClient];
    }
    return _osgiClient;
}

-(JCOsgiClient*)getOsgiClient
{
    return _osgiClient;
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
    
    self.voicemails = [NSMutableArray arrayWithArray:[Voicemail MR_findAll]];
    
    [self setupTable];
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

- (void)setupTable
{
    UINib *voicemailNib = [UINib nibWithNibName:@"JCVoicemailCell" bundle:nil];
    //Registers a nib object containing a cell with the table view under a specified identifier. (the line below)
    [self.tableView registerNib:voicemailNib forCellReuseIdentifier:[JCVoicemailCell reuseIdentifier]];

    self.clearsSelectionOnViewWillAppear = NO;
}

- (void)updateVoicemailData
{
    [self.osgiClient RetrieveVoicemailForEntity:me success:^(id JSON) {
        //clear self.voicemails in case of refresh
        [self.voicemails removeAllObjects];
        
        //parse voicemail objects from server and store in self.voicemails
        NSLog(@"%@",JSON);
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        
        NSDictionary *voicemails = [(NSDictionary*)JSON objectForKey:@"entries"];
        
        for (NSDictionary* vmail in voicemails) {
            //only create/save to core data if this is a new voicemail
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"urn == %@", vmail[@"urn"]];
            NSArray * arr = [Voicemail MR_findAllWithPredicate:pred];
            Voicemail *aVoicemail;
            if(arr.count==0){
                //create and save
                aVoicemail = [Voicemail MR_createInContext:localContext];
                aVoicemail.urn = vmail[@"urn"];
                
                //non modifiable attributes go here
                aVoicemail.callerId = vmail[@"callerId"];
                aVoicemail.createdDate = [vmail[@"createdDate"] stringValue];
                aVoicemail.duration = [NSNumber numberWithInteger:[vmail[@"length"] intValue]];
                aVoicemail.voicemail = [NSData dataWithContentsOfURL:[NSURL URLWithString:vmail[@"file"]]];
                
            }else if(arr.count==1){
                //fetch and set
                aVoicemail = arr[0];
            }
            else{
                NSLog(@"More than one copy of the same voicemail in coredata.");
            }
            
            //modifiable attributes should be changed here
            aVoicemail.read = [NSNumber numberWithBool:[vmail[@"read"] boolValue]];//TODO make sure this works
            [localContext MR_saveToPersistentStoreAndWait];
            [self.voicemails addObject:aVoicemail];
            
        }
        NSLog(@"Currently %lu voicemail(s) in core data", [Voicemail MR_findAll].count);
        
        [self.tableView reloadData];
    } failure:^(NSError *err) {
        //TODO: retry later
        MBProgressHUD *toast = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] windows] lastObject] animated:YES];
        toast.mode = MBProgressHUDModeText;
        toast.labelText = @"Unable to fetch voicemail from server";
        toast.userInteractionEnabled = YES;
        toast.margin = 10.f;
        toast.yOffset = 150.f;
        [toast hide:YES afterDelay:2];
        [toast show:YES];

        NSLog(@"%@",err);
    }];
}

- (NSString*)getLocalVoicemailFilePathUsingURN:(NSString*) URN
{
    NSRange startRange = [URN rangeOfString:@"/voicemail"];
    NSRange endRange = [URN rangeOfString:@".wav"];
    NSString *filePath = @"";
    if (startRange.location >= 0 && endRange.location >= 0) {
        NSString *docsDir;
        NSArray *dirPaths;
        NSRange searchRange = NSMakeRange(startRange.location , ((endRange.length + endRange.location) - startRange.location));
        dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        docsDir = [dirPaths objectAtIndex:0];
        filePath = [URN substringWithRange:searchRange];
        NSString *databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:filePath]];
        
        return databasePath;
    }
    return @"";
}

- (NSData*)getVoiceMailDataUsingString: (NSString*)URLString
{
    NSData *audioData = [[NSData alloc]init];
    //TODO: Add Progress wheel of happiness
    NSData* (^getVoicemailData)(NSString*) = ^(NSString* path){
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:path]];
        NSString *docsDir;
        NSArray *dirPaths;
        dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        docsDir = [dirPaths objectAtIndex:0];
        
        NSString *filePath = [self getLocalVoicemailFilePathUsingURN:path];
        NSString *databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:filePath]];
//        [data writeToFile:databasePath atomically:YES];
        
        return data;
    };
    
    
    return audioData = getVoicemailData(URLString);
}

//when the voicemail has been played, this is the callback
-(void) voicemailShouldBeMarkedRead:(JCVoicemailCell*)cell{
    //udpate this action in core data first
    cell.voicemailObject.read=[NSNumber numberWithInt:1];
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if(success){
            //attempt to save change to server
//            TODO: uncomment
            [self.osgiClient UpdateVoicemailToRead:cell.voicemailObject success:^(id JSON) {
                //if successful, do nothing
            } failure:^(NSError *err) {
                //TODO: if failure, resend update at when connection restored
                NSLog(@"%@", err);
            }];
        }else
            NSLog(@"%@", error);
    }];
}


/** Changes the currently selected voicemail cell - performing animations as appropriate */
-(void)changeSelectedVoicemailCell:(JCVoicemailCell *)cell {
    if (self.currentVoicemailCell.voicemailObject != cell.voicemailObject) {
        NSMutableArray *reloadCells = [NSMutableArray arrayWithCapacity:2];
        
        // if there's a previous cell
        if (self.currentVoicemailCell) {
            JCVoicemailCell *cell2 = (JCVoicemailCell *)[self visibleCellForItem:self.currentVoicemailCell.voicemailObject];
            // stop playing
            [cell2 stop];
            // and add it to the reload list
            [reloadCells addObject:[self.tableView indexPathForCell:cell2]];
        }
        
        // add new cell to the reload list
        if (cell) {
            [reloadCells addObject:[self.tableView indexPathForCell:cell]];
        }
        self.currentVoicemailCell = cell;
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:reloadCells withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}


/** Returns the cell associated with the item, or nil if it is not visible */
-(UITableViewCell *)visibleCellForItem:(Voicemail *)item {
    for (JCVoicemailCell *cell in self.tableView.visibleCells) {
        if (cell.voicemailObject==item) {
            return cell;
        }
    }
    return nil;
}

- (void)updateTable
{
    
    [self updateVoicemailData];
    
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
    static NSString *CellIdentifier = @"VoicemailCell";
    JCVoicemailCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
   [cell configureWithItem:(Voicemail*)self.voicemails[indexPath.row] andDelegate:self];
   
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Voicemail *item = [self itemAtIndexPath:indexPath];
    BOOL selected = [self.currentVoicemailCell.voicemailObject isEqual:item];
    CGFloat height = [JCVoicemailCell cellHeightForData:item selected:selected];
    return height;
}

-(Voicemail *)itemAtIndexPath:(NSIndexPath *)indexPath {
    
    return (Voicemail*)self.voicemails[indexPath.row];
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    Voicemail *vmail = [self itemAtIndexPath:indexPath];
    if([self.currentVoicemailCell.voicemailObject isEqual:vmail]){//TODO:switch to asking cell if it is expanded
        return NO;
    }
    else
        return YES;
    
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //attempt to delete from server first
        [self voiceCellDeleteTapped:(JCVoicemailCell*)[self.tableView cellForRowAtIndexPath:indexPath]];
    }
}

#pragma mark - JCVoicemailCellDelegate
-(void)voiceCellDeleteTapped:(JCVoicemailCell *)cell {
    
    [self.osgiClient DeleteVoicemail:cell.voicemailObject sucess:^(id JSON) {
        
        //delete from Core data
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"urn == %@", cell.voicemailObject.urn];
        if(![Voicemail MR_deleteAllMatchingPredicate:pred]){
            //TODO: alert user that deletion from core data was unsucessful
            NSLog(@"Deletion from core data unsuccessful");
        }else{
            NSLog(@"%lu voicemails remaining in Core data", (unsigned long)[Voicemail MR_findAll].count);
        }
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        //delete from self.voicemails
        [self.voicemails removeObjectAtIndex:indexPath.row];
        
        //update view
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        //toast user
        MBProgressHUD *toast = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] windows] lastObject] animated:YES];
        toast.mode = MBProgressHUDModeText;
        toast.labelText = @"Successfully Deleted";
        toast.userInteractionEnabled = YES;
        toast.margin = 10.f;
        toast.yOffset = 150.f;
        [toast hide:YES afterDelay:2];
        [toast show:YES];
    } failure:^(NSError *err) {
        //alert user that deleting from server failed
        NSLog(@"%@",err);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Deletion unsuccessful" message:@"Please try again when you have data connectivity" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }];

}

-(void)voiceCellInfoTapped:(JCVoicemailCell *)cell {
}

-(void)voiceCellPlayTapped:(JCVoicemailCell *)cell {
    if (cell.isPlaying) {
        [cell pause];
    }
    else {
        [cell play];
    }
    if(![cell.voicemailObject.read boolValue])
    {[self voicemailShouldBeMarkedRead:(JCVoicemailCell*)cell];}
}

-(void)voiceCellReplyTapped:(JCVoicemailCell *)cell {
}

-(void)voiceCellSpeakerTapped:(JCVoicemailCell *)cell {
    cell.useSpeaker = !cell.useSpeaker;
}

-(void)voiceCellToggleTapped:(JCVoicemailCell *)cell {

    // if a selected cell is not the actively selected cell
    if (![cell.voicemailObject isEqual:self.currentVoicemailCell.voicemailObject]) {
        [self changeSelectedVoicemailCell:cell];
    }// if the selected cell is the actively selected cell
    else {
        [self changeSelectedVoicemailCell:nil];
    }
}



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
