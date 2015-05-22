//
//  JCPhoneManager.h
//  JiveOne
//
//  Singleton Manager that interfaces the UI/UX with the back end call architecture.
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import <AFNetworking/AFNetworkReachabilityManager.h>

#import "JCManager.h"
#import "JCSipManager.h"
#import "JCAppSettings.h"
#import "JCPhoneAudioManager.h"
#import "JCPhoneNumberDataSource.h"
#import "JCPhoneBook.h"
#import "JCCallerViewController.h"
#import "JCError.h"

@class Line;

extern NSString *const kJCPhoneManagerRegisteringNotification;
extern NSString *const kJCPhoneManagerRegisteredNotification;
extern NSString *const kJCPhoneManagerUnregisteredNotification;
extern NSString *const kJCPhoneManagerRegistrationFailureNotification;
extern NSString *const kJCPhoneManagerShowCallsNotification;
extern NSString *const kJCPhoneManagerHideCallsNotification;

typedef enum : NSUInteger {
    JCPhoneManagerSingleDial = 0,
    JCPhoneManagerBlindTransfer,
    JCPhoneManagerWarmTransfer,
} JCPhoneManagerDialType;

typedef enum : NSInteger {
    JCPhoneManagerUnknownNetwork    = AFNetworkReachabilityStatusUnknown,
    JCPhoneManagerNoNetwork         = AFNetworkReachabilityStatusNotReachable,
    JCPhoneManagerWifiNetwork       = AFNetworkReachabilityStatusReachableViaWiFi,
    JCPhoneManagerCellularNetwork   = AFNetworkReachabilityStatusReachableViaWWAN,
} JCPhoneManagerNetworkType;

@interface JCPhoneManager : JCManager

@property (nonatomic, strong) NSMutableArray *calls;
@property (nonatomic, strong) NSString *storyboardName;

@property (nonatomic, readonly) Line *line;
@property (nonatomic, readonly) JCPhoneManagerNetworkType networkType;
@property (nonatomic, readonly) JCCallerViewController *callViewController;

@property (nonatomic, readonly, getter=isInitialized) BOOL initialized;
@property (nonatomic, readonly, getter=isRegistering) BOOL registering;
@property (nonatomic, readonly, getter=isRegistered) BOOL registered;
@property (nonatomic, readonly, getter=isActiveCall) BOOL activeCall;
@property (nonatomic, readonly, getter=isConferenceCall) BOOL conferenceCall;
@property (nonatomic, readonly, getter=isMuted) BOOL muted;

@property (nonatomic, readonly) JCPhoneAudioManagerInputType inputType;
@property (nonatomic, readonly) JCPhoneAudioManagerOutputType outputType;

- (void)connectToLine:(Line *)line;
- (void)disconnect;

- (void)startKeepAlive;
- (void)stopKeepAlive;

- (JCPhoneManagerNetworkType)networkType;

// Attempts to dial a passed string following the dial type directive. When the dial operation was
// completed, we are notified. If the dial action resulted in the creation of a dial card, an
// kJCCallCardManagerAddedCallNotification is broadcasted through the notification center.
- (void)dialPhoneNumber:(id<JCPhoneNumberDataSource>)number
         usingLine:(Line *)line
              type:(JCPhoneManagerDialType)dialType
        completion:(CompletionHandler)completion;

// Call actions
- (void)mergeCalls:(CompletionHandler)completion;
- (void)splitCalls:(CompletionHandler)completion;
- (void)swapCalls:(CompletionHandler)completion;
- (void)finishWarmTransfer:(CompletionHandler)completion;
- (void)muteCall:(BOOL)mute;
- (void)setLoudSpeakerEnabled:(BOOL)loudSpeakerEnabled;

// NumberPad
- (void)numberPadPressedWithInteger:(NSInteger)numberPad;

@end

@interface UIViewController (PhoneManager)

@property(nonatomic, strong) JCPhoneManager *phoneManager;

// Dials a number. The sender is enabled and disabled while call is being initiated.
- (void)dialPhoneNumber:(id<JCPhoneNumberDataSource>)number
              usingLine:(Line *)line
                 sender:(id)sender;

// Dials a number with a completion block indicating a successfull dial or error, and the specific
// error. Underlying error presents a hud or alert. The sender is enabled and disabled while call is
// being initiated.
- (void)dialPhoneNumber:(id<JCPhoneNumberDataSource>)number
              usingLine:(Line *)line
                 sender:(id)sender
             completion:(CompletionHandler)completion;

@end

#define JC_PHONE_SIP_NOT_INITIALIZED                -1000
#define JC_PHONE_WIFI_DISABLED                      -1001
#define JC_PHONE_MANAGER_NO_NETWORK                 -1002
#define JC_PHONE_LINE_CONFIGURATION_REQUEST_ERROR   -1003

#define JC_PHONE_CONFERENCE_CALL_ALREADY_EXISTS     -1100
#define JC_PHONE_FAILED_TO_CREATE_CONFERENCE_CALL   -1101
#define JC_PHONE_NO_CONFERENCE_CALL_TO_END          -1102
#define JC_PHONE_FAILED_ENDING_CONFERENCE_CALL      -1103
#define JC_PHONE_BLIND_TRANSFER_FAILED              -1104

@interface JCPhoneManagerError : JCError

@end