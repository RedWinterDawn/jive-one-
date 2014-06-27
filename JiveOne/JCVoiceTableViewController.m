//
//  JCVoiceTableViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoiceTableViewController.h"
#import "JCVoiceCell.h"
#import "JCVoicemailClient.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "JCMessagesViewController.h"
#import "JCAppDelegate.h"
#import "Voicemail+Custom.h"

@interface JCVoiceTableViewController ()
{
    NSData *soundData;
    AVAudioPlayer *player;
    JCVoiceCell *selectedCell;
    NSManagedObjectContext *context;
    BOOL useSpeaker;
    MBProgressHUD *hud;
    NSTimer *requestTimeout;
    
}
@property (weak, nonatomic) JCRESTClient *osgiClient;
@property (nonatomic) NSMutableArray *selectedIndexPaths;
@property (nonatomic, retain) NSTimer *progressTimer;

@end

@implementation JCVoiceTableViewController

static NSString *CellIdentifier = @"VoicemailCell";

- (void)osgiClient:(JCRESTClient*)client
{
    _osgiClient = client;
}

-(JCRESTClient*)getOsgiClient
{
    if(!_osgiClient){
        _osgiClient = [JCRESTClient sharedClient];
        
    }
    return _osgiClient;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    [self.tableView registerClass:[JCVoiceCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"JCVoicemailCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
    self.progressTimer = nil;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]
                                        init];
    [refreshControl addTarget:self action:@selector(updateVoiceTable) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"main-logo.png"]];
    
    self.tableView.backgroundView = imageView;
    [Voicemail fetchVoicemailInBackground];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [(JCAppDelegate *)[UIApplication sharedApplication].delegate refreshTabBadges:NO];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    [Flurry logEvent:@"Voicemail View"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNewVoicemail:) name:kNewVoicemail object:nil];
//    [(JCAppDelegate *)[UIApplication sharedApplication].delegate clearBadgeCountForVoicemail];
        [self loadVoicemails];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNewVoicemail object:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadVoicemails
{
    if (self.voicemails) {
        [self.voicemails removeAllObjects];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deleted ==[c] %@", [NSNumber numberWithBool:NO]];
    self.voicemails = [NSMutableArray arrayWithArray:[Voicemail MR_findAllSortedBy:@"timeStamp" ascending:NO withPredicate:predicate]];
    
    
    [self.tableView reloadData];
}

- (void)updateVoiceTable
{
    if (requestTimeout && [requestTimeout isValid]) {
        [requestTimeout invalidate];
    }
    
    requestTimeout = [NSTimer timerWithTimeInterval:20 target:self selector:@selector(requestDidTimedOut) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:requestTimeout forMode:NSRunLoopCommonModes];
 
    [[JCVoicemailClient sharedClient] getVoicemails:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
        if(suceeded){
            if ([requestTimeout isValid]) {
                [requestTimeout invalidate];
            }
            [self.refreshControl endRefreshing];
            [self loadVoicemails];
        }
    }];
}

- (void)requestDidTimedOut
{
    if ([requestTimeout isValid]) {
        [requestTimeout invalidate];
    }

    
    [self showHudWithTitle:NSLocalizedString(@"Server Not Reachable", nil) detail:NSLocalizedString(@"Could not check for voicemails at this moment. Please try again.", nil) mode:MBProgressHUDModeText];
    [self.refreshControl endRefreshing];
}

#pragma mark - HUD Operations
- (void)showHudWithTitle:(NSString*)title detail:(NSString*)detail mode:(MBProgressHUDMode)mode
{
    if (!hud) {
        hud = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] windows] lastObject] animated:YES];
        if (!mode) {
            mode = MBProgressHUDModeIndeterminate;
        }
        hud.mode = mode;
    }
    
    if (hud.mode != mode) {
        hud.mode = mode;
    }
    
    hud.labelText = title;
    hud.detailsLabelText = detail;
    
    if (hud.mode == MBProgressHUDModeText) {
        [hud hide:YES afterDelay:2];
    }
    
    [hud show:YES];
}

- (void)hideHud
{
    if (hud) {
        [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] windows] lastObject] animated:YES];
        [hud removeFromSuperview];
        hud = nil;
    }
}

