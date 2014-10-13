//
//  SipHandler.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "SipHandler.h"

#import <PortSIPLib/PortSIPSDK.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>

#import "LineConfiguration+Custom.h"
#import "Lines+Custom.h"
#import "PBX+Custom.h"
#import "JCCallCardManager.h"

#define MAX_LINES 8
#define ALERT_TAG_REFER 100
#define OUTBOUND_SIP_SERVER_PORT 5060

NSString *const kSipHandlerServerAgentname = @"Jive iOS Client";
NSString *const kSipHandlerFetchLineConfigurationErrorMessage = @"Unable to fetch the line configuration";
NSString *const kSipHandlerFetchPBXErrorMessage = @"Unable to fetch the line configuration";
NSString *const kSipHandlerRegisteredSelectorKey = @"registered";

@interface SipHandler() <PortSIPEventDelegate>
{
    PortSIPSDK *_mPortSIPSDK;
    ConnectionCompletionHandler _connectionCompletionHandler;
    AFNetworkReachabilityStatus _previousNetworkStatus;
}

@property (nonatomic) NSMutableArray *lineSessions;

- (JCLineSession *)findSession:(long)sessionId;

@end

@implementation SipHandler

-(id)init
{
    self = [super init];
    if (self)
    {
        if (_registered)
            return self;
        
        _lineSessions = [NSMutableArray new];
        for (int i = 0; i < 2; i++)
            [_lineSessions addObject:[JCLineSession new]];
        
        _mPortSIPSDK = [[PortSIPSDK alloc] init];
        _mPortSIPSDK.delegate = self;
        
        // Register to listen for AFNetworkReachability Changes.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(networkConnectivityChanged:) name:AFNetworkingReachabilityDidChangeNotification  object:nil];
        _previousNetworkStatus = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
        
        [self connect:NULL];
    }
    return self;
}

#pragma mark - Device Registration -

-(void)connect:(ConnectionCompletionHandler)completionHandler;
{
    _connectionCompletionHandler = completionHandler;
    
    // If we are already connected, disconnect then reconnect.
    if (_registered)
        [self disconnect];
    
    @try {
        NSLog(@"Connecting");
        
        [self login];
        _initialized = true;
    }
    @catch (NSException *exception) {
        NSError *error = [NSError errorWithDomain:exception.reason code:0 userInfo:nil];
        if (completionHandler != NULL)
            completionHandler(false, error);
        else
            NSLog(@"%@", error);
    }
}

/**
 *  Sets the User info from Core Data into the Port Sip SDK.
 */
-(void)login
{
    LineConfiguration *config = [LineConfiguration MR_findFirst];
    if (!config)
        [NSException raise:NSInvalidArgumentException format:kSipHandlerFetchLineConfigurationErrorMessage];
    
    PBX *pbx = [PBX MR_findFirst];
    if (!pbx)
        [NSException raise:NSInvalidArgumentException format:kSipHandlerFetchPBXErrorMessage];
    
    NSString *kSipUserName  = config.sipUsername;
    NSString *kSIPServer    = ([pbx.v5 boolValue]) ? config.outboundProxy : config.registrationHost;
    
    _sipURL = [[NSString alloc] initWithFormat:@"sip:%@:%@", kSipUserName, kSIPServer];
    
    // Initialized the SIP SDK
    int ret = [_mPortSIPSDK initialize:TRANSPORT_UDP
                              loglevel:PORTSIP_LOG_DEBUG
                               logPath:NULL
                               maxLine:MAX_LINES
                                 agent:kSipHandlerServerAgentname
                    virtualAudioDevice:FALSE
                    virtualVideoDevice:FALSE];
    
    if(ret != 0)
        [NSException raise:NSInvalidArgumentException format:@"initializeSDK failure ErrorCode = %d",ret];
    
    ret = [_mPortSIPSDK setUser:kSipUserName
                    displayName:config.display
                       authName:kSipUserName
                       password:config.sipPassword
                        localIP:@"0.0.0.0"                      // Auto select IP address
                   localSIPPort:(10000 + arc4random()%1000)     // Generate a random port in the 10,000 range
                     userDomain:@""
                      SIPServer:kSIPServer
                  SIPServerPort:OUTBOUND_SIP_SERVER_PORT
                     STUNServer:@""
                 STUNServerPort:0
                 outboundServer:config.outboundProxy
             outboundServerPort:OUTBOUND_SIP_SERVER_PORT];
    
    if(ret != 0)
        [NSException raise:NSInvalidArgumentException format:@"set user failure ErrorCode = %d",ret];
    
    ret = [_mPortSIPSDK setLicenseKey:kPortSIPKey];
    if (ret == ECoreTrialVersionLicenseKey)
        [NSException raise:NSInvalidArgumentException format:@"This trial version SDK just allows short conversation, you can't heairng anyting after 2-3 minutes, contact us: sales@portsip.com to buy official version."];
    else if (ret == ECoreWrongLicenseKey)
        [NSException raise:NSInvalidArgumentException format:@"The wrong license key was detected, please check with sales@portsip.com or support@portsip.com"];
    
    //[_mPortSIPSDK addAudioCodec:AUDIOCODEC_PCMA];
    [_mPortSIPSDK addAudioCodec:AUDIOCODEC_PCMU];
    //[_mPortSIPSDK addAudioCodec:AUDIOCODEC_SPEEX];
    [_mPortSIPSDK addAudioCodec:AUDIOCODEC_G729];
    [_mPortSIPSDK addAudioCodec:AUDIOCODEC_G722];
    
    //[_mPortSIPSDK addAudioCodec:AUDIOCODEC_GSM];
    //[_mPortSIPSDK addAudioCodec:AUDIOCODEC_ILBC];
    //[_mPortSIPSDK addAudioCodec:AUDIOCODEC_AMR];
    //[_mPortSIPSDK addAudioCodec:AUDIOCODEC_SPEEXWB];
    
    //[_mPortSIPSDK addVideoCodec:VIDEO_CODEC_H263];
    //[_mPortSIPSDK addVideoCodec:VIDEO_CODEC_H263_1998];
    [_mPortSIPSDK addVideoCodec:VIDEO_CODEC_H264];
    
    [_mPortSIPSDK setVideoBitrate:100];//video send bitrate,100kbps
    [_mPortSIPSDK setVideoFrameRate:10];
    [_mPortSIPSDK setVideoResolution:VIDEO_CIF];
    [_mPortSIPSDK setAudioSamples:20 maxPtime:60];//ptime 20
    
    //1 - FrontCamra 0 - BackCamra
    [_mPortSIPSDK setVideoDeviceId:1];
    //[_mPortSIPSDK setVideoOrientation:180];
    
    //enable srtp
    [_mPortSIPSDK setSrtpPolicy:SRTP_POLICY_NONE];
    
    // Try to register the default identity
    [_mPortSIPSDK registerServer:120 retryTimes:3];
}

