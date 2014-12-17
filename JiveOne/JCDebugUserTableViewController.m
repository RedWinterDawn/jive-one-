//
//  JCDebugUserTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 12/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDebugUserTableViewController.h"
#import "JCDebugPbxsTableViewController.h"

@implementation JCDebugUserTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    User *user = self.user;
    
    self.jiveUserId.text = user.jiveUserId;
    self.pbxs.text = [NSString stringWithFormat:@"%lu", (unsigned long)user.pbxs.count];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCDebugPbxsTableViewController class]]) {
        ((JCDebugPbxsTableViewController *)viewController).user = self.user;
    }
}


@end
