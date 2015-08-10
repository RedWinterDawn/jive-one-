//
//  JCCallerViewController.m
//  JiveOne
//
//  This controller in responsible for managing call options, i.e.: Blind transfer, Warm transfer, Adding calls, Merging
//  calls, Splitting calls, controlling mute and speaker options. It managed the view workflow for transfers. In manages
//  the state of a subview which visually displays all the call options available for any given state. Its in closely
//  coupled with the call card manager, for call actions and the SipHandler for the mute, speaker, and other behaviors.
//
//  When a dial string is set before the view is loaded, it will be dialed.
//
//  Created by Robert Barclay on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneCallViewController.h"

// Managers
#import "JCPhoneManager.h"   // Handles call cards, and managed calls

// Presented View Controllers
#import "JCPhoneDialerViewController.h"             // Shows dial pad to dial for blind, warm transfer and additional call.
#import "JCPhoneCallTransferConfirmationViewController.h"    // Transfer confimation view controller
#import "JCPhoneCallCollectionViewController.h"

#import "JCPhoneSipSession.h"
#import "JCCallCard.h"

#define CALL_OPTIONS_ANIMATION_DURATION 0.6
#define TRANSFER_ANIMATION_DURATION 0.3
#define KEYBOARD_ANIMATION_DURATION 0.3

NSString *const kJCCallerViewControllerTransferStoryboardIdentifier = @"warmTransferModal";
NSString *const kJCCallerViewControllerKeyboardStoryboardIdentifier = @"keyboardModal";

NSString *const kJCCallerViewControllerBlindTransferCompleteSegueIdentifier = @"blindTransferComplete";

@interface JCPhoneCallViewController () <JCPhoneDialerViewControllerDelegate>
{
    UIViewController *_presentedTransferViewController;
    UIViewController *_presentedKeyboardViewController;
    NSTimeInterval _defaultCallOptionViewConstraint;
    
    bool _showingCallOptions;
    BOOL _showingConferenceCall;
    
    JCPhoneCallCollectionViewController *_callCardCollectionViewController;
}

@end

@implementation JCPhoneCallViewController

CGFloat *_callOptionsWidth;

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _callOptionTransitionAnimationDuration = CALL_OPTIONS_ANIMATION_DURATION;
        _transferAnimationDuration             = TRANSFER_ANIMATION_DURATION;
        _keyboardAnimationDuration             = KEYBOARD_ANIMATION_DURATION;
        
        self.warmTransfer.enabled       = false;
        self.blindTransfer.enabled      = false;
        self.swapBtn.enabled            = false;
        self.mergeBtn.enabled           = false;
        self.addBtn.enabled             = false;
        self.finishTransferBtn.enabled  = false;
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCPhoneCallCollectionViewController class]]) {
        _callCardCollectionViewController = (JCPhoneCallCollectionViewController *)viewController;
    }
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    // determine if call options should be shown
    if ([self shouldShowCallOptions]) {
        [self showCallOptionsAnimated:YES];
    } else {
        [self hideCallOptionsAnimated:NO];
    }
        
    // determine call options view state
    [self.callOptionsView setState:[self stateForOptionView] animated:YES];
    
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(void)dealloc
{
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
}

-(void)reload
{
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [_callCardCollectionViewController.collectionView reloadData];
}

-(void)startConferenceCall
{
    _showingConferenceCall = TRUE;
    [UIView transitionWithView:_callCardCollectionViewController.view
                      duration:0.3
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        [self reload];
                    } completion:NULL];
}

-(void)stopConferenceCall
{
    _showingConferenceCall = FALSE;
    [UIView transitionWithView:_callCardCollectionViewController.view
                      duration:0.3
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        [self reload];
                    } completion:NULL];
}

#pragma mark - IBActions -

-(IBAction)mute:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
        JCPhoneManager *phoneManager = self.phoneManager;
        [phoneManager muteCall:!phoneManager.isMuted];
        button.selected = phoneManager.isMuted;
    }
}

-(IBAction)keypad:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        if (!_presentedKeyboardViewController) {
            JCPhoneDialerViewController *keyboardViewController = [self.storyboard instantiateViewControllerWithIdentifier:kJCCallerViewControllerKeyboardStoryboardIdentifier];
            keyboardViewController.delegate = self;
            [self presentKeyboardViewController:keyboardViewController];
            button.selected = TRUE;
        }
        else {
            [self dismissKeyboardViewController:YES];
            button.selected = FALSE;
        }
    }
}

