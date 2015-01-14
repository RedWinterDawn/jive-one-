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

-(void)sipHandlerDidRegister:(SipHandler *)sipHandler;
-(void)sipHandlerDidUnregister:(SipHandler *)sipHandler;
-(void)sipHandler:(SipHandler *)sipHandler didFailToRegisterWithError:(NSError *)error;
-(void)sipHandler:(SipHandler *)sipHandler receivedIntercomLineSession:(JCLineSession *)session;
-(void)sipHandler:(SipHandler *)sipHandler didAddLineSession:(JCLineSession *)session;
-(void)sipHandler:(SipHandler *)sipHandler willRemoveLineSession:(JCLineSession *)session;

@end

@interface SipHandler : NSObject

@property (nonatomic, weak) id <SipHandlerDelegate> delegate;

@property (nonatomic, readonly) Line *line;
@property (nonatomic, readonly, getter=isRegistered) BOOL registered;
@property (nonatomic, readonly, getter=isInitialized) BOOL initialized;
@property (nonatomic, readonly, getter=isActive) BOOL active;

-(instancetype)initWithNumberOfLines:(NSInteger)lines delegate:(id<SipHandlerDelegate>)delegate;

// Methods to handle registration.
- (void)registerToLine:(Line *)line;
- (void)unregister;

// Backgrounding
- (void)startKeepAwake;
- (void)stopKeepAwake;

// Methods for makeing, transferring or establsihing conference calls.
- (JCLineSession *) makeCall:(NSString*)callee videoCall:(BOOL)videoCall contactName:(NSString *)contactName;
- (void)answerSession:(JCLineSession *)lineSession completion:(CompletionHandler)completion;
- (void)hangUpSession:(JCLineSession *)lineSession completion:(CompletionHandler)completion;
- (void)blindTransferToNumber:(NSString*)referTo completion:(CompletionHandler)completion;
- (void)warmTransferToNumber:(NSString*)referTo completion:(CompletionHandler)completion;
- (bool)setConference:(bool)conference;

// Methods to effect a calls state or audio.
- (void)pressNumpadButton:(char )dtmf;
- (void)muteCall:(BOOL)mute;
- (void)setLoudSpeakerEnabled:(BOOL)loudSpeakerEnabled;
- (void)setHoldCallState:(bool)holdState forSessionId:(long)sessionId;

@end
