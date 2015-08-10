//
//  SipManager.h
//  JiveOne
//
//  The SipManager server as a wrapper to the port sip SDK and manages JCLineSession objects.
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import "JCPhoneProvisioningDataSource.h"
#import "JCPhoneNumberDataSource.h"
#import "JCPhoneSipSession.h"
#import "JCPhoneAudioManager.h"
#import "JCError.h"

@protocol JCPhoneSipSessionManagerDelegate;

@interface JCPhoneSipSessionManager : NSObject

@property (nonatomic, weak) id <JCPhoneSipSessionManagerDelegate> delegate;
@property (nonatomic, readonly) id <JCPhoneProvisioningDataSource> provisioning;
@property (nonatomic, readonly) JCPhoneAudioManager *audioManager;

@property (nonatomic, readonly, getter=isInitialized) BOOL initialized;         // If PortSipSDK has been initialized.
@property (nonatomic, readonly, getter=isRegistering) BOOL registering;         // True while we are registering.
@property (nonatomic, readonly, getter=isRegistered) BOOL registered;           // True if we registered.
@property (nonatomic, readonly, getter=isActive) BOOL active;                   // True if we have an active call.
@property (nonatomic, readonly, getter=isConferenceCall) BOOL conferenceCall;   // True if active call is a conference call.
@property (nonatomic, readonly, getter=isMuted) BOOL mute;                      // True if the audio session has been placed on mute.

-(instancetype)initWithNumberOfLines:(NSUInteger)lines
                        audioManager:(JCPhoneAudioManager *)audioManager
                            delegate:(id<JCPhoneSipSessionManagerDelegate>)delegate
                               error:(NSError *__autoreleasing *)error;

// Methods to handle registration.
- (BOOL)registerToProvisioning:(id <JCPhoneProvisioningDataSource>)line;
- (void)unregister;

// Backgrounding
- (void)startKeepAwake;
- (void)stopKeepAwake;

// Calls a party from its number.
- (BOOL)makeCall:(id<JCPhoneNumberDataSource>)number videoCall:(BOOL)videoCall error:(NSError *__autoreleasing *)error;

// Call Actions
- (BOOL)answerSession:(JCPhoneSipSession *)lineSession error:(NSError *__autoreleasing *)error;         // Answer line session
- (BOOL)hangUpAllSessions:(NSError *__autoreleasing *)error;
- (BOOL)hangUpSession:(JCPhoneSipSession *)lineSession error:(NSError *__autoreleasing *)error;         // Hang up line session
- (BOOL)holdLines:(NSError *__autoreleasing *)error;                                                // Hold all line sessions
- (BOOL)holdLineSessions:(NSSet *)lineSessions error:(NSError *__autoreleasing *)error;             // Holds line sessions in set
- (BOOL)holdLineSession:(JCPhoneSipSession *)lineSession error:(NSError *__autoreleasing *)error;       // Holds line session
- (BOOL)unholdLines:(NSError *__autoreleasing *)error;                                              // unhold all line sessions
- (BOOL)unholdLineSessions:(NSSet *)lineSessions error:(NSError *__autoreleasing *)error;           // unhold line sessions in set
- (BOOL)unholdLineSession:(JCPhoneSipSession *)lineSession error:(NSError *__autoreleasing *)error;     // unhold line session

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

@protocol JCPhoneSipSessionManagerDelegate <JCPhoneAudioManagerDelegate>

// Registration
-(void)sipHandlerDidRegister:(JCPhoneSipSessionManager *)sessionManager;
-(void)sipHandlerDidUnregister:(JCPhoneSipSessionManager *)sessionManager;
-(void)sipHandler:(JCPhoneSipSessionManager *)sessionManager didFailToRegisterWithError:(NSError *)error;

// Intercom line session for Auto Answer feature.
-(void)sipHandler:(JCPhoneSipSessionManager *)sessionManager receivedIntercomSession:(JCPhoneSipSession *)session;
-(BOOL)shouldReceiveIncomingLineSession:(JCPhoneSipSessionManager *)sessionManager;