-(void)disconnect
{
    if(_initialized)
    {
        [_mPortSIPSDK unRegisterServer];
        [_mPortSIPSDK unInitialize];
        
        _registered = NO;
        _initialized = NO;
    }
}

#pragma mark Registration Callback

- (void)onRegisterSuccess:(char*) statusText statusCode:(int)statusCode
{
    [self willChangeValueForKey:kSipHandlerRegisteredSelectorKey];
    _registered = TRUE;
    if (_connectionCompletionHandler != NULL)
        _connectionCompletionHandler(true, nil);
    [self didChangeValueForKey:kSipHandlerRegisteredSelectorKey];
};

- (void)onRegisterFailure:(char*) statusText statusCode:(int)statusCode
{
    [self willChangeValueForKey:kSipHandlerRegisteredSelectorKey];
    _registered = FALSE;
    NSString *errorMessage = [NSString stringWithFormat:@"%@ code:(%i)", [NSString stringWithUTF8String:statusText], statusCode];
    if (_connectionCompletionHandler != NULL)
        _connectionCompletionHandler(false, [NSError errorWithDomain:errorMessage code:0 userInfo:nil]);
    [self didChangeValueForKey:kSipHandlerRegisteredSelectorKey];
};

#pragma mark NetworkConnectivity

-(void)networkConnectivityChanged:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    AFNetworkReachabilityStatus status = (AFNetworkReachabilityStatus)((NSNumber *)[userInfo valueForKey:AFNetworkingReachabilityNotificationStatusItem]).integerValue;
    NSLog(@"AFNetworking status change");
    
    if (_previousNetworkStatus == AFNetworkReachabilityStatusUnknown)
        _previousNetworkStatus = status;
    
    switch (status)
    {
        case AFNetworkReachabilityStatusNotReachable:
            break;
        case AFNetworkReachabilityStatusReachableViaWiFi: {
            
            // If we are not transitioning from cellular to wifi, reconnect
            if (_previousNetworkStatus != AFNetworkReachabilityStatusReachableViaWWAN && _previousNetworkStatus != AFNetworkReachabilityStatusReachableViaWiFi)
            {
                JCLineSession *lineSession = [self findLineWithSessionState];
                if (lineSession)
                {
                    [self hangUpCallWithSession:lineSession.mSessionId];
                }
                
                [self connect:NULL];
            }
            
            break;
        }
        case AFNetworkReachabilityStatusReachableViaWWAN:
            
            
            break;
            
        default:
            [self connect:NULL];
            break;
    }
    _previousNetworkStatus = status;
}

- (void)startKeepAwake
{
    if (_mPortSIPSDK)
    {
        [_mPortSIPSDK startKeepAwake];
    }
}

-(void)stopKeepAwake
{
    if (_mPortSIPSDK)
    {
        [_mPortSIPSDK stopKeepAwake];
    }
}


//#pragma mark - Registration Delegates
//
//- (void)onRegisterSuccess:(char*) statusText statusCode:(int)statusCode
//{
////	[viewStatus setBackgroundColor:[UIColor greenColor]];
////	
////	[labelStatus setText:@"Connected"];
////	
////	[labelDebugInfo setText:[NSString stringWithFormat: @"onRegisterSuccess: %s", statusText]];
////	
////	[activityIndicator stopAnimating];
//	
//	SIPRegistered = YES;
////	return 0;
//}
//
//
//- (void)onRegisterFailure:(char*) statusText statusCode:(int)statusCode
//{
////	[viewStatus setBackgroundColor:[UIColor redColor]];
////	
////	[labelStatus setText:@"Not Connected"];
////	
////	[labelDebugInfo setText:[NSString stringWithFormat: @"onRegisterFailure: %s", statusText]];
////	
////	[activityIndicator stopAnimating];
//	
//	SIPRegistered = NO;
////	return 0;
//};

