//
//  SipHandler.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "SipHandler.h"
#import "JCLineSession.h"

@interface SipHandler()
{
	BOOL    SIPInitialized;
	BOOL    SIPRegistered;
}
- (JCLineSession *)findSession:(long)sessionId;
@property (nonatomic) NSMutableArray *lineSessions;
@end

#define ALERT_TAG_REFER 100
@implementation SipHandler
//@synthesize mActiveLine;


+ (instancetype) sharedHandler
{
	static SipHandler *handler = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		handler = [[self alloc] init];
		[handler initiate];
	});
	return handler;
}



- (void)initiate
{
	_lineSessions = [NSMutableArray new];
	for (int i = 0; i < 2; i++)
	{
		[_lineSessions addObject:[JCLineSession new]];
	}
	
	[self online];
}

- (void)online
{
	// TODO: get configuration from database
	NSString* kSipUserName = @"0147a20ad7f07eb6b0000100620005";
	NSString* kDisplayName = @"Eduardo Gueiros";
	NSString* kSipPassword = @"VWG2cmZADP84TIrZ";
	NSString* kSIPServer = @"reg.jiveip.net";
	NSString* kProxy = @"jive.jive.rtcfront.net";
	int kSIPServerPort = 5060;
	
	int ret = [mPortSIPSDK initialize:TRANSPORT_UDP loglevel:PORTSIP_LOG_DEBUG logPath:NULL maxLine:8 agent:@"Jive iOS Client" virtualAudioDevice:FALSE virtualVideoDevice:FALSE];
	if(ret != 0)
	{
		NSLog(@"initializeSDK failure ErrorCode = %d",ret);
		return ;
	}
	
	int localPort = 10000 + arc4random()%1000;
	NSString* loaclIPaddress = @"0.0.0.0";//Auto select IP address
	
	[mPortSIPSDK setUser:kSipUserName displayName:kDisplayName authName:kSipUserName password:kSipPassword localIP:loaclIPaddress localSIPPort:localPort userDomain:@"" SIPServer:kSIPServer SIPServerPort:kSIPServerPort STUNServer:@"" STUNServerPort:0 outboundServer:kProxy outboundServerPort:kSIPServerPort];

	int rt = [mPortSIPSDK setLicenseKey:kPortSIPKey];
	if (rt == ECoreTrialVersionLicenseKey)
	{
		
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Warning"
							  message: @"This trial version SDK just allows short conversation, you can't heairng anyting after 2-3 minutes, contact us: sales@portsip.com to buy official version."
							  delegate: self
							  cancelButtonTitle: @"OK"
							  otherButtonTitles:nil];
		[alert show];
	}
	else if (rt == ECoreWrongLicenseKey)
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Warning"
							  message: @"The wrong license key was detected, please check with sales@portsip.com or support@portsip.com"
							  delegate: self
							  cancelButtonTitle: @"OK"
							  otherButtonTitles:nil];
		[alert show];
	}
	
	//    [mPortSIPSDK addAudioCodec:AUDIOCODEC_PCMA];
	[mPortSIPSDK addAudioCodec:AUDIOCODEC_PCMU];
	//    [mPortSIPSDK addAudioCodec:AUDIOCODEC_SPEEX];
	[mPortSIPSDK addAudioCodec:AUDIOCODEC_G729];
	[mPortSIPSDK addAudioCodec:AUDIOCODEC_G722];
	
	//[mPortSIPSDK addAudioCodec:AUDIOCODEC_GSM];
	//[mPortSIPSDK addAudioCodec:AUDIOCODEC_ILBC];
	//[mPortSIPSDK addAudioCodec:AUDIOCODEC_AMR];
	//[mPortSIPSDK addAudioCodec:AUDIOCODEC_SPEEXWB];
	
	//[mPortSIPSDK addVideoCodec:VIDEO_CODEC_H263];
	//[mPortSIPSDK addVideoCodec:VIDEO_CODEC_H263_1998];
	[mPortSIPSDK addVideoCodec:VIDEO_CODEC_H264];
	
	[mPortSIPSDK setVideoBitrate:100];//video send bitrate,100kbps
	[mPortSIPSDK setVideoFrameRate:10];
	[mPortSIPSDK setVideoResolution:VIDEO_CIF];
	[mPortSIPSDK setAudioSamples:20 maxPtime:60];//ptime 20
	
	//1 - FrontCamra 0 - BackCamra
	[mPortSIPSDK setVideoDeviceId:1];
	//[mPortSIPSDK setVideoOrientation:180];
	
	//enable srtp
	[mPortSIPSDK setSrtpPolicy:SRTP_POLICY_NONE];
	
	// Try to register the default identity
	[mPortSIPSDK registerServer:120 retryTimes:3];
	
	NSString* sipURL = nil;
	if(kSIPServerPort == 5060) {
		sipURL = [[NSString alloc] initWithFormat:@"sip:%@:%@",kSipUserName,kSIPServer];
	}
	else {
		sipURL = [[NSString alloc] initWithFormat:@"sip:%@:%@:%d",kSipUserName,kSIPServer,kSIPServerPort];
	}
	
	SIPInitialized = YES;
}

