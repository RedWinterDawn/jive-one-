//
//  JCMessageParticipantViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMessageParticipantViewController.h"

@interface JCMessageParticipantViewController ()
{
    UITableViewController *_participantsTableViewController;
}

@end

@implementation JCMessageParticipantViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.containerView.clipsToBounds = TRUE;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[UITableViewController class]]) {
        _participantsTableViewController = (UITableViewController *)viewController;
    }
}

-(void)viewWillLayoutSubviews {
    
    [super viewWillLayoutSubviews];
    
//    CGSize size = _participantsTableViewController.tableView.contentSize;
//    CGRect frame = _participantsTableViewController.view.frame;
//    frame.size.height = size.height;
//    _participantsTableViewController.view.frame = frame;
}

@end
