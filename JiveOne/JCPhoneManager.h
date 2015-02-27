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
    JCPhoneManagerUnknownNetwork    = AFNetworkReachabilityStatusUnknown,
    JCPhoneManagerNoNetwork         = AFNetworkReachabilityStatusNotReachable,
    JCPhoneManagerWifiNetwork       = AFNetworkReachabilityStatusReachableViaWiFi,
    JCPhoneManagerCellularNetwork   = AFNetworkReachabilityStatusReachableViaWWAN,
} JCPhoneManagerNetworkType;

@interface JCPhoneManager : JCManager

@property (nonatomic, strong) NSMutableArray *calls;
@property (nonatomic, strong) NSString *storyboardName;

@property (nonatomic, strong) NSTimer *regTimer;
@property (nonatomic) NSInteger *timeToWait;
@property (nonatomic, readonly) Line *line;
@property (nonatomic, readonly) JCPhoneManagerOutputType outputType;
@property (nonatomic, readonly) JCPhoneManagerNetworkType networkType;

@property (nonatomic, readonly, getter=isInitialized) BOOL initialized;
@property (nonatomic, readonly, getter=isConnected) BOOL connected;
@property (nonatomic, readonly, getter=isConnecting) BOOL connecting;
@property (nonatomic, readonly, getter=isConferenceCall) BOOL conferenceCall;
@property (nonatomic, readonly) BOOL isMuted;

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
+ (void)dialNumber:(NSString *)dialNumber type:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion;

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

- (void)dialNumber:(NSString *)phoneNumber sender:(id)sender;
- (void)dialNumber:(NSString *)phoneNumber sender:(id)sender completion:(CompletionHandler)completion;

@end