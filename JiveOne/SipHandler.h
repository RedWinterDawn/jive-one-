//
//  SipHandler.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PortSIPLib/PortSIPSDK.h>

@interface SipHandler : NSObject <PortSIPEventDelegate>
{
	
	BOOL mSIPRegistered;
	NSString *sipUrl;
}

@property (strong, nonatomic) PortSIPSDK *mPortSIPSDK;
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic,retain) NSString *sipURL;
@property NSInteger    mActiveLine;

+ (instancetype) sharedHandler;
- (void)initiate;
- (void) pressNumpadButton:(char )dtmf;
- (void) makeCall:(NSString*) callee videoCall:(BOOL)videoCall;
- (void) hungUpCall;
- (void) holdCall;
//- (void) unholdCall;
- (void) hangUpCall;
- (void) referCall:(NSString*)referTo;
- (void) muteCall:(BOOL)mute;
- (void) setLoudspeakerStatus:(BOOL)enable;
- (void) toggleHoldForCallWithSessionState;

//- (void) switchSessionLine;

@end
