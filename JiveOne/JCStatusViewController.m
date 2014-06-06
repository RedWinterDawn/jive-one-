//
//  JCStatusViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCStatusViewController.h"
#import "JCSocketDispatch.h"

@interface JCStatusViewController ()

@end

@implementation JCStatusViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self refresh:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveSocketEvent:) name:@"kSocketEvent" object:nil];
    
    self.lastSocketEventTextView.scrollsToTop = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kSocketEvent" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didReceiveSocketEvent:(NSNotification *)notification
{
    NSString *currentText = self.lastSocketEventTextView.text;
    if (currentText) {
        currentText = [currentText stringByAppendingString:@"################\n\n"];
        currentText = [currentText stringByAppendingString:[NSString stringWithFormat:@"%@", [notification.object description]]];
        self.lastSocketEventTextView.text = currentText;
    }
    else {
        self.lastSocketEventTextView.text = [NSString stringWithFormat:@"%@", [notification.object description]];
    }
    [self refresh:nil];
}

- (IBAction)refresh:(id)sender {
    
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:UDdeviceToken];
    
    if (deviceToken) {
        self.tokenLabel.text = deviceToken;
    } else {
        self.tokenLabel.text = @"no token. are you in simulator?";
    }
    
    
    NSInteger count = [JCSocketDispatch sharedInstance].subscriptionCount;
    _subscription2.text = [NSString stringWithFormat:@"Subscribed to %ld events", (long)count];
    
    
    SRReadyState state = [JCSocketDispatch sharedInstance].webSocket.readyState;
    switch (state) {
        case SR_CLOSED:
            self.socketStatusLabel.text = @"Closed";
            self.socketStatusLabel.textColor = [UIColor redColor];
            break;
        case SR_CLOSING:
            self.socketStatusLabel.text = @"Closing";
            break;
        case SR_CONNECTING:
            self.socketStatusLabel.text = @"Connecting";
            break;
        case SR_OPEN:
            self.socketStatusLabel.text = @"Open";
            break;
            
        default:
            break;
    }
}

- (IBAction)poll:(id)sender {
    [[JCSocketDispatch sharedInstance] sendPoll];
}


#pragma mark - UITableViewController Delegates
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}





@end