- (JCLineSession *)findSession:(long)sessionId
{

	for (JCLineSession *line in self.lineSessions)
	{
		if (sessionId == line.mSessionId)
		{
			return line;
		}
	}
	
	return nil;
}

#pragma mark - Find line methods
- (JCLineSession *)findLineWithSessionState
{
	for (JCLineSession *line in self.lineSessions)
	{
		if (line.mSessionState &&
			!line.mHoldSate &&
			!line.mRecvCallState)
		{
			return line;
		}
	}
	return nil;
}

- (JCLineSession *)findLineWithRecevingState
{
	for (JCLineSession *line in self.lineSessions)
	{
		if (!line.mSessionState &&
			line.mRecvCallState)
		{
			return line;
		}
	}
	return nil;
}

- (JCLineSession *)findLineWithHoldState
{
	for (JCLineSession *line in self.lineSessions)
	{
		if (line.mSessionState &&
			line.mHoldSate &&
			!line.mRecvCallState)
		{
			return line;
		}
	}
	return nil;
}

- (JCLineSession *)findIdleLine
{
	for (JCLineSession *line in self.lineSessions)
	{
		if (!line.mSessionState &&
			!line.mRecvCallState)
		{
			return line;
		}
	}
	return nil;
}

- (NSArray *) findAllActiveLines {
	NSMutableArray *activeLines = [NSMutableArray new];
	for (JCLineSession *line in self.lineSessions)
	{
		if (line.mSessionState) {
			[activeLines addObject:line];
		}
	}
	return activeLines;
}

- (void) pressNumpadButton:(char )dtmf
{
	JCLineSession *session = [self findLineWithSessionState];
	if(session && session.mSessionState)
	{
		[_mPortSIPSDK sendDtmf:session.mSessionId dtmfMethod:DTMF_RFC2833 code:dtmf dtmfDration:160 playDtmfTone:TRUE];
	}
}

- (JCLineSession *) makeCall:(NSString*) callee
		videoCall:(BOOL)videoCall contactName:(NSString *)contactName;
{

	JCLineSession *currentSession = [self findLineWithSessionState];
	if (currentSession && currentSession.mSessionState && !currentSession.mHoldSate) {
		[_mPortSIPSDK hold:currentSession.mSessionId];
	}
	
	currentSession = [self findIdleLine];	
	
	long sessionId = [_mPortSIPSDK call:callee sendSdp:TRUE videoCall:videoCall];	
	if(sessionId >= 0)
	{
		[currentSession setMSessionId:sessionId];
		[currentSession setMSessionState:YES];
		
		[currentSession setCallTitle:contactName ? contactName : callee];
		[currentSession setCallDetail:callee];
	}
	else
	{
		//TODO:update call state
		[currentSession setMCallState:JCCallFailed];
		[currentSession reset];
	}
	
	return currentSession;
}

- (void) hangUpCallWithSession:(long)sessionId;
{
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (selectedLine.mSessionState)
	{
		[_mPortSIPSDK hangUp:selectedLine.mSessionId];
//		if (mSessionArray[mActiveLine].getVideoState() == true) {
//			[videoViewController onStopVideo:mSessionArray[mActiveLine].getSessionId()];
//		}
		
//		[numpadViewController setStatusText:[NSString  stringWithFormat:@"Hungup call on line %ld", mActiveLine]];
		
	}
	else if (selectedLine.mRecvCallState)
	{
		[_mPortSIPSDK rejectCall:selectedLine.mSessionId code:486];
		
//		[numpadViewController setStatusText:[NSString  stringWithFormat:@"Rejected call on line %ld", mActiveLine]];
	}
	
//	[selectedLine setMCallState:JCCallCanceled];
	[selectedLine reset];
}

- (void)toggleHoldForLineWithSessionId:(long)sessionId
{
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (selectedLine && selectedLine.mHoldSate) {
		[_mPortSIPSDK unHold:selectedLine.mSessionId];
		[selectedLine setMHoldSate:false];
	}
	else if (selectedLine) {
		[_mPortSIPSDK hold:selectedLine.mSessionId];
		[selectedLine setMHoldSate:true];
	}
}

- (void) toggleHoldForCallWithSessionState
{
	JCLineSession *selectedLine = [self findLineWithSessionState];
	if (!selectedLine) {
		selectedLine = [self findLineWithHoldState];
	}
	
	if (selectedLine.mHoldSate) {
		[_mPortSIPSDK unHold:selectedLine.mSessionId];
		[selectedLine setMHoldSate:NO];
	}
	else {
		[_mPortSIPSDK hold:selectedLine.mSessionId];
		[selectedLine setMHoldSate:YES];
	}
}

- (void) holdCall
{
	JCLineSession *selectedLine = [self findLineWithSessionState];
	if (!selectedLine)
	{
		return;
	}
	
	[_mPortSIPSDK hold:selectedLine.mSessionId];
	[selectedLine setMHoldSate:true];
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Hold the call on line %ld", mActiveLine]];
	
	//TODO:update call state
}

//- (void) unholdCall
//{
//	if (mSessionArray[mActiveLine].getSessionState() == false ||
//		mSessionArray[mActiveLine].getHoldState() == false)
//	{
//		return;
//	}
//	
//	[_mPortSIPSDK unHold:mSessionArray[mActiveLine].getSessionId()];
//	mSessionArray[mActiveLine].setHoldState(false);
//	
////	[numpadViewController setStatusText:[NSString  stringWithFormat:@"UnHold the call on line %ld", mActiveLine]];
//	
//	//TODO:update call state
//}

