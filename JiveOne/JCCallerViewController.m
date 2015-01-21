//
//  JCCallerViewController.m
//  JiveOne
//
//  This controller in responsible for managing call options, i.e.: Blind transfer, Warm transfer, Adding calls, Merging
//  calls, Splitting calls, controlling mute and speaker options. It managed the view workflow for transfers. In manages
//  the state of a subview which visually displays all the call options available for any given state. Its in closely
//  coupled with the call card manager, for call actions and the SipHandler for the mute, speaker, and other behaviors.
//
//  When a dial string is set befor ethe view is loaded, it will be dialed.
//
//  Created by Robert Barclay on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallerViewController.h"


// Managers
#import "JCPhoneManager.h"   // Handles call cards, and managed calls

// Presented View Controllers
#import "JCTransferViewController.h"                // Shows dial pad to dial for blind, warm transfer and additional call.
#import "JCKeypadViewController.h"                  // Numberpad
#import "JCTransferConfirmationViewController.h"    // Transfer confimation view controller
#import "JCCallCardCollectionViewController.h"

#import "UIViewController+HUD.h"
#define CALL_OPTIONS_ANIMATION_DURATION 0.6
#define TRANSFER_ANIMATION_DURATION 0.3
#define KEYBOARD_ANIMATION_DURATION 0.3

#define kCallOptionsDefualtContraint 116
#define kHalfCallOptionsContraint 232

NSString *const kJCCallerViewControllerTransferStoryboardIdentifier = @"warmTransferModal";
NSString *const kJCCallerViewControllerKeyboardStoryboardIdentifier = @"keyboardModal";

NSString *const kJCCallerViewControllerBlindTransferCompleteSegueIdentifier = @"blindTransferComplete";

@interface JCCallerViewController () <JCTransferViewControllerDelegate, JCKeypadViewControllerDelegate>
{
    UIViewController *_presentedTransferViewController;
    UIViewController *_presentedKeyboardViewController;
    NSTimeInterval _defaultCallOptionViewConstraint;
    
    bool _showingCallOptions;
    BOOL _showingConferenceCall;
    
    JCCallCardCollectionViewController *_callCardCollectionViewController;
}

@property (nonatomic, strong) NSDictionary *warmTransferInfo;

@end

@implementation JCCallerViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _callOptionTransitionAnimationDuration = CALL_OPTIONS_ANIMATION_DURATION;
        _transferAnimationDuration             = TRANSFER_ANIMATION_DURATION;
        _keyboardAnimationDuration             = KEYBOARD_ANIMATION_DURATION;
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    // determine if call options should be shown
    if ([_dataSource callerViewControllerShouldShowCallOptions:self]) {
        [self showCallOptionsAnimated:YES];
    } else {
        [self hideCallOptionsAnimated:NO];
    }
    
    // determine call options view state
    JCCallOptionViewState state = JCCallOptionViewSingleCallState;
    if (_showingConferenceCall) {
        state = JCCallOptionViewConferenceCallState;
    }
    else if ([JCPhoneManager sharedManager].calls.count > 1) {
        state = JCCallOptionViewMultipleCallsState;
    }
    
    [self.callOptionsView setState:state];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCTransferConfirmationViewController class]]) {
        JCTransferConfirmationViewController *transferConfirmationViewController = (JCTransferConfirmationViewController *)viewController;
        transferConfirmationViewController.transferInfo = _warmTransferInfo;
    }
    else if ([viewController isKindOfClass:[JCCallCardCollectionViewController class]]) {
        _callCardCollectionViewController = (JCCallCardCollectionViewController *)viewController;
    }
}

-(void)reload
{
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [_callCardCollectionViewController.collectionView reloadData];
}

-(void)startConferenceCall
{
    [UIView transitionWithView:_callCardCollectionViewController.view
                      duration:0.3
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        [_callCardCollectionViewController.collectionView reloadData];
                        [self.callOptionsView setState:JCCallOptionViewConferenceCallState animated:YES];
                    } completion:^(BOOL finished) {
                        _showingConferenceCall = TRUE;
                    }];
}

