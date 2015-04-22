//
//  JCProgressHUD.m
//  JiveOne
//
//  Created by Robert Barclay on 2/17/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCProgressHUD.h"

static NSInteger JCProgressHUDDuration;

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

@implementation UIViewController (JCProgressHUD)

- (void)configureHud
{
    [JCProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [JCProgressHUD setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.75]];
    [JCProgressHUD setForegroundColor:[UIColor whiteColor]];
    [JCProgressHUD setDuration:4];
}

- (void)showError:(NSError *)error
{
    [self configureHud];
    
    NSLog(@"%@", [error description]);
    NSString *message = [error localizedDescription];
    if (!message) {
        message = [error localizedFailureReason];
    }
    
    NSError *underlyingError = [self underlyingErrorForError:error];
    NSString *underlyingFailureReason = [underlyingError localizedFailureReason];
    if(underlyingFailureReason) {
        message = [NSString stringWithFormat:@"%@(%li: %@)", NSLocalizedString(message, nil), (long)underlyingError.code, underlyingFailureReason];
    }
    else {
        message = [NSString stringWithFormat:@"%@(%li)", NSLocalizedString(message, nil), (long)underlyingError.code];
    }
    [JCProgressHUD showErrorWithStatus:message];
}

- (void)showInfo:(NSString *)string
{
    [self configureHud];
    
    [JCProgressHUD showInfoWithStatus:string];
}

- (void)showInfo:(NSString *)string duration:(NSTimeInterval)timeInterval
{
    [self configureHud];
    [JCProgressHUD setDuration:timeInterval];
    [JCProgressHUD showInfoWithStatus:string];
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

-(NSInteger)underlyingErrorCodeForError:(NSError *)error
{
    NSError *underlyingError = [error.userInfo objectForKey:NSUnderlyingErrorKey];
    if (underlyingError) {
        return [self underlyingErrorCodeForError:underlyingError];
    }
    return error.code;
}

-(NSError *)underlyingErrorForError:(NSError *)error
{
    NSError *underlyingError = [error.userInfo objectForKey:NSUnderlyingErrorKey];
    if (underlyingError) {
        return [self underlyingErrorForError:underlyingError];
    }
    return error;
}

@end

@implementation UIApplication (JCProgressHUD)

+(void)showError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication].keyWindow.rootViewController showError:error];
    });
}

+(void)showInfo:(NSString *)string
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication].keyWindow.rootViewController showInfo:string];
    });
}

+(void)showInfo:(NSString *)string duration:(NSTimeInterval)duration;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication].keyWindow.rootViewController showInfo:string duration:duration];
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

@end