- (void)offline
{
	if(SIPInitialized)
	{
		[mPortSIPSDK unRegisterServer];
		[mPortSIPSDK unInitialize];
		//[viewStatus setBackgroundColor:[UIColor redColor]];
		
		//[labelStatus setText:@"Not Connected"];
		//[labelDebugInfo setText:[NSString stringWithFormat: @"unRegisterServer"]];
		
		SIPRegistered = NO;
		SIPInitialized = NO;
	}
	//if([activityIndicator isAnimating])
	//	[activityIndicator stopAnimating];
};

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

- (void) pressNumpadButton:(char )dtmf
{
	JCLineSession *session = [self findLineWithSessionState];
	if(session && session.mSessionState)
	{
		[mPortSIPSDK sendDtmf:session.mSessionId dtmfMethod:DTMF_RFC2833 code:dtmf dtmfDration:160 playDtmfTone:TRUE];
	}
}

- (void) makeCall:(NSString*) callee
		videoCall:(BOOL)videoCall
{

	JCLineSession *currentSession = [self findLineWithSessionState];
	if (currentSession && currentSession.mSessionState && !currentSession.mHoldSate) {
		[mPortSIPSDK hold:currentSession.mSessionId];
	}
	
//	if(mSessionArray[mActiveLine].getSessionState() == true ||
//	   mSessionArray[mActiveLine].getRecvCallState() == true)
//	{
//		UIAlertView *alert = [[UIAlertView alloc]
//							  initWithTitle:@"Warning"
//							  message: @"Current line is busy now, please switch a line"
//							  delegate: nil
//							  cancelButtonTitle: @"OK"
//							  otherButtonTitles:nil];
//		[alert show];
//		
//		return;
//	}
	
	currentSession = [self findIdleLine];	
	
	long sessionId = [mPortSIPSDK call:callee sendSdp:TRUE videoCall:videoCall];
	
	if(sessionId >= 0)
	{
		[currentSession setMSessionId:sessionId];
		[currentSession setMSessionState:true];

		
//		mSessionArray[mActiveLine].setSessionId(sessionId);
//		mSessionArray[mActiveLine].setSessionState(true);
//		mSessionArray[mActiveLine].setVideoState(videoCall);
		
		//TODO:update call state
		
//		[numpadViewController setStatusText:[NSString  stringWithFormat:@"Calling:%@ on line %ld", callee, mActiveLine]];
	}
	else
	{
		//TODO:update call state
		[currentSession setMCallState:JCCallFailed];
//		[numpadViewController setStatusText:[NSString  stringWithFormat:@"make call failure ErrorCode =%ld", sessionId]];
	}
}

