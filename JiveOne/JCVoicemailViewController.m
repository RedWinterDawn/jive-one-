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

#import "JCVoicemailViewController.h"

#import "JCVoicemailTableViewController.h"
#import "PBX+Custom.h"

NSString *const kJCVoiceNonVisualViewControllerIdentifier = @"VoiceNonVisualViewController";

@interface JCVoicemailViewController ()
{
    JCVoicemailTableViewController *_voicemailTableViewController;
    Voicemail *_voicemail;
}

@end

@implementation JCVoicemailViewController

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    PBX *pbx = [PBX fetchFirstPBX];
    if (![pbx.v5 boolValue])
    {
        [_voicemailTableViewController.view removeFromSuperview];
        [_voicemailTableViewController removeFromParentViewController];
        _voicemailTableViewController = nil;
        
        @try {
            UIViewController *nonVisualViewController = [self.storyboard instantiateViewControllerWithIdentifier:kJCVoiceNonVisualViewControllerIdentifier];
            [self addChildViewController:nonVisualViewController];
            [self.containerView addSubview:nonVisualViewController.view];
        }
        @catch (NSException *exception) {
            NSLog(@"Non Visual Voicmail View Controller was unable to to loaded from the storyboard, was expecting identifier: %@", kJCVoiceNonVisualViewControllerIdentifier);
        }
    }
    else
    {
        if (_voicemail)
        {
            NSIndexPath *indexPath = [_voicemailTableViewController indexPathOfObject:_voicemail];
            [_voicemailTableViewController.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            [_voicemailTableViewController tableView:_voicemailTableViewController.tableView didSelectRowAtIndexPath:indexPath];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCVoicemailTableViewController class]])
    {
        _voicemailTableViewController = (JCVoicemailTableViewController *)viewController;
    }
}

#pragma mark - Methods -

-(void)loadVoicemail:(Voicemail *)voicemail
{
    _voicemail = voicemail;
    [self.view setNeedsLayout];
}

@end