-(void)stopConferenceCall
{
    [UIView transitionWithView:_callCardCollectionViewController.view
                      duration:0.3
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        [_callCardCollectionViewController.collectionView reloadData];
                        [self.callOptionsView setState:JCCallOptionViewMultipleCallsState animated:YES];
                    } completion:^(BOOL finished) {
                        _showingConferenceCall = FALSE;
                    }];
}

#pragma mark - IBActions -

-(IBAction)mute:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
        button.selected = !button.selected;
        [JCPhoneManager muteCall:button.selected];
    }
}

-(IBAction)keypad:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        if (!_presentedKeyboardViewController) {
            JCKeypadViewController *keyboardViewController = [self.storyboard instantiateViewControllerWithIdentifier:kJCCallerViewControllerKeyboardStoryboardIdentifier];
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
    //[JCPhoneManager setLoudSpeakerEnabled:(_phoneManager.outputType != JCPhoneManagerOutputSpeaker)];
}

-(IBAction)blindTransfer:(id)sender
{
    JCTransferViewController *transferViewController = [self.storyboard instantiateViewControllerWithIdentifier:kJCCallerViewControllerTransferStoryboardIdentifier];
    transferViewController.transferCallType = JCPhoneManagerBlindTransfer;
    transferViewController.delegate = self;
    [self presentTransferViewController:transferViewController];
}

-(IBAction)warmTransfer:(id)sender
{
    JCTransferViewController *transferViewController = [self.storyboard instantiateViewControllerWithIdentifier:kJCCallerViewControllerTransferStoryboardIdentifier];
    transferViewController.transferCallType = JCPhoneManagerWarmTransfer;
    transferViewController.delegate = self;
    [self presentTransferViewController:transferViewController];
}

-(IBAction)addCall:(id)sender
{
    JCTransferViewController *transferViewController = [self.storyboard instantiateViewControllerWithIdentifier:kJCCallerViewControllerTransferStoryboardIdentifier];
    transferViewController.transferCallType = JCPhoneManagerSingleDial;
    transferViewController.delegate = self;
    [self presentTransferViewController:transferViewController];
}

-(IBAction)swapCall:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.enabled = false;
        [JCPhoneManager swapCalls:^(BOOL success, NSError *error) {
            button.enabled = true;
        }];
    }
}

-(IBAction)mergeCall:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]){
        UIButton *button = (UIButton *)sender;
        button.enabled = false;
        if ([JCPhoneManager sharedManager].isConferenceCall) {
            [JCPhoneManager splitCalls:^(BOOL success, NSError *error) {
                if (success) {
                    self.mergeLabel.text = NSLocalizedString(@"Merge Calls", nil);
                    button.selected = TRUE;
                }
                else {
                    [self showHudWithTitle:@"Oh-oh" detail:@"Failed to End Conference"];
                }
                button.enabled = TRUE;
            }];
        } else {
            [JCPhoneManager mergeCalls:^(BOOL success, NSError *error) {
				if (success) {
					self.mergeLabel.text = NSLocalizedString(@"Split Calls", nil);
                    button.selected = FALSE;
				}
				else {
					[self showHudWithTitle:@"Oh-oh" detail:@"Failed to Create Conference"];
				}
                button.enabled = TRUE;
			}];
        }
    }
}

-(IBAction)finishTransfer:(id)sender
{
    [JCPhoneManager finishWarmTransfer:^(BOOL success, NSError *error) {
        if (success) {
            [self showTransferSuccess];
        }
        else {
            [self showHudWithTitle:NSLocalizedString(@"Oh-oh", nil)
                            detail:NSLocalizedString(@"Failed to finish transfer", nil)];
            [self.callOptionsView setState:JCCallOptionViewMultipleCallsState animated:YES];
        }
    }];
}

#pragma mark - Private -

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
                         [self.view layoutIfNeeded];
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
    [self performSelector:@selector(dismissModalViewController) withObject:nil afterDelay:3];
}

-(void)dismissModalViewController
{
    [self dismissViewControllerAnimated:NO completion:^{
        [self closeCallerViewController];
    }];
}

