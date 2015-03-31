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

@class Line;

extern NSString *const kJCPhoneManagerRegisteringNotification;
extern NSString *const kJCPhoneManagerRegisteredNotification;
extern NSString *const kJCPhoneManagerUnregisteredNotification;
extern NSString *const kJCPhoneManagerRegistrationFailureNotification;

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

@property (nonatomic, readonly, getter=isInitialized) BOOL initialized;
@property (nonatomic, readonly, getter=isRegistering) BOOL registering;
@property (nonatomic, readonly, getter=isRegistered) BOOL registered;
@property (nonatomic, readonly, getter=isActiveCall) BOOL activeCall;
@property (nonatomic, readonly, getter=isConferenceCall) BOOL conferenceCall;
@property (nonatomic, readonly, getter=isMuted) BOOL muted;

@property (nonatomic, readonly) JCPhoneAudioManagerInputType inputType;
@property (nonatomic, readonly) JCPhoneAudioManagerOutputType outputType;

@end

@interface JCPhoneManager (Singleton)

+ (JCPhoneManager *)sharedManager;

+ (void)connectToLine:(Line *)line;
+ (void)disconnect;

+ (void)startKeepAlive;
+ (void)stopKeepAlive;

+ (JCPhoneManagerNetworkType)networkType;

// Attempts to dial a passed string following the dial type directive. When the dial operation was completed, we are
// notified. If the dial action resulted in the creation of a dial card, an kJCCallCardManagerAddedCallNotification is
// broadcasted through the notification center.
+ (void)dialNumber:(NSString *)dialNumber
         usingLine:(Line *)line
              type:(JCPhoneManagerDialType)dialType
        completion:(CompletionHandler)completion;

// Call actions
+ (void)mergeCalls:(CompletionHandler)completion;
+ (void)splitCalls:(CompletionHandler)completion;
+ (void)swapCalls:(CompletionHandler)completion;
+ (void)finishWarmTransfer:(CompletionHandler)completion;
+ (void)muteCall:(BOOL)mute;
+ (void)setLoudSpeakerEnabled:(BOOL)loudSpeakerEnabled;

// NumberPad
+ (void)numberPadPressedWithInteger:(NSInteger)numberPad;

@end

@interface UIViewController (PhoneManager)

// Dials a number. The sender is enabled and disabled while call is being initiated.
- (void)dialNumber:(NSString *)phoneNumber
         usingLine:(Line *)line
            sender:(id)sender;

// Dials a number with a completion block indicating a successfull dial or error, and the specific
// error. Underlying error presents a hud or alert. The sender is enabled and disabled while call is
// being initiated.
- (void)dialNumber:(NSString *)phoneNumber
         usingLine:(Line *)line
            sender:(id)sender
        completion:(CompletionHandler)completion;

@end