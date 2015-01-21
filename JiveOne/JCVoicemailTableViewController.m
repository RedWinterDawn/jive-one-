//
//  JCVoiceTableViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import AVFoundation;
@import UIKit;

#import <MBProgressHUD/MBProgressHUD.h>

#import "JCVoicemailTableViewController.h"
#import "JCVoicemailPlaybackCell.h"
#import "JCV5ApiClient.h"

#import "JCAppDelegate.h"
#import "Voicemail+V5Client.h"

@interface JCVoicemailTableViewController () <AVAudioPlayerDelegate, JCVoiceCellDelegate>
{
    NSData *soundData;
    AVAudioPlayer *player;
    NSManagedObjectContext *context;
    BOOL _playThroughSpeaker;
    MBProgressHUD *hud;
    NSTimer *requestTimeout;
}

@property (nonatomic) NSMutableArray *selectedIndexPaths;
@property (nonatomic, retain) NSTimer *progressTimer;

@end

@implementation JCVoicemailTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(updateVoiceTable:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

#pragma mark - Getters -

-(NSFetchedResultsController *)fetchedResultsController
{
	if (!_fetchedResultsController) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"markForDeletion ==[c] %@", @NO];
		NSFetchRequest *fetchRequest = [Voicemail MR_requestAllSortedBy:@"date" ascending:NO withPredicate:predicate];
		fetchRequest.fetchBatchSize = 10;
		
		super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                             managedObjectContext:self.managedObjectContext
                                                                               sectionNameKeyPath:nil
                                                                                        cacheName:nil];
	}
	return _fetchedResultsController;
}

