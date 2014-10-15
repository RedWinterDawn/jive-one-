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
		NSString *dtmf = [self characterFromNumPadTag:(int)button.tag];
        [self.dialStringLabel append:dtmf];
		[_sipHandler pressNumpadButton:*(char*)[dtmf UTF8String]];
    }
}

-(IBAction)initiateCall:(id)sender
{
    if (!_sipHandler.isRegistered)
        [_sipHandler connect:^(bool success, NSError *error) {
            if (success)
                [self performSegueWithIdentifier:kJCDialerViewControllerCallerStoryboardIdentifier sender:self];
        }];
    else
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

-(void)updateResgistrationStatus
{
    NSString *prompt = @"Unregistered";
    if (_sipHandler.isRegistered)
    {
        _callBtn.selected = false;
        prompt = [NSString stringWithFormat:@"Ext: %@", @"5555"];
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


