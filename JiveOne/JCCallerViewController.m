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
#import "JCCallCardManager.h"   // Handles call cards, and managed calls
#import "SipHandler.h"          // Direct access to the lower level sip manager.

// Presented View Controllers
#import "JCTransferViewController.h"                // Shows dial pad to dial for blind, warm transfer and additional call.
#import "JCKeyboardViewController.h"                // Numberpad
#import "JCTransferConfirmationViewController.h"    // Transfer confimation view controller

#define CALL_OPTIONS_ANIMATION_DURATION 0.3
#define TRANSFER_ANIMATION_DURATION 0.3
#define KEYBOARD_ANIMATION_DURATION 0.3

NSString *const kJCCallerViewControllerTransferStoryboardIdentifier = @"warmTransferModal";
NSString *const kJCCallerViewControllerKeyboardStoryboardIdentifier = @"keyboardModal";

NSString *const kJCCallerViewControllerBlindTransferCompleteSegueIdentifier = @"blindTransferComplete";

@interface JCCallerViewController () <JCTransferViewControllerDelegate, JCKeyboardViewControllerDelegate>
{
    UIViewController *_presentedTransferViewController;
    UIViewController *_presentedKeyboardViewController;
    
    NSTimeInterval _defaultCallOptionViewConstraint;
}

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
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        JCCallCardManager *manager = [JCCallCardManager sharedManager];
        [center addObserver:self selector:@selector(callHungUp:) name:kJCCallCardManagerRemoveCurrentCallNotification object:manager];
        [center addObserver:self selector:@selector(addCurrentCall:) name:kJCCallCardManagerAddedCurrentCallNotification object:manager];
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];

    NSString *dialString = self.dialString;
    if (dialString)
        [[JCCallCardManager sharedManager] dialNumber:dialString];
	
    [self setCallOptionsHidden:_callOptionsHidden animated:NO];
}

-(void)awakeFromNib
{
    _defaultCallOptionViewConstraint = 202;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCTransferConfirmationViewController class]])
    {
        //JCTransferConfirmationViewController *transferConfirmationViewController = (JCTransferConfirmationViewController *)viewController;
        
        // TODO: Pass Data Array of call cards from transfer result to view controller to transfer completion.
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setters -

-(void)setCallOptionsHidden:(bool)callOptionsHidden
{
    _callOptionsHidden = callOptionsHidden;
    if (self.view.superview)
        [self setCallOptionsHidden:callOptionsHidden animated:YES];

}

-(void)setCallOptionsHidden:(bool)callOptionsHidden animated:(bool)animated
{
    if (callOptionsHidden)
        [self hideCallOptionsAnimated:animated];
    else
        [self showCallOptionsAnimated:animated];
}

#pragma mark - IBActions -

-(IBAction)mute:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
        button.selected = !button.selected;
        [[SipHandler sharedHandler] muteCall:button.selected];
    }
}

-(IBAction)keypad:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
        button.selected = ! button.selected;
        
        if (!_presentedKeyboardViewController)
        {
            JCKeyboardViewController *keyboardViewController = [self.storyboard instantiateViewControllerWithIdentifier:kJCCallerViewControllerKeyboardStoryboardIdentifier];
            keyboardViewController.delegate = self;
            [self presentKeyboardViewController:keyboardViewController];
        }
        else
            [self dismissKeyboardViewController:YES];
    }
}

-(IBAction)speaker:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
        button.selected = !button.selected;
        [[SipHandler sharedHandler] setLoudspeakerStatus:button.selected];
    }
}

-(IBAction)blindTransfer:(id)sender
{
    JCTransferViewController *transferViewController = [self.storyboard instantiateViewControllerWithIdentifier:kJCCallerViewControllerTransferStoryboardIdentifier];
    transferViewController.transferType = JCTransferBlind;
    transferViewController.delegate = self;
    [self presentTransferViewController:transferViewController];
}

-(IBAction)warmTransfer:(id)sender
{
    JCTransferViewController *transferViewController = [self.storyboard instantiateViewControllerWithIdentifier:kJCCallerViewControllerTransferStoryboardIdentifier];
    transferViewController.transferType = JCTransferWarm;
    transferViewController.delegate = self;
    [self presentTransferViewController:transferViewController];
}