#pragma mark - New Voicemail
- (void)didReceiveNewVoicemail:(NSNotification *)notification
{
//    if (self.view.window) {
//        [(JCAppDelegate *)[UIApplication sharedApplication].delegate clearBadgeCountForVoicemail];
//    }
    [self loadVoicemails];
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
    JCVoiceCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[JCVoiceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Voicemail *voicemail = self.voicemails[indexPath.row];
    
    cell.voicemail = voicemail;
    cell.indexPath = indexPath;
    cell.delegate = self;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isSelected = [self.selectedIndexPaths containsObject:indexPath];
    return isSelected ? 180.0f : 60.0f;
}

-(void)resetSlider
{
        [selectedCell setSliderValue:0];
        [selectedCell.slider updateThumbWithCurrentProgress];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((player.currentTime > 0) && (selectedCell.indexPath == indexPath)) {
        //pause
        [player pause];
        
        [self stopProgressTimerForVoicemail];
        [selectedCell.playPauseButton setPlayPauseDisplaysPlay:YES];
//        [selectedCell setSliderValue:0];
//        [selectedCell.slider updateThumbWithCurrentProgress];
        [self performSelector:@selector(resetSlider) withObject:nil afterDelay:.5];
    }
    
    [self addOrRemoveSelectedIndexPath:indexPath];
    
    BOOL isSelected = [self.selectedIndexPaths containsObject:indexPath];
    
    if (isSelected) {
        [self prepareAudioForIndexPath:indexPath];
        selectedCell = (JCVoiceCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        if (selectedCell.frame.origin.y >= 300) {
            [tableView setContentOffset:CGPointMake(0, 80)animated:YES];
        }
    }
    
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //attempt to delete from server first
        [self voiceCellDeleteTapped:indexPath];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    BOOL isSelected = [self.selectedIndexPaths containsObject:indexPath];
    
    return !isSelected;
}

#pragma mark - JCVoicemailCellDelegate
-(void)voiceCellDeleteTapped:(NSIndexPath *)indexPath {
    
    // if we are playing a voicemail and we delete the voicemail cell that is being played -> stop playing then delete.
    if (player.isPlaying && (selectedCell.indexPath == indexPath)) {
        //pause
        [player pause];
        
        [self stopProgressTimerForVoicemail];
    }
    Voicemail *voicemail = self.voicemails[indexPath.row];
    [Voicemail markVoicemailForDeletion:voicemail.jrn managedContext:nil];
    [(JCAppDelegate *)[UIApplication sharedApplication].delegate decrementBadgeCountForVoicemail:voicemail.jrn];
    [self.voicemails removeObjectAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    [self deleteVoicemailsInBackground];
}

- (void)deleteVoicemailsInBackground
{
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deleted ==[c] %@", [NSNumber numberWithBool:YES]];
//    NSArray *deletedVoicemails = [NSMutableArray arrayWithArray:[Voicemail MR_findAllWithPredicate:predicate]];
//    
//    if (deletedVoicemails.count > 0) {
//        for (Voicemail *voice in deletedVoicemails) {
//            [[JCRESTClient sharedClient] DeleteVoicemail:voice success:^(id JSON) {
//                [Voicemail deleteVoicemail:voice.jrn managedContext:nil];
//            } failure:^(NSError *err) {
//                NSLog(@"%@", err);
//            }];
//        }
//    }
}

- (void)addOrRemoveSelectedIndexPath:(NSIndexPath *)indexPath
{
    if (!self.selectedIndexPaths) {
        self.selectedIndexPaths = [NSMutableArray new];
    }
    
    BOOL containsIndexPath = [self.selectedIndexPaths containsObject:indexPath];
    
    if (containsIndexPath) {
        [self.selectedIndexPaths removeObject:indexPath];
    }else{
        [self.selectedIndexPaths addObject:indexPath];
    }
    
    
    NSIndexPath *removed = nil;
    
    if (self.selectedIndexPaths.count == 2) {
        removed = [self.selectedIndexPaths objectAtIndex:0];
        [self.selectedIndexPaths removeObjectAtIndex:0];
    }
    
    
    NSArray *indexPaths;
    
    if (removed) {
        indexPaths = @[removed, indexPath];
    }
    else {
        indexPaths = @[indexPath];
    }
    
    
    [self.tableView reloadRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationFade];
    
}

- (void)markVoicemailAsRead
{
    selectedCell.voicemail.read = [NSNumber numberWithBool:YES];
    
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    // save to local storage
    [context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            [selectedCell  performSelectorOnMainThread:@selector(styleCellForRead) withObject:nil waitUntilDone:NO];
            // now send update to server
            [[JCVoicemailClient sharedClient] updateVoicemailToRead:selectedCell.voicemail :^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
                if(suceeded){
                      NSLog(@"Success Updating Read On Server");
                }else{
                    NSString*errorMessage = @"Failed Updating Read On Server";
                    NSLog(@"%@", errorMessage);
                    [Flurry logError:@"Voicmail-11" message:errorMessage error:error];
                }
            }];
        }
    }];
}


