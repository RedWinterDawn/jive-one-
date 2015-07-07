//
//  JCAuthenticationManager.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthenticationManager.h"
#import "JCAuthenticationKeychain.h"
#import <objc/runtime.h>

#import "Common.h"

#import "User.h"
#import "Line.h"
#import "DID.h"
#import "PBX.h"

#import "JCV5ApiClient.h"
#import "JCAuthenticationManagerError.h"
#import "User+Custom.h"
#import "PBX+V5Client.h"
#import "JCAuthClient.h"

#import "JCAlertView.h"

#import "UIDevice+Additions.h"

// Notifications
NSString *const kJCAuthenticationManagerUserLoggedOutNotification           = @"userLoggedOut";
NSString *const kJCAuthenticationManagerUserAuthenticatedNotification       = @"userAuthenticated";
NSString *const kJCAuthenticationManagerUserLoadedMinimumDataNotification   = @"userLoadedMinimumData";
NSString *const kJCAuthenticationManagerAuthenticationFailedNotification    = @"authenticationFailed";
NSString *const kJCAuthenticationManagerLineChangedNotification             = @"lineChanged";

// KVO and NSUserDefaults Keys
NSString *const kJCAuthenticationManagerRememberMeAttributeKey              = @"rememberMe";
NSString *const kJCAuthenticationManagerJiveUserIdKey                       = @"username";
NSString *const kJCAuthneticationManagerDeviceTokenKey                      = @"deviceToken";

NSString *const kJCAuthenticationManagerResponseAccessTokenKey              = @"access_token";
NSString *const kJCAuthenticationManagerResponseRefreshTokenKey             = @"refresh_token";
NSString *const kJCAuthenticationManagerResponseUsernameKey                 = @"username";
NSString *const kJCAuthenticationManagerResponseExpirationTimeIntervalKey   = @"expires_in";

@interface JCAuthenticationManager () <UIWebViewDelegate>
{
    JCAuthenticationKeychain *_authenticationKeychain;
    JCAuthClient *_authClient;
    Line *_line;
}

@property (nonatomic, readwrite) NSString *rememberMeUser;

@end

@implementation JCAuthenticationManager

-(instancetype)init
{
    JCAuthenticationKeychain *keyChain = [JCAuthenticationKeychain new];
    
    return [self initWithKeychain:keyChain];
}

-(instancetype)initWithKeychain:(JCAuthenticationKeychain *)keychain
{
    self = [super init];
    if(self) {
        _authenticationKeychain = keychain;
    }
    return self;
}

#pragma mark - Class methods

