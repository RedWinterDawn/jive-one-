//
//  SipHandler.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JCLineSession.h"

typedef void(^CompletionHandler)(bool success, NSError *error);
typedef void(^TransferCompletionHandler)(bool success, NSError *error);

extern NSString *const kSipHandlerRegisteredSelectorKey;

@protocol SipHandlerDelegate <NSObject>

-(void)addLineSession:(JCLineSession *)session;
-(void)removeLineSession:(JCLineSession *)session;

@end


@interface SipHandler : NSObject

@property (nonatomic, weak) id <SipHandlerDelegate> delegate;

@property (nonatomic, strong) NSString *sipURL;
@property (nonatomic) NSInteger mActiveLine;

@property (nonatomic, readonly, getter=isRegistered) BOOL registered;
@property (nonatomic, readonly, getter=isInitialized) BOOL initialized;

@property (nonatomic, copy) TransferCompletionHandler transferCompleted;

- (instancetype)initWithPbx:(PBX *)pbx lineConfiguration:(LineConfiguration *)lineConfiguration delegate:(id<SipHandlerDelegate>)delegate;

// "Registers" the application to the SIP service via the Port SIP SDK.
- (void)connect:(CompletionHandler)completion;

// "Deregisters" the application from the SIP service.
- (void)disconnect;

- (void) pressNumpadButton:(char )dtmf;
- (JCLineSession *) makeCall:(NSString*)callee videoCall:(BOOL)videoCall contactName:(NSString *)contactName;

- (void)answerSession:(JCLineSession *)lineSession completion:(CompletionHandler)completion;

- (void)hangUpSession:(JCLineSession *)lineSession completion:(CompletionHandler)completion;

- (bool)setConference:(bool)conference;
//- (void) hangUpCall;
- (void) blindTransferToNumber:(NSString*)referTo completion:(void (^)(bool success, NSError *error))completion;   // Blind Transfer
- (void) warmTransferToNumber:(NSString*)referTo completion:(void (^)(bool success, NSError *error))completion;    // warm Transfer
- (void) muteCall:(BOOL)mute;
- (void) setLoudspeakerStatus:(BOOL)enable;

// Directly sets the hold state of a call session.
- (void)setHoldCallState:(bool)holdState forSessionId:(long)sessionId;

- (NSArray *) findAllActiveLines;

//- (void) switchSessionLine;
- (void)startKeepAwake;
- (void)stopKeepAwake;

@end
