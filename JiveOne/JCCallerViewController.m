//
//  JCCallerViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallerViewController.h"
#import "JCTransferViewController.h"
#import "JCCallCardCollectionViewController.h"
#import "JCKeyboardViewController.h"

#import "JCCallCardManager.h"

#define TRANSFER_ANIMATION_DURATION 0.3

NSString *const kJCCallerViewControllerTransferStoryboardIdentifier = @"warmTransferModal";
NSString *const kJCCallerViewControllerKeyboardStoryboardIdentifier = @"keyboardModal";

@interface JCCallerViewController () <JCTransferViewControllerDelegate, JCKeyboardViewControllerDelegate>
{
    UIViewController *_presentedTransferViewController;
    UIViewController *_presentedKeyboardViewController;
}

@end

@implementation JCCallerViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *dialString = self.dialString;
    if (dialString)
        [[JCCallCardManager sharedManager] dialNumber:dialString];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callHungUp:) name:kJCCallCardManagerRemoveCurrentCallNotification object:[JCCallCardManager sharedManager]];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)callHungUp:(NSNotification *)notification
{
    JCCallCardManager *callManager = (JCCallCardManager *)notification.object;
    NSUInteger count = callManager.totalCalls;
    if(count == 0)
        [self closeCallerViewController];
    else if (count == 1)
        [self.dialerOptions setState:JCDialerOptionSingle animated:YES];
    
    
    
}

#pragma mark - IBActions -

-(IBAction)speaker:(id)sender
{
    JCCallCard *incomingCallCard = [[JCCallCard alloc] init];
    incomingCallCard.dialNumber = @"555-123-4567";
    [[JCCallCardManager sharedManager] addIncomingCall:incomingCallCard];
}

-(IBAction)keypad:(id)sender
{
    if (!_presentedKeyboardViewController)
    {
        JCKeyboardViewController *keyboardViewController = [self.storyboard instantiateViewControllerWithIdentifier:kJCCallerViewControllerKeyboardStoryboardIdentifier];
        keyboardViewController.delegate = self;
        [self presentKeyboardViewController:keyboardViewController];
    }
    else
    {
        [self dismissKeyboardViewController:YES];
    }
    
    
}

-(IBAction)mute:(id)sender
{
    [self.dialerOptions setState:JCDialerOptionSingle animated:YES];
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
    
}

-(IBAction)mergeCall:(id)sender
{
    
}

-(IBAction)finishTransfer:(id)sender
{
    
}

#pragma mark - Private - 

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
    [UIView animateWithDuration:TRANSFER_ANIMATION_DURATION
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
    [UIView animateWithDuration:(animated ? TRANSFER_ANIMATION_DURATION : 0)
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
    [UIView animateWithDuration:TRANSFER_ANIMATION_DURATION
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
    [UIView animateWithDuration:(animated ? TRANSFER_ANIMATION_DURATION : 0)
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

-(void)transferViewController:(JCTransferViewController *)controller shouldDialNumber:(NSString *)dialString
{
    [self dismissTransferViewControllerAnimated:NO];
    NSLog(@"%@, %i", dialString, controller.transferType);
    
    JCCallCardDialTypes dialType;
    if (controller.transferType == JCTransferBlind)
        dialType = JCCallCardDialBlindTransfer;
    else if(controller.transferType == JCTransferWarm)
        dialType = JCCallCardDialWarmTransfer;
    else
        dialType = JCCallCardDialSingle;
    
    [[JCCallCardManager sharedManager] dialNumber:dialString type:dialType completion:^(bool success, NSDictionary *callInfo) {
        if (success)
        {
            if (dialType == JCCallCardDialWarmTransfer)
            {
                
            }
            else if(dialType == JCCallCardDialBlindTransfer)
            {
                
            }
            else
                [self.dialerOptions setState:JCDialerOptionMultiple animated:YES];
        }
    }];
}

-(void)shouldCancelTransferViewController:(JCTransferViewController *)controller
{
    [self dismissTransferViewControllerAnimated:YES];
}


@end
