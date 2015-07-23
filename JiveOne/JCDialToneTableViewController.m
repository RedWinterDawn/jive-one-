//
//  JCDialToneTableViewController.m
//  JiveOne
//
//  Created by P Leonard on 6/26/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import AVFoundation;
@import MediaPlayer;

#import "JCDialToneTableViewController.h"
#import "JCAppSettings.h"
#import "JCPhoneAudioManager.h"

#import "JCSysVolCell.h"
#import "JCRingToneCell.h"

@interface JCDialToneTableViewController (){
    NSArray *_dialTones;
    
    JCPhoneAudioManager *_audioManager;
}

@end

@implementation JCDialToneTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (_audioManager) {
        [_audioManager stop];
    }
    _audioManager = [JCPhoneAudioManager new];

    _dialTones = @[@"Ring", @"Old Phone", @"Sifi", @"iReport", @"Walkie - Talkie", @"Edm Trumpets", @"Nokia Tune", @"Piano Riff"];
    MPVolumeView *volumeView = [MPVolumeView new];
    self.routeIconBackground.hidden = !volumeView.showsRouteButton;
    
    // Settings Info
    JCAppSettings *settings = self.appSettings;
    _volumeslidder.value = settings.volumeLevel;
    [self layoutDialTone:_dialTones animated:NO];
    
}

-(void)layoutDialTone:(NSArray *)dialtone animated:(BOOL)animated
{
    [self startUpdates];
    
    for (int x = 0; x < [_dialTones count]; x++){
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ringtone"];
        cell.textLabel.text = _dialTones[x];
        [self addCell:cell atIndexPath:[NSIndexPath indexPathForRow:x inSection:2]];
    }
    
    [self endUpdates];
    
}
- (IBAction)sliderValue:(id)sender {
    self.appSettings.volumeLevel = _volumeslidder.value;
    [_audioManager playIncomingCallToneDemo];  //Plays a snippit of the ringer so the user know how load it is going ot be
}

- (CGFloat)heightForCell:(UITableViewCell *)cell
{
    if ([cell isKindOfClass:[JCSysVolCell class]]) {
        return 80;
    }
    else if ([cell isKindOfClass:[JCRingToneCell class]]) {
        return 44;
    }
    return self.tableView.rowHeight;
}


#pragma mark - Table view data source

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 2) {
        self.appSettings.ringtone = _dialTones[indexPath.row];
        [_audioManager playIncomingCallToneDemo];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2){
        NSString *dialTone = _dialTones[indexPath.row];
        if ([self.appSettings.ringtone isEqualToString:dialTone]){
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    }
}

@end
