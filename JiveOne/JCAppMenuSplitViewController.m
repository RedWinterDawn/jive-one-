//
//  JCAppMenuSplitViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 4/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAppMenuSplitViewController.h"

@interface JCAppMenuSplitViewController ()

@end

@implementation JCAppMenuSplitViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:231/255.0f green:231/255.0f blue:234/255.0f alpha:1];
    self.maximumPrimaryColumnWidth = 240.0f;
    self.minimumPrimaryColumnWidth = 240.0f;
}

@end
