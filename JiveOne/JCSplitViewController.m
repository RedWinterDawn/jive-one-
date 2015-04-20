//
//  JCSplitViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 4/20/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSplitViewController.h"

@implementation JCSplitViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:231/255.0f green:231/255.0f blue:234/255.0f alpha:1];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
