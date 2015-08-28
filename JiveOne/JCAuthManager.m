//
//  JCAuthManager.m
//  JiveOne
//
//  Created by Robert Barclay on 8/28/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthManager.h"
#import "JCAuthClient.h"

NSString *const kJCAuthenticationManagerUserRequiresAuthenticationNotification  = @"userRequiresAuthentication";
NSString *const kJCAuthenticationManagerUserWillLogOutNotification              = @"userWillLogOut";
NSString *const kJCAuthenticationManagerUserLoggedOutNotification               = @"userLoggedOut";
NSString *const kJCAuthenticationManagerUserAuthenticatedNotification           = @"userAuthenticated";
NSString *const kJCAuthenticationManagerAuthenticationFailedNotification        = @"authenticationFailed";

static BOOL requestingAuthentication;
static NSMutableArray *authenticationCompletionRequests;

@interface JCAuthManager ()
{
    JCAuthClient *_client;
}

@end

@implementation JCAuthManager

-(instancetype)init
{
    JCAuthKeychain *keyChain = [JCAuthKeychain new];
    JCAuthSettings *settings = [JCAuthSettings new];
    return [self initWithKeychain:keyChain setting:settings];
}

-(instancetype)initWithKeychain:(JCAuthKeychain *)keychain setting:(JCAuthSettings *)settings
{
    self = [super init];
    if(self) {
        _keychain = keychain;
        _settings = settings;
    }
    return self;
}



/**
 * Checks to see if we have a authtoken in the keychain. If we do not have a valid auth token, we
 * purge the existing auth token.
 */
-(void)checkAuthenticationStatus:(JCAuthCompletionHandler)completion
{
    // Check to see if we are autheticiated. If we are not, notify that we are logged out.
    JCAuthToken *authToken = _keychain.authToken;
    if (!authToken) {
        [_keychain logout];
        [self postNotificationNamed:kJCAuthenticationManagerUserRequiresAuthenticationNotification];
        if (completion) {
            completion(NO, nil, [JCAuthManagerError errorWithCode:AUTH_MANAGER_REQUIRES_LOGIN]);
        }
    }
    
    if ([[NSDate date] timeIntervalSinceDate:authToken.expirationDate] > 0) {
        [[self class] requestAuthenticationForUsername:authToken.username completion:^(BOOL success, NSString *username, NSError *error) {
            if (completion) {
                completion(success, username, error? [JCAuthManagerError errorWithCode:AUTH_MANAGER_REQUIRES_VALIDATION underlyingError:error] : nil);
            }
        }];
    } else {
        if (completion) {
            completion(YES, authToken.username, nil);
        }
    }
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completed:(JCAuthCompletionHandler)completion
{
    // Destroy current authToken;
    [_keychain logout];
    
    // Login using the auth client.
    _client = [JCAuthClient new];
    [_client loginWithUsername:username password:password completion:^(BOOL success, JCAuthToken *authToken, NSError *error) {
        if (success)
        {
            __autoreleasing NSError *error;
            BOOL result = [_keychain setAuthToken:authToken error:&error];
            if (!result) {
                if (completion) {
                    completion(NO, authToken.username, [JCAuthManagerError errorWithCode:AUTH_MANAGER_CLIENT_ERROR underlyingError:error]);
                }
                return;
            } else {
                if(_settings.rememberMe)
                    _settings.rememberMeUser = authToken.username;
                
                if (completion) {
                    completion(YES, authToken.username, nil);
                }
                
                // Broadcast that we have succesfully authenticated the user.
                [self postNotificationNamed:kJCAuthenticationManagerUserAuthenticatedNotification];
            }
        }
        else {
            if (completion) {
                completion(NO, nil, [JCAuthManagerError errorWithCode:AUTH_MANAGER_CLIENT_ERROR underlyingError:error]);
            }
        }
        _client = nil;
    }];
}

/**
 * Logouts the keychain, destroying the store AuthToken
 */
- (void)logout
{
    // Notify the System that we are logging out.
    [self postNotificationNamed:kJCAuthenticationManagerUserWillLogOutNotification];
    
    // Destroy current authToken;
    [_keychain logout];
    
    // Clear local variables.
    if (!self.settings.rememberMe) {
        self.settings.rememberMeUser = nil;
    }
    
    // Notify the System that we are logging out.
    [self postNotificationNamed:kJCAuthenticationManagerUserLoggedOutNotification];
}

#pragma mark - Getters -

-(JCAuthToken *)authToken
{
    return _keychain.authToken;
}

- (BOOL)userAuthenticated
{
    return _keychain.isAuthenticated;
}

#pragma mark - Class methods

+ (void)requestAuthenticationForUsername:(NSString *)username completion:(JCAuthCompletionHandler)completion
{
    if (requestingAuthentication) {
        if (!authenticationCompletionRequests) {
            authenticationCompletionRequests = [NSMutableArray new];
        }
        if (![authenticationCompletionRequests containsObject:completion]) {
            [authenticationCompletionRequests addObject:completion];
        }
        return;
    }
    
    JCUserManager *manager = [self sharedManager];
    JCAuthCompletionHandler completionBlock = ^(BOOL success, NSString *username, NSError *error) {
        if (success) {
            [UIApplication hideStatus];
            requestingAuthentication = FALSE;
            if (authenticationCompletionRequests) {
                for (JCAuthCompletionHandler completionBlock in authenticationCompletionRequests) {
                    completionBlock(success, username, error);
                }
                authenticationCompletionRequests = nil;
            } else {
                if (completion) {
                    completion(success, username, error);
                }
            }
        }
        else
        {
            [JCAlertView alertWithTitle:nil message:NSLocalizedString(@"Invalid Password", nil)
                              dismissed:^(NSInteger buttonIndex) {
                                  if (buttonIndex == 0) {
                                      [manager logout];
                                  } else {
                                      [self requestAuthenticationForUsername:username completion:completion];
                                  }
                              }
                        showImmediately:YES
                      cancelButtonTitle:NSLocalizedString(@"Logout", nil)
                      otherButtonTitles:NSLocalizedString(@"Try Again", nil), nil];
        }
    };
    
    requestingAuthentication = TRUE;
    __block JCAlertView *alertView = [JCAlertView alertWithTitle:nil
                                                         message:NSLocalizedString(@"Please enter your password", @"Authentication Manager Error")
                                                       dismissed:^(NSInteger buttonIndex) {
                                                           if (buttonIndex == 0) {
                                                               requestingAuthentication = NO;
                                                               authenticationCompletionRequests = nil;
                                                               [UIApplication showStatus:NSLocalizedString(@"Logging Out...", nil)];
                                                               [manager logout];
                                                               [UIApplication hideStatus];
                                                           } else {
                                                               [UIApplication showStatus:NSLocalizedString(@"Validating...", nil)];
                                                               [manager loginWithUsername:username
                                                                                 password:[alertView textFieldAtIndex:0].text
                                                                                completed:completionBlock];
                                                           }
                                                       }
                                                 showImmediately:NO
                                               cancelButtonTitle:NSLocalizedString(@"Logout", nil)
                                               otherButtonTitles:NSLocalizedString(@"Enter", nil), nil];
    
    alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [alertView show];
}

@end
