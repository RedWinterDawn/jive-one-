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

#import "JCCallCardManager.h"

#define TRANSFER_ANIMATION_DURATION 0.3

NSString *const kJCCallerViewControllerTransferStoryboardIdentifier = @"warmTransferModal";

@interface JCCallerViewController () <JCTransferViewControllerDelegate>
{
    UIViewController *_presentedTransferViewController;
}

@end

@implementation JCCallerViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *dialString = self.dialString;
    if (dialString)
        [[JCCallCardManager sharedManager] dialNumber:dialString];
}

#pragma mark - IBActions -

-(IBAction)speaker:(id)sender
{
    
}

-(IBAction)keypad:(id)sender
{
    
}

-(IBAction)mute:(id)sender
{
    
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

#pragma mark - Private - 

-(void)closeCallerViewController
{
    if (_delegate && [_delegate respondsToSelector:@selector(shouldDismissCallerViewController:)])
        [_delegate shouldDismissCallerViewController:self];
}

-(void)presentTransferViewController:(UIViewController *)viewController
{
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
                     }];
}

#pragma mark - Delegate Handlers -

#pragma mark JCTransferViewController

-(void)transferViewController:(JCTransferViewController *)controller shouldDialNumber:(NSString *)dialString
{
    [self dismissTransferViewControllerAnimated:NO];
    NSLog(@"%@, %i", dialString, controller.transferType);
    
    /*if (controller.transferType == JCTransferBlind)
    {
        
    }
    else if(controller.transferType == JCTransferHold)
    {
        
    }
    else if(controller.transferType == JCTransferWarm)
    {
        
    }*/
    
    [[JCCallCardManager sharedManager] dialNumber:dialString];
}

-(void)shouldCancelTransferViewController:(JCTransferViewController *)controller
{
    [self dismissTransferViewControllerAnimated:YES];
}


@end
