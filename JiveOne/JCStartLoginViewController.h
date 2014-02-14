//
//  JCStartLoginViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCStartLoginViewController : UIViewController <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIWebView *authWebview;
- (IBAction)showWebviewForLogin:(id)sender;
- (void)dismissWebviewForLogin;
- (void)checkAuthTokenValidity;
- (void)refreshAuthenticationCredentials:(NSNotification*)notification;
- (void)tokenValidityPassed:(NSNotification*)notification;
@end
