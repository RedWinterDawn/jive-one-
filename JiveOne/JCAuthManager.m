//
//  JCAuthenticationManager.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthManager.h"
#import "JCAuthKeychain.h"
#import <objc/runtime.h>

#import "Line.h"
#import "DID.h"
#import "User+Custom.h"
#import "PBX+V5Client.h"
#import "JCAuthClient.h"
#import "UIDevice+Additions.h"

#import "JCProgressHUD.h"
#import "JCAlertView.h"

// Notifications
NSString *const kJCAuthenticationManagerUserRequiresAuthenticationNotification  = @"userRequiresAuthentication";
NSString *const kJCAuthenticationManagerUserWillLogOutNotification              = @"userWillLogOut";
NSString *const kJCAuthenticationManagerUserLoggedOutNotification               = @"userLoggedOut";
NSString *const kJCAuthenticationManagerUserAuthenticatedNotification           = @"userAuthenticated";
NSString *const kJCAuthenticationManagerUserLoadedMinimumDataNotification       = @"userLoadedMinimumData";
NSString *const kJCAuthenticationManagerAuthenticationFailedNotification        = @"authenticationFailed";
NSString *const kJCAuthenticationManagerLineChangedNotification                 = @"lineChanged";

// KVO and NSUserDefaults Keys
NSString *const kJCAuthenticationManagerRememberMeAttributeKey              = @"rememberMe";
NSString *const kJCAuthenticationManagerJiveUserIdKey                       = @"username";
NSString *const kJCAuthneticationManagerDeviceTokenKey                      = @"deviceToken";

static BOOL requestingAuthentication;
static NSMutableArray *authenticationCompletionRequests;

@interface JCAuthManager () <UIWebViewDelegate>
{
    JCAuthKeychain *_keychain;
    JCAuthClient *_client;
    Line *_line;
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

#pragma mark - Class methods

+ (void)requestAuthentication:(CompletionHandler)completion
{
    User *user = [UIApplication sharedApplication].authenticationManager.user;
    [self requestAuthenticationForUser:user completion:completion];
}

+ (void)requestAuthenticationForUser:(User *)user completion:(CompletionHandler)completion
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
    