- (void) referCall:(NSString*)referTo
{
	JCLineSession *selectedLine = [self findLineWithSessionState];
	if (!selectedLine || selectedLine.mSessionState == false)
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Warning"
							  message: @"Need to make the call established first"
							  delegate: nil
							  cancelButtonTitle: @"OK"
							  otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	int errorCodec = [_mPortSIPSDK refer:selectedLine.mSessionId referTo:referTo];
	if (errorCodec != 0)
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Warning"
							  message: @"Refer failed"
							  delegate: nil
							  cancelButtonTitle: @"OK"
							  otherButtonTitles:nil];
		[alert show];
		[selectedLine setMCallState:JCTransferFailed];
	}
	
	[selectedLine setMCallState:JCTransferSuccess];
}

- (void) muteCall:(BOOL)mute
{
	JCLineSession *selectedLine = [self findLineWithSessionState];
	
	if(selectedLine.mSessionState){
			[_mPortSIPSDK muteSession:selectedLine.mSessionState
				   muteIncomingAudio:FALSE
				   muteOutgoingAudio:mute
				   muteIncomingVideo:FALSE
				   muteOutgoingVideo:mute];
	}
}

- (void)switchLines
{
	JCLineSession *activeLine = [self findLineWithSessionState];
	JCLineSession *lineOnHold = [self findLineWithHoldState];
	if (activeLine)
	{
		// Need to hold this line
		[_mPortSIPSDK hold:activeLine.mSessionId];
		[activeLine setMHoldSate:true];
		
		//		[numpadViewController setStatusText:[NSString  stringWithFormat:@"Hold call on line %ld", mActiveLine]];
	}
	//	[numpadViewController.buttonLine setTitle:[NSString  stringWithFormat:@"Line%ld:", mActiveLine] forState:UIControlStateNormal];
	
	if (lineOnHold)
	{
		// Need to unhold this line
		[_mPortSIPSDK unHold:lineOnHold.mSessionState];
		[activeLine setMHoldSate:false];
		
		//		[numpadViewController setStatusText:[NSString  stringWithFormat:@"unHold call on line %ld", mActiveLine]];
	}

}

- (void) setLoudspeakerStatus:(BOOL)enable
{
	[_mPortSIPSDK setLoudspeakerStatus:enable];
}

//- (void)didSelectLine:(NSInteger)activeLine
//{
//	UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
//	
//	[tabBarController dismissViewControllerAnimated:TRUE completion:nil];
//	
//	if (mSIPRegistered == false || mActiveLine == activeLine)
//	{
//		return;
//	}
//	
//	if (mSessionArray[mActiveLine].getSessionState()==true && mSessionArray[mActiveLine].getHoldState()==false)
//	{
//		// Need to hold this line
//		[_mPortSIPSDK hold:mSessionArray[mActiveLine].getSessionId()];
//		
//		mSessionArray[mActiveLine].setHoldState(true);
//		
////		[numpadViewController setStatusText:[NSString  stringWithFormat:@"Hold call on line %ld", mActiveLine]];
//	}
//	
//	mActiveLine = activeLine;
////	[numpadViewController.buttonLine setTitle:[NSString  stringWithFormat:@"Line%ld:", mActiveLine] forState:UIControlStateNormal];
//	
//	if (mSessionArray[mActiveLine].getSessionState()==true && mSessionArray[mActiveLine].getHoldState()==true)
//	{
//		// Need to unhold this line
//		[_mPortSIPSDK unHold:mSessionArray[mActiveLine].getSessionId()];
//		
//		mSessionArray[mActiveLine].setHoldState(false);
//		
////		[numpadViewController setStatusText:[NSString  stringWithFormat:@"unHold call on line %ld", mActiveLine]];
//	}
//}

//- (void) switchSessionLine
//{
//	UIStoryboard *stryBoard=[UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
//	
////	LineTableViewController* selectLineView  = [stryBoard instantiateViewControllerWithIdentifier:@"LineTableViewController"];
//	
////	selectLineView.delegate = self;
////	selectLineView.mActiveLine = mActiveLine;
//	
//	UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
//	
//	[tabBarController presentViewController:selectLineView animated:YES completion:nil];
//}