-(IBAction)speaker:(id)sender
{
    JCPhoneManager *phoneManager = self.phoneManager;
    [phoneManager setLoudSpeakerEnabled:(phoneManager.outputType != JCPhoneAudioManagerOutputSpeaker)];
}

-(IBAction)blindTransfer:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.enabled = NO;
        [self presentTransferViewControllerWithDialType:JCPhoneManagerBlindTransfer
                                             completion:^(BOOL success, NSError *error) {
                                                 button.enabled = YES;
                                             }];
    }
}

-(IBAction)warmTransfer:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.enabled = NO;
        [self presentTransferViewControllerWithDialType:JCPhoneManagerWarmTransfer
                                             completion:^(BOOL success, NSError *error) {
                                                 button.enabled = YES;
                                             }];
    }
}

-(IBAction)addCall:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.enabled = NO;
        
        [self presentTransferViewControllerWithDialType:JCPhoneManagerSingleDial
                                             completion:^(BOOL success, NSError *error) {
                                                 button.enabled = YES;
                                             }];
    }
}

-(IBAction)swapCall:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.enabled = false;
        [self.phoneManager swapCalls:^(BOOL success, NSError *error) {
            button.enabled = true;
        }];
    }
}

-(IBAction)mergeCall:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]){
        UIButton *button = (UIButton *)sender;
        button.enabled = false;
        JCPhoneManager *phoneManager = self.phoneManager;
        if (phoneManager.isConferenceCall) {
            [phoneManager splitCalls:^(BOOL success, NSError *error) {
                if (success) {
                    self.mergeLabel.text = NSLocalizedStringFromTable(@"Merge Calls", @"Phone", @"Merge Call Display Button");
                    button.selected = FALSE;
                }
                button.enabled = TRUE;
            }];
        } else {
            [phoneManager mergeCalls:^(BOOL success, NSError *error) {
				if (success) {
					self.mergeLabel.text = NSLocalizedStringFromTable(@"Split Calls", @"Phone", @"Merge Call Display Button");
                    button.selected = TRUE;
				}
                button.enabled = TRUE;
			}];
        }
    }
}

-(IBAction)finishTransfer:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.enabled = NO;
        JCPhoneManager *phoneManager = self.phoneManager;
        [phoneManager finishWarmTransfer:^(BOOL success, NSError *error) {
            if (!success) {
                [JCAlertView alertWithError:error];
            }
            button.enabled = YES;
        }];
    }
}

#pragma mark - Private -

-(BOOL)shouldShowCallOptions
{
    NSArray *calls = self.phoneManager.calls;
    if (calls.count > 1) {
        BOOL isIncoming = TRUE;
        for (JCCallCard *call in calls) {
            if (!call.lineSession.isIncoming) {
                isIncoming = FALSE;
                break;
            }
        }
        return !isIncoming;
    } else {
        JCCallCard *call = calls.firstObject;
        if (call.lineSession.isIncoming) {
            return NO;
        }
        return YES;
    }
}

-(JCCallOptionViewState)stateForOptionView
{
    JCPhoneManager *phoneManager = self.phoneManager;
    JCCallOptionViewState state = JCCallOptionViewSingleCallState;
    if (_showingConferenceCall) {
        state = JCCallOptionViewConferenceCallState;
    }
    else if (phoneManager.calls.count > 1) {
        state = JCCallOptionViewMultipleCallsState;
        NSArray *calls = phoneManager.calls;
       
            for (JCCallCard *call in calls) {
                if (call.lineSession.isTransfer) {
                    state = JCCallOptionViewFinishTransferState;
                    break;
                }
            }
        }
    return state;
}

/**
 * Hides the call options card.
 */
-(void)hideCallOptionsAnimated:(BOOL)animated
{
    _callOptionsViewOriginYConstraint.constant = 10;
    [self.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:animated ? _callOptionTransitionAnimationDuration : 0
                     animations:^{
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         _showingCallOptions = false;
                         [_callCardCollectionViewController.collectionViewLayout invalidateLayout];
                     }];
}

/**
 * Show All call options card.
 */

-(void)showCallOptionsAnimated:(BOOL)animated
{
    if (_showingCallOptions) {
        return;
    }
    
    _callOptionsViewOriginYConstraint.constant = 228;
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:animated ? 0.1 : 0
                     animations:^{
                         
                     } completion:^(BOOL finished) {
                         _showingCallOptions = false;
                         [_callCardCollectionViewController.collectionViewLayout invalidateLayout];
                     }];
    
    // Flip view to show a transition state
    [UIView transitionWithView:self.view
                      duration:_callOptionTransitionAnimationDuration
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:NULL
                    completion:^(BOOL finished) {
                        _showingCallOptions = TRUE;
                        [_callCardCollectionViewController.collectionViewLayout invalidateLayout];
                    }];
}

