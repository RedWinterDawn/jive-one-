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
    NSArray *dialTones;
    
}
@property (nonatomic) JCPhoneAudioManager* audioManager;

@end

@implementation JCDialToneTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _audioManager = [JCPhoneAudioManager new];

    dialTones = @[@"ambiant", @"calling", @"dialup", @"futureDial", @"iReport", @"oldPhone", @"sifi", @"walkietalkie"];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
     return dialTones.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"ringToneCell";
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if(!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }

    cell.textLabel.text = dialTones[indexPath.row];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
   
    self.appSettings.ringTone = dialTones[indexPath.row];
    NSLog(@"%@", dialTones[indexPath.row]);
    NSLog(@"%@", self.appSettings.ringTone);
    [_audioManager playIncomingCallToneDemo];
}


#pragma mark - Navigation

@end