#pragma mark - Call Events
//Call Event
- (void)onInviteIncoming:(long)sessionId
	   callerDisplayName:(char*)callerDisplayName
				  caller:(char*)caller
	   calleeDisplayName:(char*)calleeDisplayName
				  callee:(char*)callee
			 audioCodecs:(char*)audioCodecs
			 videoCodecs:(char*)videoCodecs
			 existsAudio:(BOOL)existsAudio
			 existsVideo:(BOOL)existsVideo
{
	NSLog(@"onInviteIncoming - Session ID: %ld", sessionId);
	JCLineSession *idleLine = [self findIdleLine];
	
	if (!idleLine)
	{
		[_mPortSIPSDK rejectCall:sessionId code:486];
		return ;
	}
	
	[idleLine setMSessionId:sessionId];
	[idleLine setMRecvCallState:true];
	[idleLine setMVideoState:existsVideo];
	[idleLine setCallTitle:[NSString stringWithUTF8String:callerDisplayName]];
	[idleLine setCallDetail:[NSString stringWithUTF8String:caller]];
	
	
	if ([UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground) {
		UILocalNotification* localNotif = [[UILocalNotification alloc] init];
		if (localNotif){
			localNotif.alertBody =[NSString  stringWithFormat:@"Call from <%s>%s", callerDisplayName,caller];
			localNotif.soundName = UILocalNotificationDefaultSoundName;
			localNotif.applicationIconBadgeNumber = 1;
			
			[[UIApplication sharedApplication]  presentLocalNotificationNow:localNotif];
		}
	}
	
// DO NOT DELETE
//	if(existsVideo)
//	{//video call
//		UIAlertView *alert = [[UIAlertView alloc]
//							  initWithTitle: @"Incoming Call"
//							  message: [NSString  stringWithFormat:@"Call from <%s>%s on line %d", callerDisplayName,caller,index]
//							  delegate: self
//							  cancelButtonTitle: @"Reject"
//							  otherButtonTitles:@"Answer", @"Video",nil];
////		alert.tag = index;
//		[alert show];
//	}
//	else
//	{
//		UIAlertView *alert = [[UIAlertView alloc]
//							  initWithTitle: @"Incoming Call"
//							  message: [NSString  stringWithFormat:@"Call from <%s>%s on line %d", callerDisplayName,caller,index]
//							  delegate: self
//							  cancelButtonTitle: @"Reject"
//							  otherButtonTitles:@"Answer", nil];
////		alert.tag = index;
//		[alert show];
//	}
	
	[[JCCallCardManager sharedManager] addIncomingCall:idleLine];
};

- (void)onInviteTrying:(long)sessionId
{
	NSLog(@"onInviteTrying - Session ID: %ld", sessionId);
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Call is trying on line %d",index]];
};

- (void)onInviteSessionProgress:(long)sessionId
					audioCodecs:(char*)audioCodecs
					videoCodecs:(char*)videoCodecs
			   existsEarlyMedia:(BOOL)existsEarlyMedia
					existsAudio:(BOOL)existsAudio
					existsVideo:(BOOL)existsVideo
{
	NSLog(@"onInviteSessionProgress - Session ID: %ld", sessionId);
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
	if (existsEarlyMedia)
	{
		// Checking does this call has video
		if (existsVideo)
		{
			// This incoming call has video
			// If more than one codecs using, then they are separated with "#",
			// for example: "g.729#GSM#AMR", "H264#H263", you have to parse them by yourself.
		}
		
		if (existsAudio)
		{
			// If more than one codecs using, then they are separated with "#",
			// for example: "g.729#GSM#AMR", "H264#H263", you have to parse them by yourself.
		}
	}
	
	[selectedLine setMExistEarlyMedia:existsEarlyMedia];
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Call session progress on line %d",index]];
}

- (void)onInviteRinging:(long)sessionId
			 statusText:(char*)statusText
			 statusCode:(int)statusCode
{
	NSLog(@"onInviteRinging - Session ID: %ld", sessionId);
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
	if (!selectedLine.mExistEarlyMedia)
	{
		// No early media, you must play the local WAVE file for ringing tone
	}
	
	[selectedLine setMCallState:JCCallRinging];
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Call ringing on line %d",index]];
}

- (void)onInviteAnswered:(long)sessionId
	   callerDisplayName:(char*)callerDisplayName
				  caller:(char*)caller
	   calleeDisplayName:(char*)calleeDisplayName
				  callee:(char*)callee
			 audioCodecs:(char*)audioCodecs
			 videoCodecs:(char*)videoCodecs
			 existsAudio:(BOOL)existsAudio
			 existsVideo:(BOOL)existsVideo
{
	
	NSLog(@"onInviveAnswered - Session ID: %ld", sessionId);
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
	// If more than one codecs using, then they are separated with "#",
	// for example: "g.729#GSM#AMR", "H264#H263", you have to parse them by yourself.
	// Checking does this call has video
//	if (existsVideo)
//	{
//		[videoViewController onStartVideo:sessionId];
//	}
	
	if (existsAudio)
	{
	}
	
	[selectedLine setMSessionState:true];
	[selectedLine setMVideoState:existsVideo];
	[selectedLine setMCallState:JCCallConnected];
	
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Call Established on line  %d",index]];
	
	// If this is the refer call then need set it to normal
	if (selectedLine.mIsReferCall)
	{
		[selectedLine setReferCall:false originalCallSessionId:0];
	}
	
	///todo: joinConference(index);
}

- (void)onInviteFailure:(long)sessionId
				 reason:(char*)reason
				   code:(int)code
{
	NSLog(@"onInviteFailure - Session ID: %ld", sessionId);
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Failed to call on line  %d,%s(%d)",index,reason,code]];
	
//	if (selectedLine.mIsReferCall)
//	{
//		// Take off the origin call from HOLD if the refer call is failure
//		long originIndex = -1;
//		for (int i=LINE_BASE; i<MAX_LINES; ++i)
//		{
//			// Looking for the origin call
//			if (mSessionArray[i].getSessionId() == mSessionArray[index].getOriginCallSessionId())
//			{
//				originIndex = i;
//				break;
//			}
//		}
//		
//		if (originIndex != -1)
//		{
////			[numpadViewController setStatusText:[NSString  stringWithFormat:@"Call failure on line  %d,%s(%d)",index,reason,code]];
//			
//			// Now take off the origin call
//			[_mPortSIPSDK unHold:mSessionArray[index].getOriginCallSessionId()];
//			
//			mSessionArray[originIndex].setHoldState(false);
//			
//			// Switch the currently line to origin call line
//			mActiveLine = originIndex;
//			
//			NSLog(@"Current line is: %ld",(long)mActiveLine);
//		}
//	}
	
//	mSessionArray[index].reset();
	[selectedLine reset];
}

- (void)onInviteUpdated:(long)sessionId
			audioCodecs:(char*)audioCodecs
			videoCodecs:(char*)videoCodecs
			existsAudio:(BOOL)existsAudio
			existsVideo:(BOOL)existsVideo
{
	NSLog(@"onInviteUpdated - Session ID: %ld", sessionId);
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
	// Checking does this call has video
//	if (existsVideo)
//	{
//		[videoViewController onStartVideo:sessionId];
//	}
	if (existsAudio)
	{
	}
	
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"The call has been updated on line %d",index]];
}