// Call Creation Events
-(void)sipHandler:(JCPhoneSipSessionManager *)sessionManager didAddSession:(JCPhoneSipSession *)session;
-(void)sipHandler:(JCPhoneSipSessionManager *)sessionManager didAnswerSession:(JCPhoneSipSession *)session;
-(void)sipHandler:(JCPhoneSipSessionManager *)sessionManager willRemoveSession:(JCPhoneSipSession *)session;

// Conference Calls
-(void)sipHandler:(JCPhoneSipSessionManager *)sessionManager didCreateConferenceCallWithSessions:(NSSet *)sessions;
-(void)sipHandler:(JCPhoneSipSessionManager *)sessionManager didEndConferenceCallForSessions:(NSSet *)sessions;

// Line Session Status
-(void)sipHandler:(JCPhoneSipSessionManager *)sessionManager didUpdateStatusForSessions:(NSSet *)sessions;

// Transfer Call
-(void)sipHandler:(JCPhoneSipSessionManager *)sessionManager didTransferCalls:(NSSet *)sessions;
-(void)sipHandler:(JCPhoneSipSessionManager *)sessionManager didFailTransferWithError:(NSError *)error;

// Requests a phone number for a given string and name.
-(id<JCPhoneNumberDataSource>)sipHandler:(JCPhoneSipSessionManager *)sipHandler phoneNumberForNumber:(NSString *)string name:(NSString *)name;

@end

#define JC_SIP_REGISTER_LINE_IS_EMPTY                   -5000
#define JC_SIP_REGISTER_LINE_CONFIGURATION_IS_EMPTY     -5001
#define JC_SIP_REGISTER_LINE_PBX_IS_EMPTY               -5002
#define JC_SIP_REGISTER_USER_IS_EMPTY                   -5003
#define JC_SIP_REGISTER_SERVER_IS_EMPTY                 -5004
#define JC_SIP_REGISTER_PASSWORD_IS_EMPTY               -5005
#define JC_SIP_REGISTER_CALLER_ID_IS_EMPTY              -5006
#define JC_SIP_ALREADY_REGISTERING                      -5007
#define JC_SIP_REGISTRATION_TIMEOUT                     -5008
#define JC_SIP_REGISTRATION_FAILURE                     -5009

#define JC_SIP_CALL_NO_IDLE_LINE                        -5100
#define JC_SIP_CALL_NO_ACTIVE_LINE                      -5101
#define JC_SIP_LINE_SESSION_IS_EMPTY                    -5102
#define JC_SIP_CALL_NO_REFERRAL_LINE                    -5103
#define JC_SIP_CALL_POOR_NETWORK_QUALITY                -5104

#define JC_SIP_MAKE_CALL_ERROR                          -5110
#define JC_SIP_ANSWER_CALL_ERROR                        -5111
#define JC_SIP_REJECT_CALL_ERROR                        -5112
#define JC_SIP_HANGUP_CALL_ERROR                        -5113
#define JC_SIP_HOLD_CALLS_ERROR                         -5114
#define JC_SIP_HOLD_CALL_ERROR                          -5115
#define JC_SIP_UNHOLD_CALLS_ERROR                       -5116
#define JC_SIP_UNHOLD_CALL_ERROR                        -5117

#define JC_SIP_CONFERENCE_CALL_ALREADY_STARTED          -5201
#define JC_SIP_CONFERENCE_CALL_ALREADY_ENDED            -5202
#define JC_SIP_CONFERENCE_CALL_CREATION_ERROR           -5203
#define JC_SIP_CONFERENCE_CALL_UNHOLD_CALL_START_ERROR  -5204
#define JC_SIP_CONFERENCE_CALL_ADD_CALL_ERROR           -5205
#define JC_SIP_CONFERENCE_CALL_END_CALL_HOLD_ERROR      -5206

@interface JCSipManagerError : JCError

@end
