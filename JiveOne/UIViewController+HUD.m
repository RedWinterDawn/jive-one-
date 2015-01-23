//
//  UIViewController+HUD.m
//  JiveOne
//
//  Created by Robert Barclay on 11/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "UIViewController+HUD.h"
#import <SVProgressHUD/SVProgressHUD.h>

static NSInteger JCProgressHUDDuration;

@interface JCProgressHUD : SVProgressHUD

@end

@implementation JCProgressHUD

+ (instancetype)sharedView {
    static dispatch_once_t once;
    static JCProgressHUD *sharedView;
    dispatch_once(&once, ^ { sharedView = [[self alloc] initWithFrame:[[UIScreen mainScreen] bounds]]; });
    return sharedView;
}

+(void)setDuration:(NSTimeInterval)duration
{
    [self sharedView];
    JCProgressHUDDuration = duration;
}

- (NSTimeInterval)displayDurationForString:(NSString*)string
{
    return JCProgressHUDDuration;
}

@end

@implementation UIViewController (HUD)

- (void)configureHud
{
    [JCProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [JCProgressHUD setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.75]];
    [JCProgressHUD setForegroundColor:[UIColor whiteColor]];
    [JCProgressHUD setDuration:3];
}

- (void)showError:(NSError *)error
{
    [self configureHud];
    
    NSLog(@"%@", [error description]);
    NSString *message = [error localizedDescription];
    if (!message) {
        message = [error localizedFailureReason];
    }
    
    NSInteger underlyingErrorCode = [self underlyingErrorCodeForError:error];
    message = [NSString stringWithFormat:@"%@ (%li)", message, (long)underlyingErrorCode];
    [JCProgressHUD showErrorWithStatus:message];
}

- (void)showStatus:(NSString *)string
{
    [self configureHud];
    
    if (![JCProgressHUD isVisible]) {
        [JCProgressHUD showWithStatus:string];
    }
    else {
        [JCProgressHUD setStatus:string];
    }
}

- (void)hideStatus
{
    [JCProgressHUD dismiss];
}

-(void)showSimpleAlert:(NSString *)title error:(NSError *)error
{
    NSLog(@"%@", [error description]);
    NSString *message = [error localizedDescription];
    if (!message) {
        message = [error localizedFailureReason];
    }
    
    NSInteger underlyingErrorCode = [self underlyingErrorCodeForError:error];
    
    message = [NSString stringWithFormat:@"%@ (%li)", message, (long)underlyingErrorCode];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(title, nil)
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil, nil];
    [alert show];
}

-(void)showSimpleAlert:(NSString *)title message:(NSString *)message
{
    NSLog(@"%@: %@", title, message);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(title, nil)
                                                    message:NSLocalizedString(message, nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil, nil];
    [alert show];
}

-(void)showSimpleAlert:(NSString *)title message:(NSString *)message code:(NSInteger)code
{
    NSLog(@"%@: %@ (-%li)", title, message, (long)code);
    message = [NSString stringWithFormat:@"%@ (%li)", NSLocalizedString(message, nil), (long)code];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(title, nil)
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil, nil];
    [alert show];
}

-(NSInteger)underlyingErrorCodeForError:(NSError *)error
{
    NSError *underlyingError = [error.userInfo objectForKey:NSUnderlyingErrorKey];
    if (underlyingError) {
        return [self underlyingErrorCodeForError:underlyingError];
    }
    return error.code;
}

@end

@implementation UIApplication (Custom)

+(void)showError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication].keyWindow.rootViewController showError:error];
    });
}

+(void)showStatus:(NSString *)status
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication].keyWindow.rootViewController showStatus:status];
    });
}

+(void)hideStatus{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication].keyWindow.rootViewController hideStatus];
    });
}

+(void)showSimpleAlert:(NSString *)title error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [viewController showSimpleAlert:title error:error];
    });
}

+(void)showSimpleAlert:(NSString *)title message:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [viewController showSimpleAlert:title message:message];
    });
}

+(void)showSimpleAlert:(NSString *)title message:(NSString *)message code:(NSInteger)code
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [viewController showSimpleAlert:title message:message code:code];
    });
}

@end
