//
//  JCAuthenticationManager.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCUserManager.h"
#import <objc/runtime.h>

#import "Line.h"
#import "DID.h"
#import "User+Custom.h"
#import "PBX+V5Client.h"

#import "UIDevice+Additions.h"
#import "JCProgressHUD.h"
#import "JCAlertView.h"

// Notifications
NSString *const kJCAuthenticationManagerUserLoadedMinimumDataNotification       = @"userLoadedMinimumData";
NSString *const kJCAuthenticationManagerLineChangedNotification                 = @"lineChanged";

// KVO and NSUserDefaults Keys
NSString *const kJCAuthenticationManagerRememberMeAttributeKey              = @"rememberMe";
NSString *const kJCAuthenticationManagerJiveUserIdKey                       = @"username";
NSString *const kJCAuthneticationManagerDeviceTokenKey                      = @"deviceToken";

@interface JCUserManager () <UIWebViewDelegate>
{
    Line *_line;
}

@end

@implementation JCUserManager

+ (void)requestAuthentication:(CompletionHandler)completion
{
    NSString *username = [UIApplication sharedApplication].userManager.user.jiveUserId;
    [self requestAuthenticationForUsername:username completion:^(BOOL success, NSString *username, NSError *error) {
        if (completion) {
            completion(success, error);
        }
    }];
}
/**
 * Override to check if the user has loaded its minimum data. If the minumum data is not loaded, forces a logout
 *
 */
-(void)checkAuthenticationStatus:(JCAuthCompletionHandler)completion
{
    [super checkAuthenticationStatus:^(BOOL success, NSString *username, NSError *error) {
        if (success) {
            _user = [User MR_findFirstByAttribute:NSStringFromSelector(@selector(jiveUserId)) withValue:username];
            if (_user && _user.pbxs.count > 0) {
                Line *line = self.line;
                if (line) {
                    [self postNotificationNamed:kJCAuthenticationManagerUserLoadedMinimumDataNotification];
                    if (completion) {
                        completion(YES, username, nil);
                    }
                } else {
                    [JCAlertView alertWithTitle:NSLocalizedString(@"Warning", @"Authentication Manager Error")
                                        message:NSLocalizedString(@"Unable to select line. Please Login again.", @"Authentication Manager Error")];
                    [self logout];
                    if (completion) {
                        completion(NO, username, nil);
                    }
                }
            }
            else {
                [self logout]; // Nuke it, we need to relogin.
                if (completion) {
                    completion(NO, username, nil);
                }
            }
        }
        else {
            [self logout]; // Nuke it, we need to relogin.
            if (completion) {
                completion(success, username, error);
            }
        }
    }];
    
    
    // Check to see if we are autheticiated. If we are not, notify that we are logged out.
    if (!_keychain.isAuthenticated) {
        [_keychain logout];
        [self postNotificationNamed:kJCAuthenticationManagerUserRequiresAuthenticationNotification];
        return;
    }

    // Check to see if we have data using the authentication store to retrive the user id.
    JCAuthToken *authInfo = _keychain.authToken;
    NSString *jiveUserId = authInfo.username;
    
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completed:(JCAuthCompletionHandler)completion
{
    // Clear local variables.
    _user = nil;
    _line = nil;
    
    [super loginWithUsername:username password:password completed:^(BOOL success, NSString *jiveUserId, NSError *error) {
        if (success) {
            NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
            _user = [User userForJiveUserId:jiveUserId context:context];
            [PBX downloadPbxInfoForUser:_user
                              completed:^(BOOL success, NSError *error) {
                                  if (success) {
                                      [self postNotificationNamed:kJCAuthenticationManagerUserLoadedMinimumDataNotification];
                                      if (completion) {
                                          completion(YES, jiveUserId, nil);
                                      }
                                  } else {
                                      [_keychain logout];
                                      [self postNotificationNamed:kJCAuthenticationManagerAuthenticationFailedNotification];
                                      if (completion) {
                                          completion(NO, jiveUserId, [JCAuthManagerError errorWithCode:AUTH_MANAGER_PBX_INFO_ERROR underlyingError:error]);
                                      }
                                  }
                              }];
        } else {
            if (completion) {
                completion(success, jiveUserId, error);
            }
        }
    }];
}

- (void)logout
{
    [super logout];
    
    _user = nil;
    _line = nil;
}

#pragma mark - Setters -

-(void)setLine:(Line *)line
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(line))];
    _line = line;
    [self didChangeValueForKey:NSStringFromSelector(@selector(line))];
    [self postNotificationNamed:kJCAuthenticationManagerLineChangedNotification];
}

#pragma mark - Getters -

- (BOOL)userLoadedMinimumData
{
    return (_user && _user.pbxs);
}

-(Line *)line
{
    if (_line) {
        return _line;
    }
    
    // If we do not have a user loaded, we cannot select the line.
    if (!_user) {
        return nil;
    }
    
    // If we do not yet have a line, look for a line for our user that is marked as active.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx.user = %@ and active = %@", _user, @YES];
    _line = [Line MR_findFirstWithPredicate:predicate];
    if (_line) {
        return _line;
    }
    
    predicate = [NSPredicate predicateWithFormat:@"pbx.user = %@", _user];
    _line = [Line MR_findFirstWithPredicate:predicate sortedBy:@"number" ascending:YES];
    return _line;
}

-(PBX *)pbx
{
    return self.line.pbx;
}

@end

@implementation UIViewController (JCUserManager)

- (void)setUserManager:(JCUserManager *)userManager {
    objc_setAssociatedObject(self, @selector(userManager), userManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(JCUserManager *)userManager
{
    JCUserManager *userManager = objc_getAssociatedObject(self, @selector(userManager));
    if (!userManager)
    {
        userManager = [UIApplication sharedApplication].userManager;
        objc_setAssociatedObject(self, @selector(userManager), userManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return userManager;
}

@end

@implementation UIApplication (JCUserManager)

- (void)setUserManager:(JCUserManager *)userManager {
    objc_setAssociatedObject(self, @selector(userManager), userManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(JCUserManager *)userManager
{
    JCUserManager *userManager = objc_getAssociatedObject(self, @selector(userManager));
    if (!userManager)
    {
        userManager = [JCUserManager sharedManager];
        objc_setAssociatedObject(self, @selector(userManager), userManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return userManager;
}

@end