- (void)onInviteConnected:(long)sessionId
{
	NSLog(@"onInviteConnected - Session ID: %ld", sessionId);
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
	[selectedLine setMCallState:JCCallConnected];
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"The call is connected on line %d",index]];
}


- (void)onInviteBeginingForward:(char*)forwardTo
{
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Call has been forward to:%s" ,forwardTo]];
}

- (void)onInviteClosed:(long)sessionId
{
	NSLog(@"onInviteClosed - Session ID: %ld", sessionId);
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Call closed by remote on line %d",index]];
	
	[selectedLine setMCallState:JCCallCanceled];
	[selectedLine reset];
	
//	if (mSessionArray[index].getVideoState() == true) {
//		[videoViewController onStopVideo:sessionId];
//	}
}

- (void)onRemoteHold:(long)sessionId
{
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Placed on hold by remote on line %d",index]];
}

- (void)onRemoteUnHold:(long)sessionId
		   audioCodecs:(char*)audioCodecs
		   videoCodecs:(char*)videoCodecs
		   existsAudio:(BOOL)existsAudio
		   existsVideo:(BOOL)existsVideo
{
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Take off hold by remote on line  %d",index]];
}

#pragma mark - Transfer Events

//Transfer Event
- (void)onReceivedRefer:(long)sessionId
				referId:(long)referId
					 to:(char*)to
				   from:(char*)from
		referSipMessage:(char*)referSipMessage
{
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		[_mPortSIPSDK rejectRefer:referId];
		return;
	}
	
//	int referCallIndex = -1;
//	for (int i=LINE_BASE; i<MAX_LINES; ++i)
//	{
//		if (mSessionArray[i].getSessionState()==false && mSessionArray[i].getRecvCallState()==false)
//		{
//			mSessionArray[i].setSessionState(true);
//			referCallIndex = i;
//			break;
//		}
//	}
	
	JCLineSession *idleLine = [self findIdleLine];
	
	if (!idleLine)
	{
		[_mPortSIPSDK rejectRefer:referId];
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Received the refer on line %d, refer to %s",index,to]];
	
	//auto accept refer
	// Hold currently call after accepted the REFER
	
	[_mPortSIPSDK hold:selectedLine.mSessionId];
	[selectedLine setMHoldSate:true];
	
	long referSessionId = [_mPortSIPSDK acceptRefer:referId referSignaling:[NSString stringWithUTF8String:referSipMessage]];
	if (referSessionId <= 0)
	{
		[idleLine reset];
		// Take off the hold
		[_mPortSIPSDK unHold:selectedLine.mSessionId];
		[selectedLine setMHoldSate:false];
	}
	else
	{
		[idleLine setMSessionId:referSessionId];
		[idleLine setMSessionState:true];
		[idleLine setReferCall:true originalCallSessionId:selectedLine.mSessionId];
		
//		mSessionArray[referCallIndex].setSessionId(referSessionId);
//		mSessionArray[referCallIndex].setSessionState(true);
//		mSessionArray[referCallIndex].setReferCall(true, mSessionArray[index].getSessionId());
		
		// Set the refer call to active line
//		mActiveLine = referCallIndex;
		
//		[numpadViewController setStatusText:[NSString  stringWithFormat:@"Accepted the refer, new call is trying on line %d",referCallIndex]];
		
//		[self didSelectLine:mActiveLine];
	}
	
	
	/*if you want to reject Refer
	 [_mPortSIPSDK rejectRefer:referId];
	 mSessionArray[referCallIndex].reset();
	 [numpadViewController setStatusText:@"Rejected the the refer."];
	 */
}

- (void)onReferAccepted:(long)sessionId
{
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Line %d, the REFER was accepted.",index]];
}

- (void)onReferRejected:(long)sessionId reason:(char*)reason code:(int)code
{
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Line %d, the REFER was rejected.",index]];
}

- (void)onTransferTrying:(long)sessionId
{
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Transfer trying on line %d",index]];
}

- (void)onTransferRinging:(long)sessionId
{
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Transfer ringing on line %d",index]];
}

- (void)onACTVTransferSuccess:(long)sessionId
{
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Transfer succeeded on line %d",index]];
}

- (void)onACTVTransferFailure:(long)sessionId reason:(char*)reason code:(int)code
{
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Failed to transfer on line %d",index]];
}

