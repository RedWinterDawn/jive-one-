//
//  JCModuleSplitViewControllerDelegate.m
//  JiveOne
//
//  Created by Robert Barclay on 4/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCModuleSplitViewControllerDelegate.h"

@implementation JCModuleSplitViewControllerDelegate

-(BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return false;
}

@end