-(IBAction)addCall:(id)sender
{
    JCTransferViewController *transferViewController = [self.storyboard instantiateViewControllerWithIdentifier:kJCCallerViewControllerTransferStoryboardIdentifier];
    transferViewController.transferType = JCTransferHold;
    transferViewController.delegate = self;
    [self presentTransferViewController:transferViewController];
}

-(IBAction)swapCall:(id)sender
{
    // TODO: Swap current calls.

}

-(IBAction)mergeCall:(id)sender
{
    // TODO: Merge two calls.
}

-(IBAction)finishTransfer:(id)sender
{
    [[JCCallCardManager sharedManager] finishWarmTransfer:^(bool success) {
        if (success)
            [self showTransferSuccess];
    }];
}

#pragma mark - Private - 

/**
 * Hides the call options card.
 */
-(void)hideCallOptionsAnimated:(bool)animated
{
    _callOptionsViewOriginYConstraint.constant = 10;
    [self.view setNeedsUpdateConstraints];
    __unsafe_unretained UIView *weakView = self.view;
    [UIView animateWithDuration:animated ? _callOptionTransitionAnimationDuration : 0
                     animations:^{
                         [weakView layoutIfNeeded];
                     }];
}

/**
 * Shows the call option card.
 */
-(void)showCallOptionsAnimated:(bool)animated
{
    _callOptionsViewOriginYConstraint.constant = _defaultCallOptionViewConstraint;
    [self.view setNeedsUpdateConstraints];
    __unsafe_unretained UIView *weakView = self.view;
    [UIView animateWithDuration:animated ? _callOptionTransitionAnimationDuration : 0
                     animations:^{
                         [weakView layoutIfNeeded];
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
}

-(void)presentKeyboardViewController:(UIViewController *)viewController
{
    if (viewController == _presentedKeyboardViewController)
        return;
    
    _presentedKeyboardViewController = viewController;
    [self addChildViewController:viewController];
    CGRect bounds = self.view.bounds;
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
                     }];
}

-(void)presentTransferViewController:(UIViewController *)viewController
{
    if (_presentedKeyboardViewController)
        [self dismissKeyboardViewController:YES];
    
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

/**
 * Notification recieved when a call has been added to the call card manager. Can happen after a call has been added via
 * the add call or warm call, or after an incominc call is answered.
 */
-(void)addCurrentCall:(NSNotification *)notification
{
    self.callOptionsHidden = false;
}

/**
 * Notification when a call has been been removed and we shoudl possibly respond to close the view.
 */
-(void)callHungUp:(NSNotification *)notification
{
    JCCallCardManager *callManager = (JCCallCardManager *)notification.object;
    NSUInteger count = callManager.totalCalls;
    if(count == 0)
        [self closeCallerViewController];
    else if (count == 1)
        [self.callOptionsView setState:JCCallOptionViewSingleCallState animated:YES];
}

#pragma mark - Delegate Handlers -

#pragma mark JCKeyboardViewController

-(void)keyboardViewController:(JCKeyboardViewController *)controller didTypeNumber:(NSString *)typedNumber
{
    [[SipHandler sharedHandler] pressNumpadButton:*(char*)[typedNumber UTF8String]];
}


#pragma mark JCTransferViewController

-(void)transferViewController:(JCTransferViewController *)controller shouldDialNumber:(NSString *)dialString
{
    [self dismissTransferViewControllerAnimated:NO];
	JCCallCardDialTypes dialType = JCCallCardDialSingle;
    
    if (controller.transferType == JCTransferBlind)
    {
		dialType = JCCallCardDialBlindTransfer;
    }
    else if(controller.transferType == JCTransferHold)
    {
		dialType = JCCallCardDialSingle;
    }
    else if(controller.transferType == JCTransferWarm)
    {
		dialType = JCCallCardDialWarmTransfer;
    }
    
    [[JCCallCardManager sharedManager] dialNumber:dialString type:dialType completion:^(bool success, NSDictionary *callInfo) {
        if (success)
        {
            if (dialType == JCCallCardDialWarmTransfer)
                [self.callOptionsView setState:JCCallOptionViewFinishTransferState animated:YES];
            else if(dialType == JCCallCardDialBlindTransfer)
                [self showTransferSuccess];
            else
                [self.callOptionsView setState:JCCallOptionViewMultipleCallsState animated:YES];
        }
    }];
}

-(void)shouldCancelTransferViewController:(JCTransferViewController *)controller
{
    [self dismissTransferViewControllerAnimated:YES];
}


@end