/**
 * Displays the "Transfer Success page" after a warm or blind transfer.
 */
-(void)showTransferSuccess
{
    [self performSegueWithIdentifier:kJCCallerViewControllerBlindTransferCompleteSegueIdentifier sender:self];
}

-(void)presentKeyboardViewController:(UIViewController *)viewController
{
    if (viewController == _presentedKeyboardViewController)
        return;
    
    _presentedKeyboardViewController = viewController;
    [self addChildViewController:viewController];
    
    CGRect bounds = (self.view.bounds);
    CGRect frame = self.view.frame;
    frame.origin.y = -frame.size.height;
    viewController.view.frame = frame;
    [self.view addSubview:viewController.view];
    [UIView animateWithDuration:_keyboardAnimationDuration
                     animations:^{
                         viewController.view.frame = bounds;
                     }
                     completion:NULL];
}

-(void)dismissKeyboardViewController:(bool)animated
{
    UIViewController *viewController = _presentedKeyboardViewController;
    CGRect frame = self.view.frame;
    frame.origin.y = -frame.size.height;
    [UIView animateWithDuration:(animated ? _keyboardAnimationDuration : 0)
                     animations:^{
                         viewController.view.frame = frame;
                     } completion:^(BOOL finished) {
                         [viewController removeFromParentViewController];
                         [viewController.view removeFromSuperview];
                         _presentedKeyboardViewController = nil;
                         _keypadButton.selected = FALSE;
                     }];
}

-(void)presentTransferViewControllerWithDialType:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion
{
    if (_presentedKeyboardViewController){
        [self dismissKeyboardViewController:YES];
    }
    
    JCPhoneDialerViewController *transferViewController = [self.storyboard instantiateViewControllerWithIdentifier:kJCCallerViewControllerTransferStoryboardIdentifier];
    transferViewController.transferCallType = dialType;
    transferViewController.delegate = self;
    
    _presentedTransferViewController = transferViewController;
    [self addChildViewController:transferViewController];
    CGRect bounds = self.view.bounds;
    CGRect frame = self.view.frame;
    frame.origin.y = frame.origin.y + frame.size.height;
    transferViewController.view.frame = frame;
    [self.view addSubview:transferViewController.view];
    [UIView animateWithDuration:_transferAnimationDuration
                     animations:^{
                         transferViewController.view.frame = bounds;
                     }
                     completion:^(BOOL finished) {
                         if (completion) {
                            completion(YES, nil);
                         }
                     }];
}

-(void)dismissTransferViewControllerAnimated:(bool)animated;
{
    UIViewController *viewController = _presentedTransferViewController;
    CGRect frame = self.view.frame;
    frame.origin.y = frame.origin.y + frame.size.height;
    [UIView animateWithDuration:(animated ? _transferAnimationDuration : 0)
                     animations:^{
                         viewController.view.frame = frame;
                     } completion:^(BOOL finished) {
                         [viewController removeFromParentViewController];
                         [viewController.view removeFromSuperview];
                         _presentedTransferViewController = nil;
                     }];
}

#pragma mark - Delegate Handlers -

#pragma mark JCTransferViewController

-(void)phoneDialerViewController:(JCPhoneDialerViewController *)controller shouldDialNumber:(id<JCPhoneNumberDataSource>)number
{
    JCPhoneManager *phoneManager = self.phoneManager;
    [phoneManager dialPhoneNumber:number
              provisioningProfile:phoneManager.provisioningProfile
                             type:controller.transferCallType
                       completion:^(BOOL success, NSError *error) {
                           [self dismissTransferViewControllerAnimated:YES];
                           if (success) {
                               switch (controller.transferCallType) {
                                   case JCPhoneManagerSingleDial:
                                       [self.callOptionsView setState:JCCallOptionViewMultipleCallsState animated:YES];
                                       break;
                               
                                   case JCPhoneManagerWarmTransfer:
                                       [self.callOptionsView setState:JCCallOptionViewFinishTransferState animated:YES];
                                       break;
                                   
                                   default:
                                       break;
                               }
                           }
                       }];
}

-(void)shouldCancelPhoneDialerViewController:(JCPhoneDialerViewController *)controller
{
    [self dismissTransferViewControllerAnimated:YES];
}


@end
