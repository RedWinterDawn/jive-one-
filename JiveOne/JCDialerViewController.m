//
//  JCDialerViewController.m
//  JiveOne
//
//  Created by P Leonard on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDialerViewController.h"

#import "JCCallerViewController.h"

@interface JCDialerViewController ()

@end

@implementation JCDialerViewController

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCCallerViewController class]])
    {
        JCCallerViewController *callerViewController = (JCCallerViewController *)viewController;
        callerViewController.dialString = self.dialString.text;
        callerViewController.mute       = self.muteBtn.enabled;
        callerViewController.speaker    = self.speakerBtn.enabled;
    }
}

#pragma mark - IBActions -

-(IBAction)numPadPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
        NSString *character = [self characterFromNumPadTag:button.tag];
        self.dialString.text = [NSString stringWithFormat:@"%@%@", self.dialString.text, character];
    }
}

-(IBAction)speakerToggle:(id)sender
{
    self.speakerBtn.selected = !self.speakerBtn.selected;
}

-(IBAction)muteToggle:(id)sender
{
    self.muteBtn.selected = !self.muteBtn.selected;
}

-(IBAction)initiateCall:(id)sender
{
    [self performSegueWithIdentifier:@"InitiateCall" sender:self];
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

#pragma mark - Delegate handlers -

#pragma mark UITextFieldDelegate

/*
// return NO to disallow editing.
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

// became first responder
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    
}

// return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

// may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
}

// return NO to not change text
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

// called when clear button pressed. return NO to ignore (no notifications)
- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

// called when 'return' key pressed. return NO to ignore.
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return YES;
}
*/

@end
