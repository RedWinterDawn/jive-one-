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

#import "JCCallCard.h"
#import "Line.h"

#import "JCManager.h"

extern NSString *const kJCPhoneManagerAddedCallNotification;
extern NSString *const kJCPhoneManagerAnswerCallNotification;
extern NSString *const kJCPhoneManagerRemoveCallNotification;

extern NSString *const kJCPhoneManagerAddedConferenceCallNotification;
extern NSString *const kJCPhoneManagerRemoveConferenceCallNotification;

extern NSString *const kJCPhoneManagerUpdatedIndex;
extern NSString *const kJCPhoneManagerPriorUpdateCount;
extern NSString *const kJCPhoneManagerUpdateCount;
extern NSString *const kJCPhoneManagerRemovedCells;
extern NSString *const kJCPhoneManagerAddedCells;
extern NSString *const kJCPhoneManagerLastCallState;
extern NSString *const kJCPhoneManagerIncomingCall;

extern NSString *const kJCPhoneManagerNewCall;
extern NSString *const kJCPhoneManagerTransferedCall;

typedef void(^CallCompletionHandler)(BOOL success, NSError *error, NSDictionary *callInfo);

typedef enum : NSUInteger {
    JCPhoneManagerSingleDial = 0,
    JCPhoneManagerBlindTransfer,
    JCPhoneManagerWarmTransfer,
} JCPhoneManagerDialType;

typedef enum : NSUInteger {
    JCPhoneManagerOutputUnknown = 0,
    JCPhoneManagerOutputLineOut,
    JCPhoneManagerOutputHeadphones,
    JCPhoneManagerOutputBluetooth,
    JCPhoneManagerOutputReceiver,
    JCPhoneManagerOutputSpeaker,
    JCPhoneManagerOutputHDMI,
    JCPhoneManagerOutputAirPlay
} JCPhoneManagerOutputType;

typedef enum : NSInteger {
    JCPhoneManagerUnknownNetwork = AFNetworkReachabilityStatusUnknown,
    JCPhoneManagerNoNetwork = AFNetworkReachabilityStatusNotReachable,
    JCPhoneManagerWifiNetwork = AFNetworkReachabilityStatusReachableViaWiFi,
    JCPhoneManagerCellularNetwork = AFNetworkReachabilityStatusReachableViaWWAN,
} JCPhoneManagerNetworkType;

@interface JCPhoneManager : JCManager

@property (nonatomic, strong) NSMutableArray *calls;
@property (nonatomic) BOOL reconnectAfterCallFinishes;

@property (nonatomic, readonly) Line *line;
@property (nonatomic, readonly, getter=isConnected) BOOL connected;
@property (nonatomic, readonly, getter=isConnecting) BOOL connecting;

@property (nonatomic, readonly) BOOL isActiveCall;
@property (nonatomic, readonly) JCPhoneManagerOutputType outputType;
@property (nonatomic, readonly) JCPhoneManagerNetworkType networkType;

@end

@interface JCPhoneManager (Singleton)

+ (JCPhoneManager *)sharedManager;

+ (void)connectToLine:(Line *)line;
+ (void)disconnect;

+ (void)startKeepAlive;
+ (void)stopKeepAlive;

+ (BOOL)isActiveCall;
+ (JCPhoneManagerNetworkType)networkType;

+ (void)setReconnectAfterCallsFinishes;

// Attempts to dial a passed string following the dial type directive. When the dial operation was completed, we are
// notified. If the dial action resulted in the creation of a dial card, an kJCCallCardManagerAddedCallNotification is
// broadcasted through the notification center.
+ (void)dialNumber:(NSString *)dialNumber type:(JCPhoneManagerDialType)dialType completion:(CallCompletionHandler)completion;

// Merges two existing calls into a conference call. Requires there to be two current calls to be merged.
+ (void)mergeCalls:(CompletionHandler)completion;

// Splits a conference call into it calls.
+ (void)splitCalls;

// Switches the active call to be on hold, and unholding the inactive call.
+ (void)swapCalls;

// Umm mutes the call :)
+ (void)muteCall:(BOOL)mute;

// Finish a transfer
+ (void)finishWarmTransfer:(CompletionHandler)completion;

// NumberPad
+ (void)numberPadPressedWithInteger:(NSInteger)numberPad;

+ (void)setLoudSpeakerEnabled:(BOOL)loudSpeakerEnabled;

@end