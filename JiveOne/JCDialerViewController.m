//
//  JCDialerViewController.m
//  JiveOne
//
//  Created by P Leonard on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDialerViewController.h"
#import "JCCallerViewController.h"
#import "SipHandler.h"

NSString *const kJCDialerViewControllerCallerStoryboardIdentifier = @"InitiateCall";

@interface JCDialerViewController () <JCCallerViewControllerDelegate>

@end


@implementation JCDialerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[SipHandler sharedHandler];
    
    // Initialy hide the backspace button
    self.backspaceBtn.alpha = 0;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCCallerViewController class]])
    {
        JCCallerViewController *callerViewController = (JCCallerViewController *)viewController;
        callerViewController.dialString = self.dialStringLabel.dialString;
        callerViewController.delegate = self;
    }
}


#pragma mark - IBActions -

-(IBAction)numPadPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
		NSString *dtmf = [self characterFromNumPadTag:button.tag];
        [self.dialStringLabel append:dtmf];
		[[SipHandler sharedHandler] pressNumpadButton:*(char*)[dtmf UTF8String]];
    }
}

-(IBAction)initiateCall:(id)sender
{
//	[[SipHandler sharedHandler] makeCall:self.dialStringLabel.text videoCall:NO contactName:[self getContactNameByNumber:self.dialStringLabel.text]];
    [self performSegueWithIdentifier:kJCDialerViewControllerCallerStoryboardIdentifier sender:self];
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
    [self dismissViewControllerAnimated:NO completion:^{
        
    }];
}

@end


