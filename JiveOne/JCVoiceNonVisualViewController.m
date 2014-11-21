//
//  JCVoiceNonVisualViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoiceNonVisualViewController.h"
#import "JCCallerViewController.h"

@interface JCVoiceNonVisualViewController () <JCCallerViewControllerDelegate>

@end

@implementation JCVoiceNonVisualViewController

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCCallerViewController class]]) {
        JCCallerViewController *callerViewController = (JCCallerViewController *)viewController;
        callerViewController.delegate = self;
        callerViewController.dialString = @"*99";
    }
}

-(void)shouldDismissCallerViewController:(JCCallerViewController *)viewController
{
    [self dismissViewControllerAnimated:NO completion:^{
        
    }];
}

@end