+ (void)requestAuthenticationForUser:(User *)user completion:(CompletionHandler)completion
{
    __block JCAlertView *alertView = [JCAlertView alertWithTitle:nil
                                                message:NSLocalizedString(@"Please enter your password", @"Authentication Manager Error")
                                              dismissed:^(NSInteger buttonIndex) {
                                                  if (buttonIndex == 0) {
                                                      [[[self class] sharedInstance] logout];
                                                  } else {
                                                      [[[self class] sharedInstance] loginWithUsername:user.jiveUserId
                                                                                              password:[alertView textFieldAtIndex:0].text
                                                                                             completed:^(BOOL success, NSError *error) {
                                                                                                 if (success) {
                                                                                                     if (completion) {
                                                                                                         completion(success, error);
                                                                                                     }
                                                                                                     else
                                                                                                     {
                                                                                                         [JCAlertView alertWithTitle:nil message:@"Invalid Password"
                                                                                                                           dismissed:^(NSInteger buttonIndex) {
                                                                                                                               if (buttonIndex == 0) {
                                                                                                                                   [[[self class] sharedInstance] logout];
                                                                                                                               } else {
                                                                                                                                   [self requestAuthenticationForUser:user completion:completion];
                                                                                                                               }
                                                                                                                           }
                                                                                                                     showImmediately:YES
                                                                                                                   cancelButtonTitle:NSLocalizedString(@"Logout", nil)
                                                                                                                   otherButtonTitles:NSLocalizedString(@"Try Again", nil), nil];
                                                                                                     }
                                                                                                 }
                                                                                             }];
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
    if (!_authenticationKeychain.isAuthenticated) {
        [self postNotificationNamed:kJCAuthenticationManagerUserLoggedOutNotification];
        return;
    }

    // Check to see if we have data using the authentication store to retrive the user id.
    NSString *jiveUserId = _authenticationKeychain.jiveUserId;
    _user = [User MR_findFirstByAttribute:NSStringFromSelector(@selector(jiveUserId)) withValue:jiveUserId];
    if (_user && _user.pbxs.count > 0) {
        Line *line = self.line;
        if (line) {
            // Check our expiration date.
            if ([[NSDate date] timeIntervalSinceDate:_authenticationKeychain.expirationDate] > 0) {
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

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completed:(CompletionBlock)completion
{
    // Destroy current authToken;
    [_authenticationKeychain logout];
    
    // Clear local variables.
    _user = nil;
    _line = nil;
    
    // Login using the auth client.
    _authClient = [[JCAuthClient alloc] init];
    [_authClient loginWithUsername:username password:password completion:^(BOOL success, NSDictionary *authToken, NSError *error) {
        if (success) {
            [self receivedAccessTokenData:authToken username:username completion:completion];
        }
        else {
            if (completion) {
                completion(NO, [JCAuthenticationManagerError errorWithCode:AUTH_MANAGER_CLIENT_ERROR underlyingError:error]);
            }
        }
        _authClient = nil;
    }];
}

- (void)logout
{
    // Destroy current authToken;
    [_authenticationKeychain logout];
    
    // Clear local variables.
    _user = nil;
    _line = nil;
    if (!self.rememberMe) {
        self.rememberMeUser = nil;
    }
    
    // Notify the System that we are logging out.
    [self postNotificationNamed:kJCAuthenticationManagerUserLoggedOutNotification];
}

#pragma mark - Setters -

-(void)setRememberMe:(BOOL)remember
{
    [self willChangeValueForKey:kJCAuthenticationManagerRememberMeAttributeKey];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:remember forKey:kJCAuthenticationManagerRememberMeAttributeKey];
    [defaults synchronize];
    [self didChangeValueForKey:kJCAuthenticationManagerRememberMeAttributeKey];
}

-(void)setRememberMeUser:(NSString *)rememberMeUser
{
    [self willChangeValueForKey:kJCAuthenticationManagerJiveUserIdKey];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:rememberMeUser forKey:kJCAuthenticationManagerJiveUserIdKey];
    [defaults synchronize];
    [self didChangeValueForKey:kJCAuthenticationManagerJiveUserIdKey];
}

-(void)setLine:(Line *)line
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(line))];
    _line = line;
    [self didChangeValueForKey:NSStringFromSelector(@selector(line))];
    [self postNotificationNamed:kJCAuthenticationManagerLineChangedNotification];
}

- (void)setDeviceToken:(NSString *)deviceToken
{
    NSString *newToken = [deviceToken description];
    newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:newToken forKey:kJCAuthneticationManagerDeviceTokenKey];
    [defaults synchronize];
}

#pragma mark - Getters -

- (BOOL)userAuthenticated
{
    return _authenticationKeychain.isAuthenticated;
}

- (BOOL)userLoadedMinimumData
{
    return (_user && _user.pbxs);
}

-(NSString *)authToken
{
    return _authenticationKeychain.accessToken;
}

-(NSString *)jiveUserId
{
    return _authenticationKeychain.jiveUserId;
}

-(NSString *)deviceToken
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:kJCAuthneticationManagerDeviceTokenKey];
}

- (BOOL)rememberMe
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kJCAuthenticationManagerRememberMeAttributeKey];
}

-(NSString *)rememberMeUser
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:kJCAuthenticationManagerJiveUserIdKey];
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

#pragma mark - Private -

