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


#if DEBUG
    #define kOsgiBaseURL @"https://test.my.jive.com/"
    //#define kOsgiBaseURL @"https://osgi.local.com:8000/"
#else
    #define kOsgiBaseURL @"https://test.my.jive.com/"
#endif


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
#define kOsgiVoicemailRoute @"voicemails"
#define kVersionURL @"http://jiveios.local/LatestVersion"
#define kEulaSite @"http://tengentllc.com/legal.html"

#pragma mark - Temporary Voicemail Constants
#define kAWSVoicemailRoute @"voicemail/userId/"
#define kAWSBaseURL @"https://s3-us-west-2.amazonaws.com/jive-mobile/"

#pragma mark - Authentication Manager
#define kAuthenticationFromTokenSucceeded @"keyauthenticationfortokensucceeded"
#define kAuthenticationFromTokenFailed @"keyauthenticationfortokenfailed"
#define kAuthenticationFromTokenFailedWithTimeout @"keyauthenticationfortokenfailedwithtimeout"


#pragma mark - Notification Constants
#define kWebViewDismissal @"keywebviewdismissal"
#define kNewConversation @"keynewconversation"
#define kPresenceChanged @"keypresencechanged"
#define kNewVoicemail @"keynewvoicemail"

#pragma mark - OAuth Credentials
#define kOAuthClientSecret @"enXabnU5KuVm4XRSWGkU"
#define kOAuthClientId @"f62d7f80-3749-11e3-9b37-542696d7c505"
#define kTestAuthKey @"f1c7adf0-786e-404e-a107-2921fc040d4a";

#pragma mark - Presence Constants
#define kPresenceAvailable @"Available"
#define kPresenceAway @"Away"
#define kPresenceBusy @"Busy"
#define kPresenceDoNotDisturb @"Do Not Disturb"
#define kPresenceInvisible @"Invisible"
#define kPresenceOffline @"Offline"

#pragma mark - KVO Constants
#define kPresenceKeyPathForClientEntity @"entityPresence"
#define kLastMofiedKeyPathForConversation @"lastModified"
#define kVoicemailKeyPathForVoicemal @"voicemail"

#pragma mark - Socket Message Types
#define kSocketPresence @"presence"
#define kSocketConversations @"conversations"
#define kSocketPermanentRooms @"permanentrooms"
#define kSocketVoicemail @"voicemails"

#pragma mark - UIConstants
#define kShiftNameLabelThisMuch 5.0
#define kShiftKeyboardTHisMuch 90
//Applied to the People view
#define kUINameRowHeight 100
#define kUIRowHeight 50
//Used in the DirectoryDetailView Controller
#define NUMBER_OF_ROWS_IN_SECTION 3
#define NUMBER_OF_SECTIONS 1
#define ZERO 0

#pragma mark - Debug Helpers
#define kVoicemailURLOverRide @"NoDontUseAWSPlaceholderURL"
//change to @"YesUseAWSPlaceholderURL" to toggle AWS Voicemail wav file
#define UDdeviceToken @"deviceToken"



typedef enum {
    JCPresenceTypeOffline = 0,
    JCPresenceTypeAvailable = 1,
    JCPresenceTypeBusy = 9,
    JCPresenceTypeInvisible = 4,
    JCPresenceTypeDoNotDisturb = 2,
    JCPresenceTypeAway = 7,  
    JCPresenceTypeNone = -1
} JCPresenceType;

typedef enum {
    JCExistingConversation,
    JCNewConversation,
    JCNewConversationWithEntity,
    JCNewConversationWithGroup
} JCMessageType;

typedef enum {
    JCRootLoginViewController,
    JCRootTabbarViewController
} JCRootViewControllerType;

