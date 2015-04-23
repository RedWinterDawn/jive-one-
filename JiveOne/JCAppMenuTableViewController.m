//
//  JCAppMenuViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 4/21/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAppMenuTableViewController.h"
#import "JCStoryboardLoaderViewController.h"

#import "JCPhoneManager.h"
#import "PBX.h"

@implementation JCAppMenuTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(lineChanged:) name:kJCAuthenticationManagerLineChangedNotification object:self.authenticationManager];
    
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *viewController = segue.destinationViewController;
    
    if ([viewController isKindOfClass:[JCStoryboardLoaderViewController class]]) {
        viewController = ((JCStoryboardLoaderViewController *)viewController).embeddedViewController;
    }
    
    if ([viewController isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *splitViewController = (UISplitViewController *)viewController;
        viewController = splitViewController.viewControllers.firstObject;
    }
    
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)viewController;
        UIColor *barColor = navigationController.navigationBar.barTintColor;
        self.navigationController.navigationBar.barTintColor = barColor;
    }
}

-(void)lineChanged:(NSNotification *)notification
{
    [self cell:self.messageCell setHidden:!self.authenticationManager.pbx.smsEnabled];
    [self reloadDataAnimated:NO];
    
    CGSize size = self.tableView.contentSize;
    [_delegate appMenuTableViewController:self willChangeToSize:size];
}

@end
