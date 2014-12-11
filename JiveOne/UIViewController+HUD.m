//
//  UIViewController+HUD.m
//  JiveOne
//
//  Created by Robert Barclay on 11/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "UIViewController+HUD.h"
#import <MBProgressHUD/MBProgressHUD.h>

static MBProgressHUD *progressHud;

@implementation UIViewController (HUD)

- (void)showHudWithTitle:(NSString*)title detail:(NSString*)detail
{
    if (!progressHud) {
        progressHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        progressHud.mode = MBProgressHUDModeIndeterminate;
    }
    
    progressHud.labelText = NSLocalizedString(title, nil);
    progressHud.detailsLabelText = NSLocalizedString(detail, nil);
    [progressHud show:YES];
}

- (void)hideHud
{
    if (progressHud) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [progressHud removeFromSuperview];
        progressHud = nil;
    }
}

-(void)showSimpleAlert:(NSString *)title message:(NSString *)message
{
    NSLog(@"%@: %@", title, message);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(title, nil)
                                                    message:NSLocalizedString(message, nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil, nil];
    [alert show];
}

-(void)showSimpleAlert:(NSString *)title message:(NSString *)message code:(NSInteger)code
{
    NSLog(@"%@: %@ (-%li)", title, message, code);
    message = [NSString stringWithFormat:@"%@ (-%li)", NSLocalizedString(message, nil), (long)code];
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(title, nil)
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil, nil];
    [alert show];
}

@end
