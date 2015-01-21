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

@class SipHandler;

@protocol SipHandlerDelegate <NSObject>

// Registration
-(void)sipHandlerDidRegister:(SipHandler *)sipHandler;
-(void)sipHandlerDidUnregister:(SipHandler *)sipHandler;
-(void)sipHandler:(SipHandler *)sipHandler didFailToRegisterWithError:(NSError *)error;

// Intercom line session for Auto Answer feature.
-(void)sipHandler:(SipHandler *)sipHandler receivedIntercomLineSession:(JCLineSession *)lineSession;

// Call Creation Events
-(void)sipHandler:(SipHandler *)sipHandler didAddLineSession:(JCLineSession *)lineSession;
-(void)sipHandler:(SipHandler *)sipHandler didAnswerLineSession:(JCLineSession *)lineSession;
-(void)sipHandler:(SipHandler *)sipHandler willRemoveLineSession:(JCLineSession *)lineSession;

// Conference Calls
-(void)sipHandler:(SipHandler *)sipHandler didCreateConferenceCallWithLineSessions:(NSSet *)lineSessions;
-(void)sipHandler:(SipHandler *)sipHandler didEndConferenceCallForLineSessions:(NSSet *)lineSessions;

// Line Session Status
-(void)sipHandler:(SipHandler *)sipHandler didUpdateStatusForLineSessions:(NSSet *)lineSessions;

@end

@interface SipHandler : NSObject

@property (nonatomic, weak) id <SipHandlerDelegate> delegate;

@property (nonatomic, readonly) Line *line;
@property (nonatomic, readonly, getter=isRegistered) BOOL registered;
@property (nonatomic, readonly, getter=isInitialized) BOOL initialized;
@property (nonatomic, readonly, getter=isActive) BOOL active;
@property (nonatomic, readonly, getter=isConferenceCall) BOOL conferenceCall;

-(instancetype)initWithNumberOfLines:(NSInteger)lines delegate:(id<SipHandlerDelegate>)delegate error:(NSError *__autoreleasing *)error;

// Methods to handle registration.
- (void)registerToLine:(Line *)line;
- (void)unregister;

// Backgrounding
- (void)startKeepAwake;
- (void)stopKeepAwake;

// Methods for makeing, transferring or establsihing conference calls.
- (BOOL)makeCall:(NSString*)callee videoCall:(BOOL)videoCall error:(NSError *__autoreleasing *)error;

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

- (void)blindTransferToNumber:(NSString*)referTo completion:(CompletionHandler)completion;
- (void)warmTransferToNumber:(NSString*)referTo completion:(CompletionHandler)completion;

// Conference Calls
- (BOOL)createConference:(NSError *__autoreleasing *)error;
- (BOOL)createConferenceWithLineSessions:(NSSet *)lineSessions error:(NSError *__autoreleasing *)error;

- (BOOL)endConference:(NSError *__autoreleasing *)error;
- (BOOL)endConferenceCallForLineSessions:(NSSet *)lineSessions error:(NSError *__autoreleasing *)error;

// Methods to effect a calls state or audio.
- (void)pressNumpadButton:(char )dtmf;
- (void)muteCall:(BOOL)mute;
- (void)setLoudSpeakerEnabled:(BOOL)loudSpeakerEnabled;
//- (void)setHoldCallState:(bool)holdState forSessionId:(long)sessionId;

@end
