//
//  JCAppMenuViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 4/21/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAppMenuViewController.h"
#import "JCStoryboardLoaderViewController.h"

#import "JCPhoneManager.h"

@implementation JCAppMenuViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
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
//        self.splitViewController.view.backgroundColor = barColor;
//        viewController.splitViewController.view.backgroundColor = barColor;
//        viewController.navigationController.view.backgroundColor = barColor;
    }
}

@end
