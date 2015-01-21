//
//  JCDialerViewController.m
//  JiveOne
//
//  Created by P Leonard on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDialerViewController.h"
#import "JCPhoneManager.h"
#import "OutgoingCall.h"
#import "UIViewController+HUD.h"
#import "JCAppSettings.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "UIViewController+HUD.h"

NSString *const kJCDialerViewControllerCallerStoryboardIdentifier = @"InitiateCall";

@interface JCDialerViewController ()
{
    JCPhoneManager *_phoneManager;
    BOOL _initiatingCall;
}

@end

@implementation JCDialerViewController

/**
 * Override to get the Phone Manager and add observers to watch for connected status so we can display the registration 
 * state, we also set the views initial state for displaying state.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _phoneManager = [JCPhoneManager sharedManager];
    [_phoneManager addObserver:self forKeyPath:@"connected" options:NSKeyValueObservingOptionNew context:NULL];
    [_phoneManager addObserver:self forKeyPath:@"connecting" options:NSKeyValueObservingOptionNew context:NULL];
    [self updateRegistrationStatus];
    
    self.backspaceBtn.alpha = 0;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateRegistrationStatus];
}


-(void)awakeFromNib
{
    [super awakeFromNib];
    
#ifndef DEBUG
    self.navigationItem.rightBarButtonItem = nil;
#endif
}

/**
 * Override so that if the phone manager is not yet connected when the view appears, try to connect. If we are logged
 * out, or have network connectivity problems it will fail, otherwise we should succeed and register if we were not 
 * already registered.
 */
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_phoneManager.line && !_phoneManager.isConnected && !_phoneManager.isConnecting) {
        [JCPhoneManager connectToLine:_phoneManager.line];
    }
}

- (void)dealloc
{
    [_phoneManager removeObserver:self forKeyPath:@"connected"];
    [_phoneManager removeObserver:self forKeyPath:@"connecting"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"connected"] || [keyPath isEqualToString:@"connecting"]) {
        [self updateRegistrationStatus];
    }
}

#pragma mark - IBActions -

/**
 * Tell the phone manager that a keypad number was pressed. Uses the tag property of the sender to identify which key, 
 * and the phone manager converts int into the DTMF tone for the phone.
 */
-(IBAction)numPadPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
        [self.dialStringLabel append:[self characterFromNumPadTag:(int)button.tag]];
        [JCPhoneManager numberPadPressedWithInteger:button.tag];
    }
}

-(IBAction)initiateCall:(id)sender
{
    NSString *string = self.dialStringLabel.dialString;
    
    // If the string is empty, we populate the dial string with the most recent item in call history.
    if (!string || [string isEqualToString:@""]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"line = %@", _phoneManager.line];
        OutgoingCall *call = [OutgoingCall MR_findFirstWithPredicate:predicate sortedBy:@"date" ascending:false];
        self.dialStringLabel.dialString = call.number;
        return;
    }
    
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.enabled = FALSE;
        [JCPhoneManager dialNumber:string
                              type:JCPhoneManagerSingleDial
                        completion:^(BOOL success, NSError *error, NSDictionary *callInfo) {
                            if (success){
                                self.dialStringLabel.dialString = nil;
                            }
                            else{
                                [self showSimpleAlert:@"Warning" error:error];
                            }
                            button.enabled = TRUE;
                        }];
    }
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

-(void)updateRegistrationStatus
{
    NSString *prompt = NSLocalizedString(@"Unregistered", nil);
    if (_phoneManager.isConnected) {
        _callBtn.selected = false;
        prompt = _phoneManager.line.extension;
    }
    else if ([JCAppSettings sharedSettings].wifiOnly && [AFNetworkReachabilityManager sharedManager].isReachableViaWWAN){
        prompt = NSLocalizedString(@"Disabled", nil);
    }
    else if (_phoneManager.isConnecting) {
        prompt = NSLocalizedString(@"Connecting", nil);
    }
    else {
        _callBtn.selected = true;
    }
    
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

@end


