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
#import "JCPhoneAudioManager.h"
#import "JCPhoneManager.h"

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

    _dialTones = @[@"Old Phone", @"Sifi", @"iReport", @"Walkie - Talkie", @"Edm Trumpets", @"Nokia Tune", @"Piano Riff"];
    MPVolumeView *volumeView = [MPVolumeView new];
    volumeView.showsRouteButton = true;
    self.routeIconBackground.hidden = !volumeView.showsRouteButton;
    
    
    // Settings Info
    [self layoutDialTone:_dialTones animated:NO];
    
}
-(void)viewWillDisappear:(BOOL)animated{
    if (_audioManager)
    {
        
        [_audioManager stop];
    }
}
-(void)layoutDialTone:(NSArray *)dialtone animated:(BOOL)animated
{
    [self startUpdates];
    
    for (int x = 0; x < [_dialTones count]; x++){
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ringtone"];
        cell.textLabel.text = _dialTones[x];
        [self addCell:cell atIndexPath:[NSIndexPath indexPathForRow:x inSection:1]];
    }
    
    [self endUpdates];
    
}

- (CGFloat)heightForCell:(UITableViewCell *)cell
{
    if ([cell.reuseIdentifier isEqualToString:@"volume"]) {
        return 80;
    }
    else if ([cell.reuseIdentifier isEqualToString:@"ringtone"]) {
        return 44;
    }
    return self.tableView.rowHeight;
}


#pragma mark - Table view data source

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

@end
