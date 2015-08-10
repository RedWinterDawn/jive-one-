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
#import "JCPhoneAudioManager.h"
#import "JCPhoneNumberDataSource.h"
#import "JCPhoneProvisioningDataSource.h"
#import "JCPhoneCallViewController.h"
#import "JCLineSession.h"
#import "JCSipManager.h"
#import "JCPhoneSettings.h"

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

@protocol JCPhoneManagerDelegate;

@interface JCPhoneManager : JCManager

-(instancetype)initWithSipManager:(JCSipManager *)sipManager
                         settings:(JCPhoneSettings *)settings
                     reachability:(AFNetworkReachabilityManager *)reachability;

@property (nonatomic, strong) NSMutableArray *calls;
@property (nonatomic, strong) NSString *storyboardName;
@property (nonatomic, weak) id<JCPhoneManagerDelegate> delegate;

@property (nonatomic, readonly) id<JCPhoneProvisioningDataSource> provisioningProfile;
@property (nonatomic, readonly) JCPhoneSettings *settings;
@property (nonatomic, readonly) JCPhoneManagerNetworkType networkType;
@property (nonatomic, readonly) JCPhoneCallViewController *callViewController;

@property (nonatomic, readonly, getter=isInitialized) BOOL initialized;
@property (nonatomic, readonly, getter=isRegistering) BOOL registering;
@property (nonatomic, readonly, getter=isRegistered) BOOL registered;
@property (nonatomic, readonly, getter=isActiveCall) BOOL activeCall;
@property (nonatomic, readonly, getter=isConferenceCall) BOOL conferenceCall;
@property (nonatomic, readonly, getter=isMuted) BOOL muted;

@property (nonatomic, readonly) JCPhoneAudioManagerInputType inputType;
@property (nonatomic, readonly) JCPhoneAudioManagerOutputType outputType;

- (void)connectWithProvisioningProfile:(id<JCPhoneProvisioningDataSource>)provisioningProfile;
- (void)disconnect;

- (void)startKeepAlive;
- (void)stopKeepAlive;

- (JCPhoneManagerNetworkType)networkType;

// Attempts to dial a passed string following the dial type directive. When the dial operation was
// completed, we are notified. If the dial action resulted in the creation of a dial card, an
// kJCCallCardManagerAddedCallNotification is broadcasted through the notification center.
- (void)dialPhoneNumber:(id<JCPhoneNumberDataSource>)number
    provisioningProfile:(id<JCPhoneProvisioningDataSource>)provisioningProfile
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


typedef enum : NSUInteger {
    JCPhoneManagerIncomingCall,
    JCPhoneManagerMissedCall,
    JCPhoneManagerOutgoingCall,
} JCPhoneManagerCallType;

@protocol JCPhoneManagerDelegate <NSObject>

-(void)phoneManager:(JCPhoneManager *)manager
   reportCallOfType:(JCPhoneManagerCallType)type
        lineSession:(JCLineSession *)lineSession
provisioningProfile:(id<JCPhoneProvisioningDataSource>)provisioningProfile;

-(id<JCPhoneNumberDataSource>)phoneManager:(JCPhoneManager *)manager
                      phoneNumberForNumber:(NSString *)number
                                      name:(NSString *)name
                              provisioning:(id<JCPhoneProvisioningDataSource>)provisioning;

-(void)phoneManager:(JCPhoneManager *)phoneManger phoneNumbersForKeyword:(NSString *)keyword
       provisioning:(id<JCPhoneProvisioningDataSource>)provisioning
         completion:(void(^)(NSArray *phoneNumbers))completion;

-(id<JCPhoneNumberDataSource>)phoneManager:(JCPhoneManager *)phoneManager
           lastCalledNumberForProvisioning:(id<JCPhoneProvisioningDataSource>)provisioning;

@end


@interface UIViewController (PhoneManager)

@property(nonatomic, strong) JCPhoneManager *phoneManager;

// Dials a number. The sender is enabled and disabled while call is being initiated.
- (void)dialPhoneNumber:(id<JCPhoneNumberDataSource>)number
                 sender:(id)sender;

// Dials a number. The sender is enabled and disabled while call is being initiated.
- (void)dialPhoneNumber:(id<JCPhoneNumberDataSource>)number
    provisioningProfile:(id<JCPhoneProvisioningDataSource>)provisioningProfile
                 sender:(id)sender;

// Dials a number with a completion block indicating a successfull dial or error, and the specific
// error. Underlying error presents a hud or alert. The sender is enabled and disabled while call is
// being initiated.
- (void)dialPhoneNumber:(id<JCPhoneNumberDataSource>)number
    provisioningProfile:(id<JCPhoneProvisioningDataSource>)provisioningProfile
                 sender:(id)sender
             completion:(CompletionHandler)completion;

@end