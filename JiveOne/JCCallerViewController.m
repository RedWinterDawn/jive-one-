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
#import "SipHandler.h"
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

	[[JCCallCardManager sharedManager] refreshCallDatasource];
//    NSString *dialString = self.dialString;
//    if (dialString)
//        [[JCCallCardManager sharedManager] dialNumber:dialString];
	
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callHungUp:) name:kJCCallCardManagerRemoveCurrentCallNotification object:[JCCallCardManager sharedManager]];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)callHungUp:(NSNotification *)notification
{
    JCCallCardManager *callManager = (JCCallCardManager *)notification.object;
    if(callManager.totalCalls == 0)
        [self closeCallerViewController];
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
    [self.dialerOptions setState:JCDialerOptionMultiple animated:YES];
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

- (NSString *)getContactNameByNumber:(NSString *)number
{
	Lines *contact = [Lines MR_findFirstByAttribute:@"externsionNumber" withValue:number];
	if (contact) {
		return contact.displayName;
	}
	
	return nil;
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
    NSLog(@"%@, %lu", dialString, controller.transferType);
    
    if (controller.transferType == JCTransferBlind)
    {
		[[SipHandler sharedHandler] referCall:dialString];
    }
    else if(controller.transferType == JCTransferHold)
    {
        [[SipHandler sharedHandler] makeCall:dialString videoCall:NO contactName:[self getContactNameByNumber:dialString]];
    }
    else if(controller.transferType == JCTransferWarm)
    {
        [[SipHandler sharedHandler] referCall:dialString];
    }
    
//    [[JCCallCardManager sharedManager] dialNumber:dialString];
	[[JCCallCardManager sharedManager] refreshCallDatasource];
}

-(void)shouldCancelTransferViewController:(JCTransferViewController *)controller
{
    [self dismissTransferViewControllerAnimated:YES];
}


@end