- (void) hangUpCall
{
	JCLineSession *selectedLine = [self findLineWithSessionState];
	if (selectedLine.mSessionState)
	{
		[mPortSIPSDK hangUp:selectedLine.mSessionId];
//		if (mSessionArray[mActiveLine].getVideoState() == true) {
//			[videoViewController onStopVideo:mSessionArray[mActiveLine].getSessionId()];
//		}
		
//		[numpadViewController setStatusText:[NSString  stringWithFormat:@"Hungup call on line %ld", mActiveLine]];
		
	}
	else if (selectedLine.mRecvCallState)
	{
		[mPortSIPSDK rejectCall:selectedLine.mSessionId code:486];
		
//		[numpadViewController setStatusText:[NSString  stringWithFormat:@"Rejected call on line %ld", mActiveLine]];
	}
	
	[selectedLine setMCallState:JCCallCanceled];
	[selectedLine reset];
}

- (void)toggleHoldForLineWithSessionId:(long)sessionId
{
	JCLineSession *selectedLine = [self findSession:sessionId];
	if (selectedLine.mHoldSate) {
		[mPortSIPSDK unHold:selectedLine.mSessionId];
		[selectedLine setMHoldSate:false];
	}
	else {
		[mPortSIPSDK hold:selectedLine.mSessionId];
		[selectedLine setMHoldSate:true];
	}
}

- (void) toggleHoldForCallWithSessionState
{
	JCLineSession *selectedLine = [self findLineWithSessionState];
	if (selectedLine.mHoldSate) {
		[mPortSIPSDK unHold:selectedLine.mSessionId];
		[selectedLine setMHoldSate:false];
	}
	else {
		[mPortSIPSDK hold:selectedLine.mSessionId];
		[selectedLine setMHoldSate:true];
	}
}

- (void) holdCall
{
	JCLineSession *selectedLine = [self findLineWithSessionState];
	if (!selectedLine)
	{
		return;
	}
	
	[mPortSIPSDK hold:selectedLine.mSessionId];
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
//	[mPortSIPSDK unHold:mSessionArray[mActiveLine].getSessionId()];
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
	
	int errorCodec = [mPortSIPSDK refer:selectedLine.mSessionId referTo:referTo];
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
		if(mute)
		{
			[mPortSIPSDK muteSession:selectedLine.mSessionState
				   muteIncomingAudio:TRUE
				   muteOutgoingAudio:TRUE
				   muteIncomingVideo:TRUE
				   muteOutgoingVideo:TRUE];
		}
		else
		{
			[mPortSIPSDK muteSession:selectedLine.mSessionState
				   muteIncomingAudio:FALSE
				   muteOutgoingAudio:FALSE
				   muteIncomingVideo:FALSE
				   muteOutgoingVideo:FALSE];
		}
	}
}

- (void)switchLines
{
	JCLineSession *activeLine = [self findLineWithSessionState];
	JCLineSession *lineOnHold = [self findLineWithHoldState];
	if (activeLine)
	{
		// Need to hold this line
		[mPortSIPSDK hold:activeLine.mSessionId];
		[activeLine setMHoldSate:true];
		
		//		[numpadViewController setStatusText:[NSString  stringWithFormat:@"Hold call on line %ld", mActiveLine]];
	}
	//	[numpadViewController.buttonLine setTitle:[NSString  stringWithFormat:@"Line%ld:", mActiveLine] forState:UIControlStateNormal];
	
	if (lineOnHold)
	{
		// Need to unhold this line
		[mPortSIPSDK unHold:lineOnHold.mSessionState];
		[activeLine setMHoldSate:false];
		
		//		[numpadViewController setStatusText:[NSString  stringWithFormat:@"unHold call on line %ld", mActiveLine]];
	}

}

