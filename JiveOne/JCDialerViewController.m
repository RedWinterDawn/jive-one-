//
//  JCDialerViewController.m
//  JiveOne
//
//  Created by P Leonard on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDialerViewController.h"
#import "JCCallerViewController.h"
#import "Call.h"
#import "SipHandler.h"
#import "Lines+Custom.h"
#import "JCAuthenticationManager.h"

NSString *const kJCDialerViewControllerCallerStoryboardIdentifier = @"InitiateCall";

@interface JCDialerViewController () <JCCallerViewControllerDelegate>
{
    SipHandler *_sipHandler;
}

@end


@implementation JCDialerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.backspaceBtn.alpha = 0;
    
    _sipHandler = [SipHandler sharedHandler];
    [_sipHandler addObserver:self forKeyPath:kSipHandlerRegisteredSelectorKey options:NSKeyValueObservingOptionNew context:NULL];
    [self updateResgistrationStatus];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!_sipHandler.isRegistered) {
        [_sipHandler connect:^(bool success, NSError *error) {
            if (error) {
                NSLog(@"%@", [error description]);
            }
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCCallerViewController class]])
    {
        JCCallerViewController *callerViewController = (JCCallerViewController *)viewController;
        callerViewController.dialString = self.dialStringLabel.dialString;
        callerViewController.delegate = self;
        self.dialStringLabel.dialString = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kSipHandlerRegisteredSelectorKey])
        [self updateResgistrationStatus];
}

- (void)dealloc
{
    [_sipHandler removeObserver:self forKeyPath:kSipHandlerRegisteredSelectorKey];
}

#pragma mark - IBActions -

-(IBAction)numPadPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
        [self.dialStringLabel append:[self characterFromNumPadTag:(int)button.tag]];
		
		NSInteger tag = [[self characterFromNumPadTag:(int)button.tag] integerValue];
		char dtmf = tag;
		switch (tag) {
			case kTAGStar:
			{
				dtmf = 10;
				break;
			}
			case kTAGSharp:
			{
				dtmf = 11;
				break;
			}
		}
		
		[[SipHandler sharedHandler] pressNumpadButton:dtmf];
    }
}

-(IBAction)initiateCall:(id)sender
{
    NSString *string = self.dialStringLabel.text;
    
    // You cannot dial an empty string or null string.
    if (!string || [string isEqualToString:@""]) {
        return;
    }
    
    // Check if we are registered. If we are registered, perform segue to initiate the call.
    if (_sipHandler.isRegistered)
    {
        [self performSegueWithIdentifier:kJCDialerViewControllerCallerStoryboardIdentifier sender:self];
        return;
    }
        
    // If we are not registered, try to register before we perform the seque. if we successfully register, perform
    // segue initiate the call.
    [_sipHandler connect:^(bool success, NSError *error) {
        if (success) {
            [self performSegueWithIdentifier:kJCDialerViewControllerCallerStoryboardIdentifier sender:self];
        }
        
        if (error) {
            NSLog(@"%@", [error description]);
        }
    }];
}

-(IBAction)backspace:(id)sender
{
    [self.dialStringLabel backspace];
}

-(IBAction)clear:(id)sender
{
    [self.dialStringLabel clear];
}



#pragma mark - Private -

-(void)updateResgistrationStatus
{
    NSString *prompt = NSLocalizedString(@"Unregistered", nil);
    if (_sipHandler.isRegistered)
    {
        _callBtn.selected = false;
        LineConfiguration *lineConfiguration = [JCAuthenticationManager sharedInstance].lineConfiguration;
        prompt = lineConfiguration.display;
    }
    else
        _callBtn.selected = true;
    
    self.regestrationStatus.text = prompt;
}

-(NSString *)characterFromNumPadTag:(int)tag
{
    switch (tag) {
        case 10:
            return @"*";
        case 11:
            return @"#";
        default:
            return [NSString stringWithFormat:@"%i", tag];
    }
}

-(void)didUpdateDialString:(NSString *)dialString
{
    __unsafe_unretained JCDialerViewController *weakSelf = self;
    if (dialString.length == 0) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             weakSelf.backspaceBtn.alpha = 0;
                         }
                         completion:^(BOOL finished) {
     
                         }];
    } else {
        [UIView animateWithDuration:0.3
                         animations:^{
                             weakSelf.backspaceBtn.alpha = 1;
                         }
                         completion:^(BOOL finished) {
     
                         }];
    }
}

#pragma mark - Delegate Handlers -

#pragma mark JCCallerViewController

-(void)shouldDismissCallerViewController:(JCCallerViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end


