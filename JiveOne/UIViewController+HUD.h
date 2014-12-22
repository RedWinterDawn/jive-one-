//
//  UIViewController+HUD.h
//  JiveOne
//
//  Created by Robert Barclay on 11/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface UIViewController (HUD)

- (void)showHudWithTitle:(NSString*)title detail:(NSString*)detail;
- (void)hideHud;

- (void)showSimpleAlert:(NSString *)title message:(NSString *)message;
- (void)showSimpleAlert:(NSString *)title message:(NSString *)message code:(NSInteger)code;

@end


@interface UIApplication (Custom)

+(void)showHudWithTitle:(NSString *)title message:(NSString *)message;
+(void)hideHud;

+(void)showSimpleAlert:(NSString *)title message:(NSString *)message;
+(void)showSimpleAlert:(NSString *)title message:(NSString *)message code:(NSInteger)code;

@end