-(void)closeCallerViewController
{
    if (_delegate && [_delegate respondsToSelector:@selector(shouldDismissCallerViewController:)])
        [_delegate shouldDismissCallerViewController:self];
    else
        [self dismissViewControllerAnimated:YES completion:NULL];
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

-(void)presentTransferViewController:(UIViewController *)viewController
{
    if (_presentedKeyboardViewController){
        [self dismissKeyboardViewController:YES];
    }
    
    if (viewController == _presentedTransferViewController)
        return;
    
    _presentedTransferViewController = viewController;
    [self addChildViewController:viewController];
    CGRect bounds = self.view.bounds;
    CGRect frame = self.view.frame;
    frame.origin.y = frame.origin.y + frame.size.height;
    viewController.view.frame = frame;
    [self.view addSubview:viewController.view];
    [UIView animateWithDuration:_transferAnimationDuration
                     animations:^{
                         viewController.view.frame = bounds;
                     }
                     completion:NULL];
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

#pragma mark - Notification Handlers -

//-(void)addedCallSelector:(NSNotification *)notification
//{
//    NSDictionary *userInfo = notification.userInfo;
//    JCCallCard *callCard = [userInfo objectForKey:kJCPhoneManagerNewCall];
//    if (callCard) {
//        [callCard.lineSession addObserver:self forKeyPath:kJCLineSessionStateKey options:0 context:NULL];
//    }
//    [self.view setNeedsLayout];
//    [self.view layoutIfNeeded];
//}
//
///**
// * Notification recieved when an incoming call has been answered. If we are currently not showing the call options view,
// * We animate in the showing of the call options view. This would occur if we were recieving an incomming call, with no 
// * other active calls. If we answer a call while already on the call, we should shown the multiple call state of the 
// * call options, allowing us to merge or swap calls.
// */
//-(void)answeredCall:(NSNotification *)notification
//{
//    if (!_showingCallOptions)
//        self.callOptionsHidden = false;
//    
//    [self.view setNeedsLayout];
//    [self.view layoutIfNeeded];
//    
//}
//
///**
// * Notification when a call has been been removed and we should possibly respond to close the view. We check the number
// * of calls. If we have no calls, we close the view. If we have a single call, we show the single call state.
// */
//-(void)removedCall:(NSNotification *)notification
//{
//    [self.view setNeedsLayout];
//    [self.view layoutIfNeeded];
//    
//    NSDictionary *userInfo = notification.userInfo;
//    JCCallCard *callCard = [userInfo objectForKey:kJCPhoneManagerRemovedCall];
//    if (callCard) {
//        [callCard.lineSession removeObserver:self forKeyPath:kJCLineSessionStateKey context:NULL];
//    }
//}

#pragma mark - Delegate Handlers -

#pragma mark JCKeyboardViewController

-(void)keypadViewController:(JCKeypadViewController *)controller didTypeNumber:(NSInteger)number
{
    [JCPhoneManager numberPadPressedWithInteger:number];
}

#pragma mark JCTransferViewController

-(void)transferViewController:(JCTransferViewController *)controller shouldDialNumber:(NSString *)dialString
{
    __unsafe_unretained JCCallerViewController *weakSelf = self;
    [JCPhoneManager dialNumber:dialString
                         type:controller.transferCallType
                   completion:^(BOOL success, NSError *error, NSDictionary *callInfo) {
                       if (success)
                       {
                           switch (controller.transferCallType) {
                               case JCPhoneManagerBlindTransfer:
                               {
                                   [weakSelf dismissTransferViewControllerAnimated:NO];
                                   [weakSelf closeCallerViewController];
                                   break;
                               }
                               case JCPhoneManagerWarmTransfer:
                               {
                                   [weakSelf dismissTransferViewControllerAnimated:YES];
                                   [weakSelf.callOptionsView setState:JCCallOptionViewFinishTransferState animated:YES];
                                   weakSelf.warmTransferInfo = callInfo;
                                   break;
                               }
                               default:
                               {
                                   [weakSelf dismissTransferViewControllerAnimated:YES];
                                   [weakSelf.callOptionsView setState:JCCallOptionViewMultipleCallsState animated:YES];
                                   break;
                               }
                           }
                       }
                   }];
}

-(void)shouldCancelTransferViewController:(JCTransferViewController *)controller
{
    [self dismissTransferViewControllerAnimated:YES];
}


@end