-(void)receivedAccessTokenData:(NSDictionary *)tokenData username:(NSString *)username completion:(CompletionBlock)completion
{
    @try {
        if (!tokenData || tokenData.count < 1) {
            [NSException raise:NSInvalidArgumentException format:@"Token Data is NULL"];
        }
        
        if (tokenData[@"error"]) {
            [NSException raise:NSInvalidArgumentException format:@"%@", tokenData[@"error"]];
        }
        
        // Validate Jive User ID. Get the responce user ID, which should match the username we requested.
        NSString *jiveUserId = [tokenData valueForKey:kJCAuthenticationManagerResponseUsernameKey];
        if (!jiveUserId || jiveUserId.length == 0) {
            [NSException raise:NSInvalidArgumentException format:@"Username null or empty"];
        }
        
        if (![jiveUserId isEqualToString:username]) {
            [NSException raise:NSInvalidArgumentException format:@"Auth token user name does not match login user name"];
        }
        
        // Retrive the access token
        NSString *accessToken = [tokenData valueForKey:kJCAuthenticationManagerResponseAccessTokenKey];
        if (!accessToken || accessToken.length == 0) {
            [NSException raise:NSInvalidArgumentException format:@"Access Token null or empty"];
        }
        
        // Retrive the Expiration date.
        NSTimeInterval expirationTimeInterval = ([tokenData doubleValueForKey:kJCAuthenticationManagerResponseExpirationTimeIntervalKey]);
        if (expirationTimeInterval <= 0) {
            [NSException raise:NSInvalidArgumentException format:@"Expiration of token not found"];
        }
        
        // convert response from miliseconds to give us a date for expriation date that works with a
        // NSDate object, which functions in seconds.
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:expirationTimeInterval/1000];
        
        // Store values into keychain
        if (![_authenticationKeychain setAccessToken:accessToken username:jiveUserId expirationDate:expirationDate]) {
            [NSException raise:NSInvalidArgumentException format:@"Unable to save access token to keychain store."];
        }
        
        if(self.rememberMe)
            self.rememberMeUser = jiveUserId;
        
        // Broadcast that we have succesfully authenticated the user.
        [self postNotificationNamed:kJCAuthenticationManagerUserAuthenticatedNotification];
        
        NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
        _user = [User userForJiveUserId:_authenticationKeychain.jiveUserId context:context];
        [PBX downloadPbxInfoForUser:_user
                          completed:^(BOOL success, NSError *error) {
                              if (success) {
                                  [self postNotificationNamed:kJCAuthenticationManagerUserLoadedMinimumDataNotification];
                                  if (completion) {
                                      completion(YES, nil);
                                  }
                              } else {
                                  [_authenticationKeychain logout];
                                  [self postNotificationNamed:kJCAuthenticationManagerAuthenticationFailedNotification];
                                  if (completion) {
                                      completion(NO, [JCAuthenticationManagerError errorWithCode:AUTH_MANAGER_PBX_INFO_ERROR underlyingError:error]);
                                  }
                              }
                              
                          }];
    }
    @catch (NSException *exception) {
        if (completion) {
            completion(false, [JCAuthenticationManagerError errorWithCode:AUTH_MANAGER_AUTH_TOKEN_ERROR reason:exception.reason]);
        }
    }
}

@end

static JCAuthenticationManager *authenticationManager = nil;

@implementation JCAuthenticationManager (Singleton)

+ (instancetype)sharedInstance
{
    static JCAuthenticationManager *singleton = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        singleton = [[JCAuthenticationManager alloc] init];
    });
    return singleton;
}

@end

@implementation UIViewController (AuthenticationManager)

- (void)setAuthenticationManager:(JCAuthenticationManager *)authenticationManager {
    objc_setAssociatedObject(self, @selector(authenticationManager), authenticationManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(JCAuthenticationManager *)authenticationManager
{
    JCAuthenticationManager *authenticationManager = objc_getAssociatedObject(self, @selector(authenticationManager));
    if (!authenticationManager)
    {
        authenticationManager = [JCAuthenticationManager sharedInstance];
        objc_setAssociatedObject(self, @selector(authenticationManager), authenticationManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return authenticationManager;
}

@end