    JCAuthManager *manager = [self sharedManager];
    CompletionHandler completionBlock = ^(BOOL success, NSError *error) {
        if (success) {
            [UIApplication hideStatus];
            requestingAuthentication = FALSE;
            if (authenticationCompletionRequests) {
                for (CompletionHandler completionBlock in authenticationCompletionRequests) {
                    completionBlock(success, error);
                }
                authenticationCompletionRequests = nil;
            } else {
                if (completion) {
                    completion(success, error);
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
                                      [self requestAuthenticationForUser:user completion:completion];
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
                                                      [manager loginWithUsername:user.jiveUserId
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

/**
 * Checks the authentication status of the user.
 *
 * Retrieves from the authentication store if the user has authenticated, and tries to load the user
 * object using the user stored in the authenctication store.
 *
 */
-(void)checkAuthenticationStatus
{
    // Check to see if we are autheticiated. If we are not, notify that we are logged out.
    if (!_keychain.isAuthenticated) {
        [_keychain logout];
        [self postNotificationNamed:kJCAuthenticationManagerUserRequiresAuthenticationNotification];
        return;
    }

    // Check to see if we have data using the authentication store to retrive the user id.
    JCAuthToken *authInfo = _keychain.authToken;
    NSString *jiveUserId = authInfo.username;
    _user = [User MR_findFirstByAttribute:NSStringFromSelector(@selector(jiveUserId)) withValue:jiveUserId];
    if (_user && _user.pbxs.count > 0) {
        Line *line = self.line;
        if (line) {
            // Check our expiration date.
            if ([[NSDate date] timeIntervalSinceDate:authInfo.expirationDate] > 0) {
                [[self class] requestAuthenticationForUser:_user completion:^(BOOL success, NSError *error) {
                    [self postNotificationNamed:kJCAuthenticationManagerUserLoadedMinimumDataNotification];
                }];
            } else {
                [self postNotificationNamed:kJCAuthenticationManagerUserLoadedMinimumDataNotification];
            }
        } else {
            [JCAlertView alertWithTitle:NSLocalizedString(@"Warning", @"Authentication Manager Error")
                                message:NSLocalizedString(@"Unable to select line. Please Login again.", @"Authentication Manager Error")];
            [self logout];
        }
    }
    else {
        [self logout]; // Nuke it, we need to relogin.
    }
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completed:(CompletionHandler)completion
{
    CompletionHandler authCompletion = ^(BOOL success, NSError *error) {
        
        // Load minimum user data
        NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
        _user = [User userForJiveUserId:_keychain.authToken.username context:context];
        [PBX downloadPbxInfoForUser:_user
                          completed:^(BOOL success, NSError *error) {
                              if (success) {
                                  [self postNotificationNamed:kJCAuthenticationManagerUserLoadedMinimumDataNotification];
                                  if (completion) {
                                      completion(YES, nil);
                                  }
                              } else {
                                  [_keychain logout];
                                  [self postNotificationNamed:kJCAuthenticationManagerAuthenticationFailedNotification];
                                  if (completion) {
                                      completion(NO, [JCAuthenticationManagerError errorWithCode:AUTH_MANAGER_PBX_INFO_ERROR underlyingError:error]);
                                  }
                              }
                          }];
        
    };
    
    // Destroy current authToken;
    [_keychain logout];
    
    // Clear local variables.
    _user = nil;
    _line = nil;
    
    // Login using the auth client.
    _client = [[JCAuthClient alloc] init];
    [_client loginWithUsername:username password:password completion:^(BOOL success, JCAuthToken *authInfo, NSError *error) {
        if (success)
        {
            __autoreleasing NSError *error;
            BOOL result = [_keychain setAuthToken:authInfo error:&error];
            if (!result) {
                if (authCompletion) {
                    authCompletion(NO, [JCAuthenticationManagerError errorWithCode:AUTH_MANAGER_CLIENT_ERROR underlyingError:error]);
                }
                return;
            } else {
                if(_settings.rememberMe)
                    _settings.rememberMeUser = authInfo.username;
                
                if (authCompletion) {
                    authCompletion(YES, nil);
                }
                
                // Broadcast that we have succesfully authenticated the user.
                [self postNotificationNamed:kJCAuthenticationManagerUserAuthenticatedNotification];
            }
        }
        else {
            if (authCompletion) {
                authCompletion(NO, [JCAuthenticationManagerError errorWithCode:AUTH_MANAGER_CLIENT_ERROR underlyingError:error]);
            }
        }
        _client = nil;
    }];
}

- (void)logout
{
    // Notify the System that we are logging out.
    [self postNotificationNamed:kJCAuthenticationManagerUserWillLogOutNotification];
    
    // Destroy current authToken;
    [_keychain logout];

    // Clear local variables.
    _user = nil;
    _line = nil;
    if (!self.settings.rememberMe) {
        self.settings.rememberMeUser = nil;
    }
    
    // Notify the System that we are logging out.
    [self postNotificationNamed:kJCAuthenticationManagerUserLoggedOutNotification];
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

-(JCAuthToken *)authToken
{
    return _keychain.authToken;
}

- (BOOL)userAuthenticated
{
    return _keychain.isAuthenticated;
}

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

-(DID *)did
{
    if (_did) {
        return _did;
    }
    
    PBX *pbx = self.pbx;
    if (!pbx) {
        return nil;
    }
    
    // If we do not yet have a line, look for a line for our user that is marked as active.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx = %@ and userDefault = %@", pbx, @YES];
    _did = [DID MR_findFirstWithPredicate:predicate];
    if (_did) {
        return _did;
    }
    
    predicate = [NSPredicate predicateWithFormat:@"pbx = %@", pbx];
    _did = [DID MR_findFirstWithPredicate:predicate sortedBy:@"number" ascending:YES];
    return _did;
}

@end

NSString *const kJCAuthManagerErrorDomain = @"AuthenticationManagerError";

@implementation JCAuthenticationManagerError

+(instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    return [self errorWithDomain:kJCAuthManagerErrorDomain code:code userInfo:userInfo];
}

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error
{
    return [self errorWithDomain:kJCAuthManagerErrorDomain code:code reason:reason underlyingError:error];
}

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason
{
    return [self errorWithDomain:kJCAuthManagerErrorDomain code:code reason:reason];
}

+(NSString *)failureReasonFromCode:(NSInteger)code
{
    switch (code) {
        case AUTH_MANAGER_CLIENT_ERROR:
            return @"We are unable to login at this time, Please Check Your Connection and try again.";
            
        case AUTH_MANAGER_PBX_INFO_ERROR:
            return @"We could not reach the server at this time to sync data. Please check your connection, and try again.";
            
        case AUTH_MANAGER_AUTH_TOKEN_ERROR:
            return @"There was an error logging in. Please Contact Support.";
            
        default:
            return @"Unknown Error Has Occured.";
    }
    return nil;
}

@end

@implementation UIViewController (AuthenticationManager)

- (void)setAuthenticationManager:(JCAuthManager *)authenticationManager {
    objc_setAssociatedObject(self, @selector(authenticationManager), authenticationManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(JCAuthManager *)authenticationManager
{
    JCAuthManager *authenticationManager = objc_getAssociatedObject(self, @selector(authenticationManager));
    if (!authenticationManager)
    {
        authenticationManager = [UIApplication sharedApplication].authenticationManager;
        objc_setAssociatedObject(self, @selector(authenticationManager), authenticationManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return authenticationManager;
}

@end

@implementation UIApplication (AutenticationManager)

- (void)setAuthenticationManager:(JCAuthManager *)authenticationManager {
    objc_setAssociatedObject(self, @selector(authenticationManager), authenticationManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(JCAuthManager *)authenticationManager
{
    JCAuthManager *authenticationManager = objc_getAssociatedObject(self, @selector(authenticationManager));
    if (!authenticationManager)
    {
        authenticationManager = [JCAuthManager sharedManager];
        objc_setAssociatedObject(self, @selector(authenticationManager), authenticationManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return authenticationManager;
}

@end