- (void)updateVoiceTable:(id)sender
{
    if (requestTimeout && [requestTimeout isValid]) {
        [requestTimeout invalidate];
    }
    
    requestTimeout = [NSTimer timerWithTimeInterval:20 target:self selector:@selector(requestDidTimedOut) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:requestTimeout forMode:NSRunLoopCommonModes];
 
    Line *line = [JCAuthenticationManager sharedInstance].line;
    [Voicemail downloadVoicemailsForLine:line complete:^(BOOL success, NSError *error) {
        if ([requestTimeout isValid]) {
            [requestTimeout invalidate];
        }
        [self.refreshControl endRefreshing];
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

#pragma mark - Table view data source

-(void)configureCell:(UITableViewCell *)cell withObject:(id<NSObject>)object
{
	[super configureCell:cell withObject:object];
	((JCVoicemailPlaybackCell *)cell).delegate = self;
}

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [super configureCell:cell atIndexPath:indexPath];
    
    JCVoicemailPlaybackCell *voiceCell = (JCVoicemailPlaybackCell *)cell;
	voiceCell.indexPath = indexPath;
	BOOL isSelected = [self.selectedIndexPaths containsObject:indexPath];
	if (isSelected)
	{
		self.selectedCell = voiceCell;
		voiceCell.playPauseButton.selected = [player isPlaying];
		voiceCell.speakerButton.selected = _playThroughSpeaker;
		[self updateViewForPlayerInfo];
		[self updateProgress:nil];
	}
	
}

-(void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath
{
	[self addOrRemoveSelectedIndexPath:indexPath];
	
	// if we are playing a voicemail and we delete the voicemail cell that is being played -> stop playing then delete.
	if (player.isPlaying && (self.selectedCell.indexPath == indexPath)) {
		//pause
		[player pause];
		
		[self stopProgressTimerForVoicemail];
	}
	
	Voicemail *voicemail = [self objectAtIndexPath:indexPath];
	[Voicemail markVoicemailForDeletion:voicemail.jrn managedContext:nil];
	[Voicemail deleteVoicemailsInBackground];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isSelected = [self.selectedIndexPaths containsObject:indexPath];
    return isSelected ? 180.0f : 60.0f;
}

-(void)resetSlider
{
        [self.selectedCell setSliderValue:0];
        [self.selectedCell.slider updateThumbWithCurrentProgress];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((player.currentTime > 0) && (self.selectedCell.indexPath == indexPath)) {
        //pause
        [player pause];
        
        [self stopProgressTimerForVoicemail];
        [self performSelector:@selector(resetSlider) withObject:nil afterDelay:.5];
    }
    [self addOrRemoveSelectedIndexPath:indexPath];
    
    BOOL isSelected = [self.selectedIndexPaths containsObject:indexPath];
    
    if (isSelected) {
        [self prepareAudioForIndexPath:indexPath];
        self.selectedCell = (JCVoicemailPlaybackCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        self.selectedCell.speakerButton.selected = _playThroughSpeaker;
        
        CGPoint positionRelativeToWindow = [self.selectedCell.contentView convertPoint:self.selectedCell.contentView.frame.origin toView:[UIApplication sharedApplication].keyWindow];
        NSLog(@"PositionRelativeToWindow%@", NSStringFromCGPoint(positionRelativeToWindow));
        if (positionRelativeToWindow.y > 338) {
            NSLog(@"SelectedCellFrame:%@", NSStringFromCGRect(self.selectedCell.frame));
            CGPoint currentContentOffset = self.tableView.contentOffset;
            int amountToOffsetWithExpandedCell = currentContentOffset.y + (positionRelativeToWindow.y - 338);
            NSLog(@"amountToOffsetWithExpandedCell:%d",amountToOffsetWithExpandedCell);
            [tableView setContentOffset:CGPointMake(0, amountToOffsetWithExpandedCell)animated:YES];
        }
    }
    
}

#pragma mark - JCVoicemailCellDelegate

-(void)voiceCellDeleteTapped:(JCVoicemailPlaybackCell *)cell {
    
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	[self deleteObjectAtIndexPath:indexPath];
}

- (void)addOrRemoveSelectedIndexPath:(NSIndexPath *)indexPath
{
    if (!self.selectedIndexPaths) {
        self.selectedIndexPaths = [NSMutableArray new];
    }
    
    BOOL containsIndexPath = [self.selectedIndexPaths containsObject:indexPath];
    
    if (containsIndexPath) {
        [self.selectedIndexPaths removeObject:indexPath];
    }
    else {
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
    
    [self.tableView reloadData];
}

#pragma mark - JCVoiceCell Delegate
- (void)voiceCellPlayTapped:(JCVoicemailPlaybackCell *)cell
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

- (void)voicecellSpeakerTouched
{
    _playThroughSpeaker = !_playThroughSpeaker;
    self.selectedCell.speakerButton.selected = _playThroughSpeaker;
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
    self.selectedCell = (JCVoicemailPlaybackCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    NSError *error;
    player = [[AVAudioPlayer alloc] initWithData:self.selectedCell.voicemail.data fileTypeHint:AVFileTypeWAVE error:&error];
    if (player) {
        [self setupSpeaker];
        player.delegate = self;
        [player prepareToPlay];
        [self updateViewForPlayerInfo];
    }
}

- (void)playPauseAudio:(JCVoicemailPlaybackCell *)cell
{
    BOOL playing = player.isPlaying;
    
    if (playing) {
        //pause
        [player pause];
        
        [self stopProgressTimerForVoicemail];
        self.selectedCell.playPauseButton.selected = false;
        [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    }
    else {
        //play
        [player play];
        
        [self startProgressTimerForVoicemail];
        self.selectedCell.playPauseButton.selected = TRUE;
        [self.selectedCell.voicemail markAsRead];
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    }
}

- (void)updateViewForPlayerInfo
{
	self.selectedCell.duration.text = [NSString stringWithFormat:@"%d:%02d", (int)player.duration / 60, (int)player.duration % 60, nil];
	self.selectedCell.slider.maximumValue = player.duration;
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
    if (self.selectedCell.playPauseButton.selected == FALSE && player.isPlaying) {
        self.selectedCell.playPauseButton.selected = TRUE;
    }
    self.selectedCell.duration.text = [self formatSeconds:player.duration];
    [self.selectedCell setSliderValue:player.currentTime];
    [self.selectedCell.slider updateThumbWithCurrentProgress];
}

/** Time formatting helper fn: N seconds => M:SS */
-(NSString *)formatSeconds:(NSTimeInterval)seconds {
    NSInteger minutes = (NSInteger)(seconds/60.);
    NSInteger remainingSeconds = (NSInteger)seconds % 60;
    return [NSString stringWithFormat:@"%.1ld:%.2ld",(long)minutes,(long)remainingSeconds];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self stopProgressTimerForVoicemail];
    self.selectedCell.playPauseButton.selected = FALSE;
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self stopProgressTimerForVoicemail];
    self.selectedCell.playPauseButton.selected = TRUE;
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
}

- (void)setupSpeaker
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    
    // set category PlanAndRecord in order to be able to use AudioRoueOverride
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
                             error:&error];
    
    AVAudioSessionPortOverride portOverride = _playThroughSpeaker ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone;
    [session overrideOutputAudioPort:portOverride error:&error];
    
    if (!error) {
        [session setActive:YES error:&error];
        
        if (!error) {
            if (_playThroughSpeaker) {
                self.selectedCell.speakerButton.selected = YES;
            }
            else {
                self.selectedCell.speakerButton.selected = NO;
            }
        }
    }
}


@end