//Signaling Event
- (void)onReceivedSignaling:(long)sessionId message:(char*)message
{
	// This event will be fired when the SDK received a SIP message
	// you can use signaling to access the SIP message.
}

- (void)onSendingSignaling:(long)sessionId message:(char*)message
{
	// This event will be fired when the SDK sent a SIP message
	// you can use signaling to access the SIP message.
}

- (void)onWaitingVoiceMessage:(char*)messageAccount
		urgentNewMessageCount:(int)urgentNewMessageCount
		urgentOldMessageCount:(int)urgentOldMessageCount
			  newMessageCount:(int)newMessageCount
			  oldMessageCount:(int)oldMessageCount
{
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Has voice messages,%s(%d,%d,%d,%d)",messageAccount,urgentNewMessageCount,urgentOldMessageCount,newMessageCount,oldMessageCount]];
}

- (void)onWaitingFaxMessage:(char*)messageAccount
	  urgentNewMessageCount:(int)urgentNewMessageCount
	  urgentOldMessageCount:(int)urgentOldMessageCount
			newMessageCount:(int)newMessageCount
			oldMessageCount:(int)oldMessageCount
{
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Has Fax messages,%s(%d,%d,%d,%d)",messageAccount,urgentNewMessageCount,urgentOldMessageCount,newMessageCount,oldMessageCount]];
}

- (void)onRecvDtmfTone:(long)sessionId tone:(int)tone
{
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Received DTMF tone: %d  on line %d",tone, index]];
}

- (void)onRecvOptions:(char*)optionsMessage
{
	NSLog(@"Received an OPTIONS message:%s",optionsMessage);
}

- (void)onRecvInfo:(char*)infoMessage
{
	NSLog(@"Received an INFO message:%s",infoMessage);
}

//Instant Message/Presence Event
- (void)onPresenceRecvSubscribe:(long)subscribeId
				fromDisplayName:(char*)fromDisplayName
						   from:(char*)from
						subject:(char*)subject
{
//	[imViewController onPresenceRecvSubscribe:subscribeId fromDisplayName:fromDisplayName from:from subject:subject];
}

- (void)onPresenceOnline:(char*)fromDisplayName
					from:(char*)from
			   stateText:(char*)stateText
{
//	[imViewController onPresenceOnline:fromDisplayName from:from
//							 stateText:stateText];
}


- (void)onPresenceOffline:(char*)fromDisplayName from:(char*)from
{
//	[imViewController onPresenceOffline:fromDisplayName from:from];
}


- (void)onRecvMessage:(long)sessionId
			 mimeType:(char*)mimeType
		  subMimeType:(char*)subMimeType
		  messageData:(unsigned char*)messageData
	messageDataLength:(int)messageDataLength
{
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Received a MESSAGE message on line %d",index]];
	
	
	if (strcmp(mimeType,"text") == 0 && strcmp(subMimeType,"plain") == 0)
	{
		NSString* recvMessage = [NSString stringWithUTF8String:(const char*)messageData];
		
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"recvMessage"
							  message: recvMessage
							  delegate: nil
							  cancelButtonTitle: @"OK"
							  otherButtonTitles:nil];
		[alert show];
	}
	else if (strcmp(mimeType,"application") == 0 && strcmp(subMimeType,"vnd.3gpp.sms") == 0)
	{
		// The messageData is binary data
	}
	else if (strcmp(mimeType,"application") == 0 && strcmp(subMimeType,"vnd.3gpp2.sms") == 0)
	{
		// The messageData is binary data
	}
}

- (void)onRecvOutOfDialogMessage:(char*)fromDisplayName
							from:(char*)from
				   toDisplayName:(char*)toDisplayName
							  to:(char*)to
						mimeType:(char*)mimeType
					 subMimeType:(char*)subMimeType
					 messageData:(unsigned char*)messageData
			   messageDataLength:(int)messageDataLength
{
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Received a message(out of dialog) from %s",from]];
	
	if (strcasecmp(mimeType,"text") == 0 && strcasecmp(subMimeType,"plain") == 0)
	{
		NSString* recvMessage = [NSString stringWithUTF8String:(const char*)messageData];
		
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:[NSString  stringWithUTF8String:from]
							  message: recvMessage
							  delegate: nil
							  cancelButtonTitle: @"OK"
							  otherButtonTitles:nil];
		[alert show];
	}
	else if (strcasecmp(mimeType,"application") == 0 && strcasecmp(subMimeType,"vnd.3gpp.sms") == 0)
	{
		// The messageData is binary data
	}
	else if (strcasecmp(mimeType,"application") == 0 && strcasecmp(subMimeType,"vnd.3gpp2.sms") == 0)
	{
		// The messageData is binary data
	}
}

- (void)onSendMessageSuccess:(long)sessionId messageId:(long)messageId
{
//	[imViewController onSendMessageSuccess:messageId];
}


- (void)onSendMessageFailure:(long)sessionId messageId:(long)messageId reason:(char*)reason code:(int)code
{
//	[imViewController onSendMessageFailure:messageId reason:reason code:code];
}

- (void)onSendOutOfDialogMessageSuccess:(long)messageId
						fromDisplayName:(char*)fromDisplayName
								   from:(char*)from
						  toDisplayName:(char*)toDisplayName
									 to:(char*)to
{
//	[imViewController onSendMessageSuccess:messageId];
}


