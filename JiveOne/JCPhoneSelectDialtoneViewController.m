//
//  JCDialToneTableViewController.m
//  JiveOne
//
//  Created by P Leonard on 6/26/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import AVFoundation;
@import MediaPlayer;

#import "JCPhoneSelectDialtoneViewController.h"
#import "JCPhoneManager.h"

static NSString *RingtoneCellReuseIdentifier = @"ringtone";
static NSString *VolumeCellReuseIdentifier = @"volume";

@interface JCPhoneSelectDialtoneViewController (){
    NSArray *_dialTones;
    JCPhoneAudioManager *_audioManager;
}

@end

@implementation JCPhoneSelectDialtoneViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _audioManager = [[JCPhoneAudioManager alloc] initWithPhoneSettings:self.phoneManager.settings];
    _dialTones = @[@"Old Phone", @"Sifi", @"iReport", @"Walkie - Talkie", @"Edm Trumpets", @"Nokia Tune", @"Piano Riff"];
    
    MPVolumeView *volumeView = [MPVolumeView new];
    volumeView.showsRouteButton = true;
    self.routeIconBackground.hidden = !volumeView.showsRouteButton;
    
    // Settings Info
    [self layoutDialtones:_dialTones animated:NO];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    if (_audioManager){
        [_audioManager stop];
    }
}

- (CGFloat)heightForCell:(UITableViewCell *)cell
{
    if ([cell.reuseIdentifier isEqualToString:VolumeCellReuseIdentifier]) {
        return 80;
    }
    else if ([cell.reuseIdentifier isEqualToString:RingtoneCellReuseIdentifier]) {
        return 44;
    }
    return self.tableView.rowHeight;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1) {
        self.phoneManager.settings.ringtone = _dialTones[indexPath.row];
        [_audioManager playIncomingCallToneDemo];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1){
        NSString *dialTone = _dialTones[indexPath.row];
        if ([self.phoneManager.settings.ringtone isEqualToString:dialTone]){
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    }
}

#pragma mark - Private -

-(void)layoutDialtones:(NSArray *)dialtones animated:(BOOL)animated
{
    [self startUpdates];
    for (int x = 0; x < [_dialTones count]; x++){
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RingtoneCellReuseIdentifier];
        cell.textLabel.text = _dialTones[x];
        [self addCell:cell atIndexPath:[NSIndexPath indexPathForRow:x inSection:1]];
    }
    
    [self endUpdates];
    
}

@end
