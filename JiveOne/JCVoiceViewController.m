//
//  JCVoiceViewController.m
//  JiveOne
//
//  This is a wrapper view controller that encapsulates v4 and v5 voicemail functionality. v4 does not have visual
//  voicemail, so we need to present a different UI when thier PBX is a v4 account. When the PBX is a v5 Account, normal
//  workflow is followed, loading the visual table view controller.
//
//  Created by Robert Barclay on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoiceViewController.h"

#import "JCVoiceTableViewController.h"
#import "PBX+Custom.h"

NSString *const kJCVoiceNonVisualViewControllerIdentifier = @"VoiceNonVisualViewController";

@interface JCVoiceViewController ()
{
    JCVoiceTableViewController *_voiceTableViewController;
}

@end

@implementation JCVoiceViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    PBX *pbx = [PBX fetchFirstPBX];
    if (![pbx.v5 boolValue])
    {
        [_voiceTableViewController.view removeFromSuperview];
        [_voiceTableViewController removeFromParentViewController];
        
        @try {
            UIViewController *nonVisualViewController = [self.storyboard instantiateViewControllerWithIdentifier:kJCVoiceNonVisualViewControllerIdentifier];
            [self addChildViewController:nonVisualViewController];
            [self.containerView addSubview:nonVisualViewController.view];
        }
        @catch (NSException *exception) {
            NSLog(@"Non Visual Voicmail View Controller was unable to to loaded from the storyboard, was expecting identifier: %@", kJCVoiceNonVisualViewControllerIdentifier);
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCVoiceTableViewController class]])
        _voiceTableViewController = (JCVoiceTableViewController *)viewController;
}

@end
