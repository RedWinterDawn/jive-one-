//
//  JCCallManager.h
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

extern NSString *const kJCCallCardManagerAddedCallNotification;
extern NSString *const kJCCallCardManagerAnswerCallNotification;
extern NSString *const kJCCallCardManagerRemoveCallNotification;

extern NSString *const kJCCallCardManagerAddedConferenceCallNotification;
extern NSString *const kJCCallCardManagerRemoveConferenceCallNotification;

extern NSString *const kJCCallCardManagerUpdatedIndex;
extern NSString *const kJCCallCardManagerPriorUpdateCount;
extern NSString *const kJCCallCardManagerUpdateCount;
extern NSString *const kJCCallCardManagerRemovedCells;
extern NSString *const kJCCallCardManagerAddedCells;
extern NSString *const kJCCallCardManagerLastCallState;
extern NSString *const kJCCallCardManagerIncomingCall;

extern NSString *const kJCCallCardManagerNewCall;
extern NSString *const kJCCallCardManagerTransferedCall;

typedef void(^CompletionHandler)(BOOL success, NSError *error);

typedef enum : NSUInteger {
    JCCallCardDialSingle = 0,
    JCCallCardDialBlindTransfer,
    JCCallCardDialWarmTransfer,
} JCCallCardDialTypes;

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

@interface JCCallCardManager : NSObject

@property (nonatomic, strong) NSMutableArray *calls;

@property (nonatomic, readonly) Line *line;
@property (nonatomic, readonly, getter=isConnected) BOOL connected;
@property (nonatomic, readonly) JCPhoneManagerOutputType outputType;

-(void)connectToLine:(Line *)line started:(void(^)())started completed:(CompletionHandler)completed;
-(void)reconnectToLine:(Line *)line started:(void(^)())started completion:(CompletionHandler)completion;
-(void)disconnect;

// Attempts to dial a passed string following the dial type directive. When the dial operation was completed, we are
// notified. If the dial action resulted in the creation of a dial card, an kJCCallCardManagerAddedCallNotification is
// broadcasted through the notification center.
-(void)dialNumber:(NSString *)dialNumber
             type:(JCCallCardDialTypes)dialType
       completion:(void (^)(bool success, NSDictionary *callInfo))completion;

// Merges two existing calls into a conference call. Requires there to be two current calls to be merged.
-(void)mergeCalls:(void (^)(bool success))completion;

// Splits a conference call into it calls.
-(void)splitCalls;

// Switches the active call to be on hold, and unholding the inactive call.
-(void)swapCalls;

// Umm mutes the call :)
-(void)muteCall:(BOOL)mute;

// Finish a transfer
-(void)finishWarmTransfer:(void (^)(bool success))completion;

// NumberPad
-(void)numberPadPressedWithInteger:(NSInteger)numberPad;

-(void)setLoudSpeakerEnabled:(BOOL)loudSpeakerEnabled;

@end

@interface JCCallCardManager (Singleton)

+ (JCCallCardManager *)sharedManager;

+ (void)connectToLine:(Line *)line started:(void(^)())started completed:(CompletionHandler)completed;
+ (void)reconnectToLine:(Line *)line started:(void(^)())started completion:(CompletionHandler)completion;
+ (void)disconnect;

@end