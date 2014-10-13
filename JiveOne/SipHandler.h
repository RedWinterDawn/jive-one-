//
//  SipHandler.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JCLineSession.h"

typedef void(^ConnectionCompletionHandler)(bool success, NSError *error);

extern NSString *const kSipHandlerRegisteredSelectorKey;

@interface SipHandler : NSObject

@property (nonatomic, strong) NSString *sipURL;
@property (nonatomic) NSInteger mActiveLine;

@property (nonatomic, readonly, getter=isRegistered) BOOL registered;
@property (nonatomic, readonly, getter=isInitialized) BOOL initialized;

// "Registers" the application to the SIP service via the Port SIP SDK.
-(void)connect:(ConnectionCompletionHandler)completion;

// "Deregisters" the application from the SIP service.
-(void)disconnect;

- (void) pressNumpadButton:(char )dtmf;
- (JCLineSession *) makeCall:(NSString*)callee videoCall:(BOOL)videoCall contactName:(NSString *)contactName;
- (void)answerCall;
- (void) hangUpCallWithSession:(long)sessionId;
- (void) holdCall;
- (bool)setConference:(bool)conference;
//- (void) unholdCall;
//- (void) hangUpCall;
- (void) referCall:(NSString*)referTo;
- (void) muteCall:(BOOL)mute;
- (void) setLoudspeakerStatus:(BOOL)enable;
- (void)toggleHoldForLineWithSessionId:(long)sessionId;
- (NSArray *) findAllActiveLines;

//- (void) switchSessionLine;
- (void)startKeepAwake;
- (void)stopKeepAwake;

@end


@interface SipHandler (Singleton)

+ (instancetype) sharedHandler;

@end