- (void) setLoudspeakerStatus:(BOOL)enable
{
	[mPortSIPSDK setLoudspeakerStatus:enable];
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
//		[mPortSIPSDK hold:mSessionArray[mActiveLine].getSessionId()];
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
//		[mPortSIPSDK unHold:mSessionArray[mActiveLine].getSessionId()];
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

#pragma mark Registration Callback
//
//	sip callback events implementation
//
//Register Event
- (void)onRegisterSuccess:(char*) statusText statusCode:(int)statusCode

{
	mSIPRegistered = TRUE;
	//TODO:Announce didRegister
//	[loginViewController onRegisterSuccess:statusCode withStatusText:statusText];
};

- (void)onRegisterFailure:(char*) statusText statusCode:(int)statusCode
{
	mSIPRegistered = FALSE;
	//TODO:Announce didFailToRegister
//	[loginViewController onRegisterFailure:statusCode withStatusText:statusText];
};


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
//	int index = -1;
//	for (int i=0; i< MAX_LINES; ++i)
//	{
//		if (mSessionArray[i].getSessionState()==false && mSessionArray[i].getRecvCallState()==false)
//		{
//			mSessionArray[i].setRecvCallState(true);
//			index = i;
//			break;
//		}
//	}
	
	JCLineSession *idleLine = [self findIdleLine];
	
	if (!idleLine)
	{
		[mPortSIPSDK rejectCall:sessionId code:486];
		return ;
	}
	
	[idleLine setMSessionId:sessionId];
	[idleLine setMRecvCallState:true];

//	mSessionArray[index].setVideoState(existsVideo);
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Incoming call:%s on line %d",caller, index]];
	
	if ([UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground) {
		UILocalNotification* localNotif = [[UILocalNotification alloc] init];
		if (localNotif){
			localNotif.alertBody =[NSString  stringWithFormat:@"Call from <%s>%s", callerDisplayName,caller];
			localNotif.soundName = UILocalNotificationDefaultSoundName;
			localNotif.applicationIconBadgeNumber = 1;
			
			[[UIApplication sharedApplication]  presentLocalNotificationNow:localNotif];
		}
	}
	
	if(existsVideo)
	{//video call
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle: @"Incoming Call"
							  message: [NSString  stringWithFormat:@"Call from <%s>%s on line %d", callerDisplayName,caller,index]
							  delegate: self
							  cancelButtonTitle: @"Reject"
							  otherButtonTitles:@"Answer", @"Video",nil];
//		alert.tag = index;
		[alert show];
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle: @"Incoming Call"
							  message: [NSString  stringWithFormat:@"Call from <%s>%s on line %d", callerDisplayName,caller,index]
							  delegate: self
							  cancelButtonTitle: @"Reject"
							  otherButtonTitles:@"Answer", nil];
//		alert.tag = index;
		[alert show];
	}
};

- (void)onInviteTrying:(long)sessionId
{
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
//			[mPortSIPSDK unHold:mSessionArray[index].getOriginCallSessionId()];
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
		[mPortSIPSDK rejectRefer:referId];
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
		[mPortSIPSDK rejectRefer:referId];
		return;
	}
	
//	[numpadViewController setStatusText:[NSString  stringWithFormat:@"Received the refer on line %d, refer to %s",index,to]];
	
	//auto accept refer
	// Hold currently call after accepted the REFER
	
	[mPortSIPSDK hold:selectedLine.mSessionId];
	[selectedLine setMHoldSate:true];
	
	long referSessionId = [mPortSIPSDK acceptRefer:referId referSignaling:[NSString stringWithUTF8String:referSipMessage]];
	if (referSessionId <= 0)
	{
		[idleLine reset];
		// Take off the hold
		[mPortSIPSDK unHold:selectedLine.mSessionId];
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
	 [mPortSIPSDK rejectRefer:referId];
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


- (void)alertView: (UIAlertView *)alertView clickedButtonAtIndex: (NSInteger)buttonIndex
{
	JCLineSession *selectedLine = [self findLineWithRecevingState];
	if (selectedLine) {
		
		if(buttonIndex == 0){//reject Call
			[mPortSIPSDK rejectCall:selectedLine.mSessionId code:486];
			
	//		[numpadViewController setStatusText:[NSString  stringWithFormat:@"Reject Call on line %d",index]];
		}
		else if (buttonIndex == 1){//Answer Call
			int nRet = [mPortSIPSDK answerCall:selectedLine.mSessionId videoCall:FALSE];
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
			int nRet = [mPortSIPSDK answerCall:selectedLine.mSessionId videoCall:TRUE];
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
