//
//  Constants.h
//  JiveOAuthTest1
//
//  Created by Eduardo Gueiros on 1/31/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#pragma mark - Keychain Store
#define kJiveAuthStore @"keyjiveauthstore"

#pragma mark - URL Scheme Auth Callback 
#define kURLSchemeCallback @"jiveclient://token"


#pragma mark - OSGI Routes
//#define kOsgiBaseURL @"https://my.jive.com/"
//#define kOsgiBaseURL @"https://test.my.jive.com/"
#define kOsgiBaseURL @"https://osgi.local.com:8000/"
#define kOsgiAuthURL @"https://auth.jive.com/oauth2/grant?client_id=%@&response_type=code&redirect_uri=%@"
#define kOsgiAPIScheme @"api/"
#define kOsgiURNScheme @"urn/"
#define kOsgiAuthRoute @"auth/login?redirectUrl="
#define kOsgiEntityRoute @"entities"
#define kOsgiMyEntityRoute @"entities:me"
#define kOsgiConverationRoute @"conversations"
#define kOsgiSessionRoute @"sessions"
#define kOsgiSubscriptionRoute @"subscriptions"
#define kOsgiPresenceRoute @"presence"

#pragma mark - Temporary Voicemail Constants
#define kDropboxVoicemailRoute @"/u/57157576/voicemail/"
#define kDropboxBaseURL @"https://dl.dropboxusercontent.com"

#pragma mark - Authentication Manager
#define kAuthenticationFromTokenSucceeded @"keyauthenticationfortokensucceeded"
#define kAuthenticationFromTokenFailed @"keyauthenticationfortokenfailed"

#pragma mark - Modal Webview Notification
#define kWebViewDismissal @"keywebviewdismissal"

#pragma mark - OAuth Credentials
#define kOAuthClientSecret @"enXabnU5KuVm4XRSWGkU"
#define kOAuthClientId @"f62d7f80-3749-11e3-9b37-542696d7c505"

#pragma mark - Presence Constants
#define kPresenceAvailable @"Available"
#define kPresenceAway @"Away"
#define kPresenceBusy @"Busy"
#define kPresenceDoNotDisturb @"Do Not Disturb"
#define kPresenceInvisible @"Invisible"
#define kPresenceOffline @"Offline"

typedef enum {
    JCPresenceTypeOffline = 0,
    JCPresenceTypeAvailable = 1,
    JCPresenceTypeBusy = 2,
    JCPresenceTypeInvisible = 4,
    JCPresenceTypeDoNotDisturb = 5,
    JCPresenceTypeAway = 7,  
    JCPresenceTypeNone = -1
} JCPresenceType;

