//
//  JCAuthenticationManager.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JCAuthManager.h"

@class User;
@class Line;
@class DID;
@class PBX;

extern NSString *const kJCAuthenticationManagerUserLoadedMinimumDataNotification;
extern NSString *const kJCAuthenticationManagerLineChangedNotification;

@interface JCUserManager : JCAuthManager

@property (nonatomic, strong) Line *line;       // Selectable
@property (nonatomic, strong) DID *did;         // Selectable
@property (nonatomic, readonly) User *user;
@property (nonatomic, readonly) PBX *pbx;

@property (nonatomic, readonly) BOOL userLoadedMinimumData;

+ (void)requestAuthentication:(CompletionHandler)completion;

@end

@interface UIViewController (JCUserManager)

@property (nonatomic, strong) JCUserManager *userManager;

@end

@interface UIApplication (JCUserManager)

@property (nonatomic, strong) JCUserManager *userManager;

@end
