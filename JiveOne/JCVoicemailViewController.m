//
//  JCVoiceViewController.m
//  JiveOne
//
//  This is a wrapper view controller that encapsulates v4 and v5 voicemail functionality. v4 does
//  not have visual voicemail, so we need to present a different UI when thier PBX is a v4 account.
//  When the PBX is a v5 Account, normal workflow is followed, loading the visual table view
//  controller.
//
//  Created by Robert Barclay on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailViewController.h"

#import "JCVoicemailTableViewController.h"
#import "PBX.h"
#import "Line.h"

NSString *const kJCVoiceNonVisualViewControllerIdentifier = @"VoiceNonVisualViewController";

@interface JCVoicemailViewController ()

@property (nonatomic, strong) JCVoicemailTableViewController *visualVoicemailViewController;
@property (nonatomic, strong) UIViewController *nonVisualVoicemailViewController;

@end

@implementation JCVoicemailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lineChanged:) name:kJCAuthenticationManagerLineChangedNotification object:[JCAuthenticationManager sharedInstance]];
}

-(void)lineChanged:(NSNotification *)notification
{
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (![JCAuthenticationManager sharedInstance].line.pbx.isV5)
    {
        JCVoicemailTableViewController *visualVoicemailViewController = self.visualVoicemailViewController;
        if (visualVoicemailViewController.view.superview != nil) {
            [visualVoicemailViewController.view removeFromSuperview];
            [visualVoicemailViewController removeFromParentViewController];
        }
        
        UIViewController *nonVisualViewController = self.nonVisualVoicemailViewController;
        [self addChildViewController:nonVisualViewController];
        nonVisualViewController.view.frame = self.containerView.bounds;
        [self.containerView addSubview:nonVisualViewController.view];
    }
    else
    {
        UIViewController *nonVisualViewController = self.nonVisualVoicemailViewController;
        if (nonVisualViewController.view.superview != nil) {
            [nonVisualViewController.view removeFromSuperview];
            [nonVisualViewController removeFromParentViewController];
        }
        
        JCVoicemailTableViewController *visualVoicemailViewController = self.visualVoicemailViewController;
        [self addChildViewController:visualVoicemailViewController];
        visualVoicemailViewController.view.frame = self.containerView.bounds;
        [self.containerView addSubview:visualVoicemailViewController.view];
        
        if (self.voicemail)
        {
            NSIndexPath *indexPath = [visualVoicemailViewController indexPathOfObject:self.voicemail];
            [visualVoicemailViewController.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            [visualVoicemailViewController tableView:visualVoicemailViewController.tableView didSelectRowAtIndexPath:indexPath];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCVoicemailTableViewController class]]){
        self.visualVoicemailViewController = (JCVoicemailTableViewController *)viewController;
    }
}

-(UIViewController *)nonVisualVoicemailViewController {
    if (!_nonVisualVoicemailViewController) {
        @try {
            _nonVisualVoicemailViewController = [self.storyboard instantiateViewControllerWithIdentifier:kJCVoiceNonVisualViewControllerIdentifier];
        }
        @catch (NSException *exception) {
            NSLog(@"Non Visual Voicmail View Controller was unable to to loaded from the storyboard, was expecting identifier: %@", kJCVoiceNonVisualViewControllerIdentifier);
        }
    }
    return _nonVisualVoicemailViewController;
}


#pragma mark - Methods -

-(void)setVoicemail:(Voicemail *)voicemail
{
    _voicemail = voicemail;
    [self.view setNeedsLayout];
}

@end
