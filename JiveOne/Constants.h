//
//  Constants.h
//  JiveOAuthTest1
//
//  Created by Eduardo Gueiros on 1/31/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#pragma mark - Miscellaneous
#define kVersionURL         @"http://jiveios.local/LatestVersion"
#define kFeedbackEmail      @"MobileApps+ios@jive.com"
//https://api.jive.com/voicemail/v1/mailbox/id/0144096f-17a0-b3a5-b5e8-000100620002/voicemail/id/6882/liste
#pragma mark - V5 services

#define kVoicemailService   @"http://10.20.26.141:8890/" //@"api.jive.com/voicemail"
#define kMailboxPath        @"voicemail/v1/mailbox/"
#define kJifService         @"https://api.jive.com/jif/v1/" //@"api.jive.com/jif"
#define kv4Provisioning     @"https://pbx.onjive.com/p/mobility/mobileusersettings"
#define kContactsService    @"https://api.jive.com/contacts/"
#define kJiveUserInfo       @"/jiveuser/info/jiveid/"


#pragma mark - Authentication Manager

#define kAuthenticationFromTokenSucceeded           @"keyauthenticationfortokensucceeded"
#define kAuthenticationFromTokenFailed              @"keyauthenticationfortokenfailed"
#define kAuthenticationFromTokenFailedWithTimeout   @"keyauthenticationfortokenfailedwithtimeout"


#pragma mark - Notification Constants
#define kWebViewDismissal   @"keywebviewdismissal"
#define kNewConversation    @"keynewconversation"
#define kPresenceChanged    @"keypresencechanged"
#define kNewVoicemail       @"keynewvoicemail"

#pragma mark - Global Call Notification
#define kIncomingCallNotification @"keyincomingcallnotification"

#pragma -mark Scopes
#define kScopeProfile       @"contacts.v1.profile.read"
#define kScopeVoicemail     @"vm.v1.msgs.meta.read"

#pragma mark - SIP SDK
#define kPortSIPKey         @"1Rx1CNDEwOUM4MzA5RTNEMjM2Q0IwNTVBNEUxMjNBNzhEOEA5Njg2NEI1OTE3OTIxMkM4MTRCMzY5QjMxMzU5NEI2Q0BCNjk0NzZCNkE2MTk1NTY1RjE0Q0M4RDU3NDg3NTdCREBDNUZGRkVCQjNBMzgwMTI3MjI2QkNFMDgxNjg5MjJFRg"

#pragma mark - Reg Constants
#define kRegesterdYes       @"Registered"
#define kRegesterdNo        @"Not Registered"
#define kRegesterdTrying    @"Trying to register"

#pragma mark - Presence Constants
#define kPresenceAvailable      @"Available"
#define kPresenceAway           @"Away"
#define kPresenceBusy           @"Busy"
#define kPresenceDoNotDisturb   @"Do Not Disturb"
#define kPresenceInvisible      @"Invisible"
#define kPresenceOffline        @"Offline"

#pragma mark - Constants
#define kCoreDataDatabase   @"MyJiveDatabase.sqlite"

#pragma mark - KVO Constants
#define kPresenceKeyPathForClientEntity     @"entityPresence"
#define kPresenceKeyPathForLineEntity       @"state"
#define kLastMofiedKeyPathForConversation   @"lastModified"
#define kVoicemailKeyPathForVoicemal        @"voicemail"

#pragma mark - Socket Events
#define kSocketDidOpen  @"socketDidOpen"
#define kSocketEventForLine     @"socketEventForLine"

#pragma mark - Socket Message Types
#define kSocketPresence         @"presence"
#define kSocketConversations    @"conversations"
#define kSocketPermanentRooms   @"permanentrooms"
#define kSocketVoicemail        @"voicemails"

#pragma mark - UIConstants
#define kShiftNameLabelThisMuch     5.0
#define kShiftKeyboardTHisMuch      90
//Applied to the People view
#define kUINameRowHeight            100
#define kUIRowHeight                50
//Used in the DirectoryDetailView Controller
#define NUMBER_OF_ROWS_IN_SECTION   3
#define NUMBER_OF_SECTIONS          1
#define ZERO                        0

#pragma mark - Debug Helpers
#define kVoicemailURLOverRide   @"NoDontUseAWSPlaceholderURL"
//change to @"YesUseAWSPlaceholderURL" to toggle AWS Voicemail wav file

#pragma mark - NSUserDefaults
#define UDdeviceToken   @"deviceToken"


#pragma mark - Misc
#define kTAGStar		10
#define kTAGSharp		11





typedef enum {
    JCExistingConversation,
    JCNewConversation,
    JCNewConversationWithEntity,
    JCNewConversationWithGroup
} JCMessageType;

typedef enum {
    Regesterd,
    Regestering,
    NotRegesterd
} JCRegStatusType;
