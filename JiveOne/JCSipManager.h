//
//  SipHandler.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import "Line.h"
#import "JCLineSession.h"
#import "JCPhoneAudioManager.h"

@class JCSipManager;

@protocol SipHandlerDelegate <JCPhoneAudioManagerDelegate>

// Registration
-(void)sipHandlerDidRegister:(JCSipManager *)sipHandler;
-(void)sipHandlerDidUnregister:(JCSipManager *)sipHandler;
-(void)sipHandler:(JCSipManager *)sipHandler didFailToRegisterWithError:(NSError *)error;

// Intercom line session for Auto Answer feature.
-(void)sipHandler:(JCSipManager *)sipHandler receivedIntercomLineSession:(JCLineSession *)lineSession;

// Call Creation Events
-(void)sipHandler:(JCSipManager *)sipHandler didAddLineSession:(JCLineSession *)lineSession;
-(void)sipHandler:(JCSipManager *)sipHandler didAnswerLineSession:(JCLineSession *)lineSession;
-(void)sipHandler:(JCSipManager *)sipHandler willRemoveLineSession:(JCLineSession *)lineSession;

// Conference Calls
-(void)sipHandler:(JCSipManager *)sipHandler didCreateConferenceCallWithLineSessions:(NSSet *)lineSessions;
-(void)sipHandler:(JCSipManager *)sipHandler didEndConferenceCallForLineSessions:(NSSet *)lineSessions;

// Line Session Status
-(void)sipHandler:(JCSipManager *)sipHandler didUpdateStatusForLineSessions:(NSSet *)lineSessions;

// Transfer Call
-(void)sipHandler:(JCSipManager *)sipHandler didTransferCalls:(NSSet *)lineSessions;
-(void)sipHandler:(JCSipManager *)sipHandler didFailTransferWithError:(NSError *)error;

@end

@interface JCSipManager : NSObject

@property (nonatomic, weak) id <SipHandlerDelegate> delegate;

@property (nonatomic, readonly) JCPhoneAudioManager *audioManager;
@property (nonatomic, readonly) Line *line;

@property (nonatomic, readonly, getter=isInitialized) BOOL initialized;         // If PortSipSDK has been initialized.
@property (nonatomic, readonly, getter=isRegistering) BOOL registering;         // True while we are registering.
@property (nonatomic, readonly, getter=isRegistered) BOOL registered;           // True if we registered.
@property (nonatomic, readonly, getter=isActive) BOOL active;                   // True if we have an active call.
@property (nonatomic, readonly, getter=isConferenceCall) BOOL conferenceCall;   // True if active call is a conference call.
@property (nonatomic, readonly, getter=isMuted) BOOL mute;                      // True if the audio session has been placed on mute.

-(instancetype)initWithNumberOfLines:(NSUInteger)lines delegate:(id<SipHandlerDelegate>)delegate error:(NSError *__autoreleasing *)error;

// Methods to handle registration.
- (void)registerToLine:(Line *)line;
- (void)unregister;

// Backgrounding
- (void)startKeepAwake;
- (void)stopKeepAwake;

// Calls a party from its number.
- (BOOL)makeCall:(id<JCPhoneNumberDataSource>)number videoCall:(BOOL)videoCall error:(NSError *__autoreleasing *)error;

// Call Actions
- (BOOL)answerSession:(JCLineSession *)lineSession error:(NSError *__autoreleasing *)error;         // Answer line session
- (BOOL)hangUpAllSessions:(NSError *__autoreleasing *)error;
- (BOOL)hangUpSession:(JCLineSession *)lineSession error:(NSError *__autoreleasing *)error;         // Hang up line session
- (BOOL)holdLines:(NSError *__autoreleasing *)error;                                                // Hold all line sessions
- (BOOL)holdLineSessions:(NSSet *)lineSessions error:(NSError *__autoreleasing *)error;             // Holds line sessions in set
- (BOOL)holdLineSession:(JCLineSession *)lineSession error:(NSError *__autoreleasing *)error;       // Holds line session
- (BOOL)unholdLines:(NSError *__autoreleasing *)error;                                              // unhold all line sessions
- (BOOL)unholdLineSessions:(NSSet *)lineSessions error:(NSError *__autoreleasing *)error;           // unhold line sessions in set
- (BOOL)unholdLineSession:(JCLineSession *)lineSession error:(NSError *__autoreleasing *)error;     // unhold line session

// Conference Calls
- (BOOL)createConference:(NSError *__autoreleasing *)error;
- (BOOL)createConferenceWithLineSessions:(NSSet *)lineSessions error:(NSError *__autoreleasing *)error;
- (BOOL)endConference:(NSError *__autoreleasing *)error;
- (BOOL)endConferenceCallForLineSessions:(NSSet *)lineSessions error:(NSError *__autoreleasing *)error;

// Methods to effect a calls state or audio.
- (void)pressNumpadButton:(char)dtmf;
- (void)muteCall:(BOOL)mute;
- (void)setLoudSpeakerEnabled:(BOOL)loudSpeakerEnabled;

// Starts a blind transfer. Success and failure reported through the delegate responses.
- (BOOL)startBlindTransferToNumber:(id<JCPhoneNumberDataSource>)number error:(NSError *__autoreleasing *)error;

// Starts a warm transfer, connecting to 2nd party taging first party as going to be transferred.
- (BOOL)startWarmTransferToNumber:(id<JCPhoneNumberDataSource>)number error:(NSError *__autoreleasing *)error;

// Finishes a warm transfer, anctually perfoming the transfer.
- (BOOL)finishWarmTransfer:(NSError *__autoreleasing *)error;

@end