- (void)onSendOutOfDialogMessageFailure:(long)messageId
						fromDisplayName:(char*)fromDisplayName
								   from:(char*)from
						  toDisplayName:(char*)toDisplayName
									 to:(char*)to
								 reason:(char*)reason
								   code:(int)code
{
//	[imViewController onSendMessageFailure:messageId reason:reason code:code];
}

#pragma mark - Other Events
//Play file event
- (void)onPlayAudioFileFinished:(long)sessionId fileName:(char*)fileName
{
	
}

- (void)onPlayVideoFileFinished:(long)sessionId
{
	
}

//RTP/Audio/video stream callback data
- (void)onReceivedRTPPacket:(long)sessionId isAudio:(BOOL)isAudio RTPPacket:(unsigned char *)RTPPacket packetSize:(int)packetSize
{
	/* !!! IMPORTANT !!!
	 
	 Don't call any PortSIP SDK API functions in here directly. If you want to call the PortSIP API functions or
	 other code which will spend long time, you should post a message to main thread(main window) or other thread,
	 let the thread to call SDK API functions or other code.
	 */
}

- (void)onSendingRTPPacket:(long)sessionId isAudio:(BOOL)isAudio RTPPacket:(unsigned char *)RTPPacket packetSize:(int)packetSize
{
	/* !!! IMPORTANT !!!
	 
	 Don't call any PortSIP SDK API functions in here directly. If you want to call the PortSIP API functions or
	 other code which will spend long time, you should post a message to main thread(main window) or other thread,
	 let the thread to call SDK API functions or other code.
	 */
}

- (void)onAudioRawCallback:(long)sessionId
		 audioCallbackMode:(int)audioCallbackMode
					  data:(unsigned char *)data
				dataLength:(int)dataLength
			samplingFreqHz:(int)samplingFreqHz
{
	/* !!! IMPORTANT !!!
	 
	 Don't call any PortSIP SDK API functions in here directly. If you want to call the PortSIP API functions or
	 other code which will spend long time, you should post a message to main thread(main window) or other thread,
	 let the thread to call SDK API functions or other code.
	 */
}

- (void)onVideoRawCallback:(long)sessionId
		 videoCallbackMode:(int)videoCallbackMode
					 width:(int)width
					height:(int)height
					  data:(unsigned char *)data
				dataLength:(int)dataLength
{
	/* !!! IMPORTANT !!!
	 
	 Don't call any PortSIP SDK API functions in here directly. If you want to call the PortSIP API functions or
	 other code which will spend long time, you should post a message to main thread(main window) or other thread,
	 let the thread to call SDK API functions or other code.
	 */
}

- (void)answerCall
{
	JCLineSession *currentLine = [self findLineWithRecevingState];
	if (currentLine) {
		int nRet = [_mPortSIPSDK answerCall:currentLine.mSessionId videoCall:FALSE];
		if(nRet == 0)
		{
			[currentLine setMSessionState:true];
			[currentLine setMVideoState:false];
		}
		else {
			[currentLine reset];
		}

	}
	
}


- (void)alertView: (UIAlertView *)alertView clickedButtonAtIndex: (NSInteger)buttonIndex
{
	JCLineSession *selectedLine = [self findLineWithRecevingState];
	if (selectedLine) {
		
		if(buttonIndex == 0){//reject Call
			[_mPortSIPSDK rejectCall:selectedLine.mSessionId code:486];
			
	//		[numpadViewController setStatusText:[NSString  stringWithFormat:@"Reject Call on line %d",index]];
		}
		else if (buttonIndex == 1){//Answer Call
			int nRet = [_mPortSIPSDK answerCall:selectedLine.mSessionId videoCall:FALSE];
			if(nRet == 0)
			{
				[selectedLine setMSessionState:true];
				[selectedLine setMVideoState:false];
//				mSessionArray[index].setSessionState(TRUE);
//				mSessionArray[index].setVideoState(FALSE);
				
	//			[numpadViewController setStatusText:[NSString  stringWithFormat:@"Answer Call on line %d",index]];
//				[self didSelectLine:index];
			}
			else
			{
				[selectedLine reset];
//				mSessionArray[index].reset();
	//			[numpadViewController setStatusText:[NSString  stringWithFormat:@"Answer Call on line %d Failed",index]];
			}
		}
		else if (buttonIndex == 2){//Answer Video Call
			int nRet = [_mPortSIPSDK answerCall:selectedLine.mSessionId videoCall:TRUE];
			if(nRet == 0)
			{
				[selectedLine setMSessionState:true];
				[selectedLine setMVideoState:true];

//				mSessionArray[index].setSessionState(TRUE);
//				mSessionArray[index].setVideoState(TRUE);
	//			[videoViewController onStartVideo:mSessionArray[index].getSessionId()];
	//			
	//			[numpadViewController setStatusText:[NSString  stringWithFormat:@"Answer Call on line %d",index]];
//				[self didSelectLine:index];
			}
			else
			{
				[selectedLine reset];
//				mSessionArray[index].reset();
	//			[numpadViewController setStatusText:[NSString  stringWithFormat:@"Answer Call on line %d Failed",index]];
			}
		}
	}
}
@end


@implementation SipHandler (Singleton)

+ (instancetype) sharedHandler
{
    static SipHandler *handler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handler = [[self alloc] init];
    });
    return handler;
}

+ (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
