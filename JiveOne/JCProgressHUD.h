//
//  JCProgressHUD.h
//  JiveOne
//
//  Created by Robert Barclay on 2/17/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>

@interface JCProgressHUD : SVProgressHUD

+(void)setDuration:(NSTimeInterval)duration;

@end


@interface UIViewController (JCProgressHUD)

- (void)showError:(NSError *)error;

- (void)showInfo:(NSString *)string;
- (void)showInfo:(NSString *)string duration:(NSTimeInterval)duration;

- (void)showStatus:(NSString *)string;
- (void)hideStatus;

@end


@interface UIApplication (JCProgressHUD)

+(void)showError:(NSError *)error;

+(void)showInfo:(NSString *)string;
+(void)showInfo:(NSString *)string duration:(NSTimeInterval)duration;

+(void)showStatus:(NSString *)status;
+(void)hideStatus;

@end