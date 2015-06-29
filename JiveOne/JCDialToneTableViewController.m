//
//  JCDialToneTableViewController.m
//  JiveOne
//
//  Created by P Leonard on 6/26/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCDialToneTableViewController.h"
#import "JCAppSettings.h"
#import "JCPhoneAudioManager.h"

@interface JCDialToneTableViewController (){
    NSArray *_dialTones;
    JCPhoneAudioManager *_audioManager;
}

@end

@implementation JCDialToneTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _audioManager = [JCPhoneAudioManager new];

    _dialTones = @[@"Ring", @"Old Phone", @"Sifi", @"iReport", @"Walkie - Talkie", @"Call For All", @"Edm Trumpets", @"Nokia Tune", @"Piano Riff"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
     return _dialTones.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"ringToneCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    cell.textLabel.text = _dialTones[indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
   
    self.appSettings.ringTone = _dialTones[indexPath.row];
    [_audioManager playIncomingCallToneDemo];
}

@end
