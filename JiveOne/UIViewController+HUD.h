//
//  UIViewController+HUD.h
//  JiveOne
//
//  Created by Robert Barclay on 11/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIViewController (HUD)

- (void)showError:(NSError *)error;

- (void)showStatus:(NSString *)string;
- (void)hideStatus;

- (void)showSimpleAlert:(NSString *)title error:(NSError *)error;
- (void)showSimpleAlert:(NSString *)title message:(NSString *)message;
- (void)showSimpleAlert:(NSString *)title message:(NSString *)message code:(NSInteger)code;

@end


@interface UIApplication (Custom)

+(void)showError:(NSError *)error;

+(void)showStatus:(NSString *)status;
+(void)hideStatus;

+(void)showSimpleAlert:(NSString *)title error:(NSError *)error;
+(void)showSimpleAlert:(NSString *)title message:(NSString *)message;
+(void)showSimpleAlert:(NSString *)title message:(NSString *)message code:(NSInteger)code;

@end
