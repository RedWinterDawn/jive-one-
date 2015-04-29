//
//  JCCallHistoryViewController_iPad.m
//  JiveOne
//
//  Created by Robert Barclay on 4/21/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCallHistoryTableViewController_iPad.h"
#import "MissedCall.h"
#import "JCAuthenticationManager.h"
#import "Line.h"
#import "PBX.h"

NSString *const kJCCallHistoryNonVisualVoicemailViewControllerIdentifier = @"NonVisualVoicemailViewController";
NSString *const kJCCallHistoryVisualVoicemailViewControllerIdentifier = @"VisualVoicemailViewController";

@interface JCCallHistoryTableViewController_iPad ()

@property (nonatomic, strong) UIViewController *voicemailViewController;

@end

@implementation JCCallHistoryTableViewController_iPad

-(IBAction)toggleFilterState:(id)sender
{
    if ([sender isKindOfClass:[UISegmentedControl class]])
    {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
        switch (segmentedControl.selectedSegmentIndex) {
            case 1:
            {
                [self hideVoicemail];
                NSFetchRequest *fetchRequest = [MissedCall MR_requestAll];
                fetchRequest.fetchBatchSize = 6;
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:false];
                fetchRequest.sortDescriptors = @[sortDescriptor];
                self.fetchRequest = fetchRequest;
                break;
            }
            case 2:
            {
                [self showVoicemail];
                break;
            }
            default:
                [self hideVoicemail];
                self.fetchRequest = nil;
                break;
        }
    }
}

-(void)showVoicemail
{
    UIViewController *viewController = self.voicemailViewController;
    [self addChildViewController:viewController];
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    viewController.view.frame = self.view.bounds;
    viewController.view.translatesAutoresizingMaskIntoConstraints = TRUE;
    [self.view addSubview:viewController.view];
    [self.view bringSubviewToFront:viewController.view];
}

-(void)hideVoicemail
{
    if (!_voicemailViewController) {
        return;
    }
    
    UIViewController *viewController = self.voicemailViewController;
    [viewController removeFromParentViewController];
    [viewController.view removeFromSuperview];
    _voicemailViewController = nil;
}

-(UIViewController *)voicemailViewController {
    if (!_voicemailViewController) {
        NSString *storyboardIdentifier = kJCCallHistoryVisualVoicemailViewControllerIdentifier;
        if (!self.authenticationManager.line.pbx.isV5) {
            storyboardIdentifier = kJCCallHistoryNonVisualVoicemailViewControllerIdentifier;
        }
        
        @try {
            _voicemailViewController = [self.storyboard instantiateViewControllerWithIdentifier:storyboardIdentifier];
        }
        @catch (NSException *exception) {
            NSLog(@"Non Visual Voicmail View Controller was unable to to loaded from the storyboard, was expecting identifier: %@", storyboardIdentifier);
        }
    }
    return _voicemailViewController;
}

@end
