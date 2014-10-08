//
//  SipHandler.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PortSIPLib/PortSIPSDK.h>
#import "Lines+Custom.h"
#import "JCLineSession.h"

typedef void(^ConnectionCompletionHandler)(bool success, NSError *error);

@interface SipHandler : NSObject

@property (nonatomic, strong) NSString *sipURL;
@property (nonatomic) NSInteger mActiveLine;

@property (nonatomic, readonly, getter=isRegistered) BOOL registered;
@property (nonatomic, readonly, getter=isInitialized) BOOL initialized;

-(void)connect:(ConnectionCompletionHandler)completion;
-(void)disconnect;



- (void) pressNumpadButton:(char )dtmf;
- (JCLineSession *) makeCall:(NSString*)callee videoCall:(BOOL)videoCall contactName:(NSString *)contactName;
- (void)answerCall;
- (void) hangUpCallWithSession:(long)sessionId;
- (void) holdCall;
//- (void) unholdCall;
//- (void) hangUpCall;
- (void) referCall:(NSString*)referTo;
- (void) muteCall:(BOOL)mute;
- (void) setLoudspeakerStatus:(BOOL)enable;
- (void)toggleHoldForLineWithSessionId:(long)sessionId;
- (NSArray *) findAllActiveLines;

//- (void) switchSessionLine;

@end


@interface SipHandler (Singleton)

+ (instancetype) sharedHandler;

@end