#pragma mark - JCVoiceCell Delegate
- (void)voiceCellPlayTapped:(JCVoiceCell *)cell
{
    [self playPauseAudio:cell];
}

- (void)voiceCellSliderMoved:(float)value
{
    player.currentTime = value;
    [self updateProgress:nil];
    [self startProgressTimerForVoicemail];
}

- (void)voiceCellSliderTouched:(BOOL)touched
{
    [self stopProgressTimerForVoicemail];
}

- (void)voicecellSpeakerTouched:(BOOL)touched
{
    useSpeaker = !useSpeaker;
    [selectedCell.speakerButton setSelected:useSpeaker];
    [self setupSpeaker];
}

- (void)voiceCellAudioAvailable:(NSIndexPath *)indexPath
{
    if (!player.isPlaying) {
        [self prepareAudioForIndexPath:indexPath];
    }
}

#pragma mark - Audio Operations

- (void)prepareAudioForIndexPath:(NSIndexPath*)indexPath
{
    if (player && player.isPlaying) {
        [player stop];
    }
    selectedCell = (JCVoiceCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    NSError *error;
    player = [[AVAudioPlayer alloc] initWithData:selectedCell.voicemail.voicemail fileTypeHint:AVFileTypeWAVE error:&error];
    if (player) {
        [self setupSpeaker];
        player.delegate = self;
        [player prepareToPlay];
        [self updateViewForPlayerInfo];
    }
}

- (void)playPauseAudio:(JCVoiceCell *)cell
{
    BOOL playing = player.isPlaying;
    
    if (playing) {
        //pause
        [player pause];
        
        [self stopProgressTimerForVoicemail];
        [selectedCell.playPauseButton setPlayPauseDisplaysPlay:YES];
    }
    else {
        //play
        [player play];
        
        [self startProgressTimerForVoicemail];
        [selectedCell.playPauseButton setPlayPauseDisplaysPlay:NO];
        [(JCAppDelegate *)[UIApplication sharedApplication].delegate decrementBadgeCountForVoicemail:selectedCell.voicemail.jrn];
        if (![selectedCell.voicemail.read boolValue]) {
            [self markVoicemailAsRead];
        }
    }
}

- (void)updateViewForPlayerInfo
{
	selectedCell.duration.text = [NSString stringWithFormat:@"%d:%02d", (int)player.duration / 60, (int)player.duration % 60, nil];
	selectedCell.slider.maximumValue = player.duration;
}

- (void)startProgressTimerForVoicemail {
    if (player.isPlaying) {
        if (self.progressTimer) {
            [self stopProgressTimerForVoicemail];
        }
        
        self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
    }    
}

- (void)stopProgressTimerForVoicemail {
    [self.progressTimer invalidate];
    self.progressTimer = nil;
    
}

- (void)updateProgress:(NSNotification*)notification {
    if (selectedCell.playPauseButton.playPauseDisplaysPlay == YES) {
        [selectedCell.playPauseButton setPlayPauseDisplaysPlay:NO];
    }
    selectedCell.duration.text = [self formatSeconds:player.duration];
    selectedCell.elapsed.text = [self formatSeconds:player.currentTime];
    [selectedCell setSliderValue:player.currentTime];
    [selectedCell.slider updateThumbWithCurrentProgress];
}

/** Time formatting helper fn: N seconds => M:SS */
-(NSString *)formatSeconds:(NSTimeInterval)seconds {
    NSInteger minutes = (NSInteger)(seconds/60.);
    NSInteger remainingSeconds = (NSInteger)seconds % 60;
    return [NSString stringWithFormat:@"%.1ld:%.2ld",(long)minutes,(long)remainingSeconds];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self stopProgressTimerForVoicemail];
    [selectedCell.playPauseButton setPlayPauseDisplaysPlay:YES];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self stopProgressTimerForVoicemail];
    [selectedCell.playPauseButton setPlayPauseDisplaysPlay:YES];
}

- (void)setupSpeaker
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    
    // set category PlanAndRecord in order to be able to use AudioRoueOverride
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
                             error:&error];
    
    AVAudioSessionPortOverride portOverride = useSpeaker ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone;
    [session overrideOutputAudioPort:portOverride error:&error];
    
    if (!error) {
        [session setActive:YES error:&error];
        
        if (!error) {
            if (useSpeaker) {
                [selectedCell.speakerView setIsSelected:YES];
            }
            else {
                [selectedCell.speakerView setIsSelected:NO];

            }
        }
    }
}


@end
