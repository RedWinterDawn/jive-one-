//
//  JCCallerViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallerViewController.h"
#import "JCTransferViewController.h"
#import "SipHandler.h"
#import "JCLineSession.h"
#import "Lines+Custom.h"

#define TRANSFER_ANIMATION_DURATION 0.3
#define kTAGStar		10
#define kTAGSharp		11

NSString *const kJCCallerViewControllerTransferStoryboardIdentifier = @"warmTransferModal";

@interface JCCallerViewController () <JCTransferViewControllerDelegate, JCCallCardViewDelegate>
{
    UIViewController *_presentedTransferViewController;
	BOOL isSpeakerSelected;
	BOOL isCallMuted;
}

@property (nonatomic) NSMutableArray *activeLines;

@end

@implementation JCCallerViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
//    JCCallCardView *callCardView = [JCCallCardView createCallCardWithIdentifier:@"1" delegate:self];
//    [self.callCardList addSubview:callCardView];
	[self refreshCardsSource];
}

- (void)refreshCardsSource
{
	NSArray *activeLines = [[SipHandler sharedHandler] findAllActiveLines];
	for (JCLineSession *line in activeLines) {
		JCCallCardView *callCardView = [JCCallCardView createCallCardWithIdentifier:[NSString stringWithFormat:@"%ld", line.mSessionId] delegate:self];
		[callCardView setLineSession:line];
		[self.callCardList addSubview:callCardView];
	}
	
	if (activeLines.count == 0) {
		//close caller viewcontroller?
		[self dismissTransferViewControllerAnimated:YES];
	}
}

#pragma mark - IBActions -

-(IBAction)speaker:(id)sender
{
	isSpeakerSelected = !isSpeakerSelected;
	[[SipHandler sharedHandler] setLoudspeakerStatus:isSpeakerSelected];
}

-(IBAction)keypad:(id)sender
{
}

-(IBAction)mute:(id)sender
{
	isCallMuted = !isCallMuted;
	[[SipHandler sharedHandler] muteCall:isCallMuted];
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

- (NSString *)getContactNameByNumber:(NSString *)number
{
	Lines *contact = [Lines MR_findFirstByAttribute:@"externsionNumber" withValue:number];
	if (contact) {
		return contact.displayName;
	}
	
	return nil;
}

#pragma mark - Delegate Handlers -

-(void)callCardViewShouldHangUp:(JCCallCardView *)view
{
    // TODO: Do whatever to close the call for whatever call has the given identifier
    //NSString *callIdentifier = view.identifer;
    
    // Update UI
    [self.callCardList removeCallCard:view];
	[self refreshCardsSource];
    // If no other calls are active, close caller.
    //if (self.callCardList.count == 0)
        //[self closeCallerViewController];
}

-(void)callCardViewShouldHold:(JCCallCardView *)view
{
    // TODO: Do whatever to close the call for whatever call has the given identifier
    //NSString *callIdentifier = view.identifer;
}

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
    
	if (controller.transferType == JCTransferWarm || controller.transferType == JCTransferHold) {
		JCCallCardView *callCardView = [JCCallCardView createCallCardWithIdentifier:@"2" delegate:self];
		[self.callCardList addSubview:callCardView];
	}	
}

-(void)shouldCancelTransferViewController:(JCTransferViewController *)controller
{
    [self dismissTransferViewControllerAnimated:YES];
}


@end
