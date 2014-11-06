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
#import "IncomingCall.h"
#import "MissedCall.h"
#import "OutgoingCall.h"
#import "Common.h"

#import "LineConfiguration+Custom.h"
#import "Lines+Custom.h"
#import "PBX+Custom.h"
#import "VideoViewController.h"


#ifdef __APPLE__
#include "TargetConditionals.h"
#endif

#define MAX_LINES 2
#define ALERT_TAG_REFER 100
#define OUTBOUND_SIP_SERVER_PORT 5061


NSString *const kSipHandlerServerAgentname = @"Jive iOS Client";
NSString *const kSipHandlerFetchLineConfigurationErrorMessage = @"Unable to fetch the line configuration";
NSString *const kSipHandlerFetchPBXErrorMessage = @"Unable to fetch the line configuration";
NSString *const kSipHandlerRegisteredSelectorKey = @"registered";

@interface SipHandler() <PortSIPEventDelegate>
{
    PortSIPSDK *_mPortSIPSDK;
    CompletionHandler _connectionCompletionHandler;
    AFNetworkReachabilityStatus _previousNetworkStatus;
	VideoViewController *_videoController;
	bool inConference;
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
        {
            return self;
        }
    
        _lineSessions = [NSMutableArray new];
        for (int i = 0; i < MAX_LINES; i++)
            [_lineSessions addObject:[JCLineSession new]];
        
        _mPortSIPSDK = [[PortSIPSDK alloc] init];
        _mPortSIPSDK.delegate = self;
		
		_videoController = [VideoViewController new];
        
        // Register to listen for AFNetworkReachability Changes.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(networkConnectivityChanged:) name:AFNetworkingReachabilityDidChangeNotification  object:nil];
        _previousNetworkStatus = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
        
        [self connect:NULL];
    }
    return self;
}

#pragma mark - Device Registration -

-(void)connect:(CompletionHandler)completionHandler;
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
	
	bool isSimulator = FALSE;
#if TARGET_IPHONE_SIMULATOR
	isSimulator = TRUE;
#elif TARGET_OS_IPHONE
	isSimulator = FALSE;
#endif
    
    // Initialized the SIP SDK
    int ret = [_mPortSIPSDK initialize:TRANSPORT_UDP
                              loglevel:PORTSIP_LOG_DEBUG
                               logPath:NULL
                               maxLine:MAX_LINES
                                 agent:kSipHandlerServerAgentname
                    virtualAudioDevice:isSimulator
                    virtualVideoDevice:isSimulator];
    
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
        for (JCLineSession *lineSession in _lineSessions) {
            [self hangUpSession:lineSession completion:NULL];
        }
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
                [self connect:NULL];
            break;
        }
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
			!line.isHolding &&
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
			line.isHolding &&
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

- (JCLineSession *) makeCall:(NSString *)dialString
		videoCall:(BOOL)videoCall contactName:(NSString *)contactName;
{
	JCLineSession *lineSession = [self findIdleLine];
    if (!lineSession) {
        return nil;
    }
	
	long sessionId = [_mPortSIPSDK call:dialString sendSdp:TRUE videoCall:videoCall];
	if(sessionId >= 0)
	{
		[lineSession setMSessionId:sessionId];
		[lineSession setMSessionState:YES];
		
		[lineSession setCallTitle:contactName ? contactName : dialString];
		[lineSession setCallDetail:dialString];
        [OutgoingCall addOutgoingCallWithLineSession:lineSession];
	}
	else
	{
        NSError *error = [Common createErrorWithDescription:NSLocalizedString(@"Call Failed", nil) reason:NSLocalizedString(@"Unable to create call", nil) code:sessionId];
        [self setSessionState:JCCallFailed forSession:lineSession event:@"makeCall:" error:error];
	}
    
	return lineSession;
}

- (void)answerSession:(JCLineSession *)lineSession completion:(CompletionHandler)completion
{
    if (!lineSession)
        return;
    
    int error = [_mPortSIPSDK answerCall:lineSession.mSessionId videoCall:FALSE];
    if(error == 0)
    {
        if (lineSession.mRecvCallState) {
            [IncomingCall addIncommingCallWithLineSession:lineSession];
        }
        
        [lineSession setMSessionState:true];
        [lineSession setMRecvCallState:false];
        [lineSession setMVideoState:false];
        
        if (completion != NULL) {
            completion(true, nil);
        }
    }
    else {
        if (completion != NULL) {
            completion(false, [NSError errorWithDomain:@"Unable to answer the call" code:error userInfo:nil]);
        }
        [lineSession reset];
    }
}

- (void)hangUpSession:(JCLineSession *)lineSession completion:(CompletionHandler)completion
{
    if (lineSession.mSessionState)
    {
        int error = [_mPortSIPSDK hangUp:lineSession.mSessionId];
        if (error == 0) {
            if (completion != NULL) {
                completion(true, nil);
            }
            [lineSession reset];
        }
        else
        {
            if (completion != NULL) {
                completion(false, [NSError errorWithDomain:@"Error T=r0yin0g to Hange up" code:error userInfo:nil]);
            }
        }
    }
    else if (lineSession.mRecvCallState)
    {
        int error = [_mPortSIPSDK rejectCall:lineSession.mSessionId code:486];
        if (error == 0) {
            if (completion != NULL) {
                completion(true, nil);
            }
            [MissedCall addMissedCallWithLineSession:lineSession];
            [lineSession reset];
        }
        else
        {
            if (completion != NULL) {
                completion(false, [NSError errorWithDomain:@"Error Trying to reject Call" code:error userInfo:nil]);
            }
        }
    }
}

- (void)switchLines
{
    JCLineSession *activeLine = [self findLineWithSessionState];
    JCLineSession *lineOnHold = [self findLineWithHoldState];
    
    [self setHoldCallState:true forSessionId:activeLine.mSessionId];
    [self setHoldCallState:false forSessionId:lineOnHold.mSessionId];
}

- (void)setHoldCallState:(bool)hold forSessionId:(long)sessionId
{
    JCLineSession *lineSession = [self findSession:sessionId];
    if (lineSession)
    {
        if (hold)
        {
            [_mPortSIPSDK hold:lineSession.mSessionId];
        }
        else
        {
            [_mPortSIPSDK unHold:lineSession.mSessionId];
        }
        lineSession.hold = hold;
    }
}

- (void) toggleHoldForCallWithSessionState
{
	JCLineSession *lineSession = [self findLineWithSessionState];
	if (!lineSession) {
		lineSession = [self findLineWithHoldState];
	}
	
	if (lineSession.isHolding) {
		[_mPortSIPSDK unHold:lineSession.mSessionId];
        lineSession.hold = NO;
	}
	else {
		[_mPortSIPSDK hold:lineSession.mSessionId];
        lineSession.hold = YES;
	}
}

- (void) referCall:(NSString *)referTo completion:(void (^)(bool success, NSError *error))completion
{
    _transferCompleted = completion;
    
	JCLineSession *currentLine = [self findLineWithSessionState];
	if (!currentLine || currentLine.mSessionState == false)
	{
        _transferCompleted(false, [NSError errorWithDomain:@"Need to make the call established first" code:0 userInfo:nil]);
		return;
	}
	
	int result = [_mPortSIPSDK refer:currentLine.mSessionId referTo:referTo];
    if (!result) {
        return;
    }
    
    NSString *msg = NSLocalizedString(@"Blind Transfer failed", nil);
    NSError *error = [Common createErrorWithDescription:msg
                                                 reason:NSLocalizedString(@"Unable make transfer", nil)
                                                   code:result];

    [self setSessionState:JCTransferFailed forSession:currentLine event:msg error:error];
	_transferCompleted(false, [NSError errorWithDomain:msg code:0 userInfo:nil]);
    
    return;
}

- (void)attendedRefer:(NSString *)referTo completion:(void (^)(bool success, NSError *error))completion
{
    _transferCompleted = completion;
    
	JCLineSession *currentLine = [self findLineWithSessionState];
    if (!currentLine || currentLine.mSessionState == false)
    {
        _transferCompleted(false, [NSError errorWithDomain:@"Need to make the call established first" code:0 userInfo:nil]);
        return;
    }
    
	JCLineSession *replaceSession = [self findLineWithHoldState];
    if (replaceSession && !replaceSession.mSessionState) {
        _transferCompleted(false, [NSError errorWithDomain:@"Unable to find replace session" code:0 userInfo:nil]);
        return;
    }
		
    int result = [_mPortSIPSDK attendedRefer:currentLine.mSessionId replaceSessionId:replaceSession.mSessionId referTo:referTo];
    if (!result) {
        return;
    }
	
    NSString *msg = NSLocalizedString(@"Warm Tranfer failed", nil);
    NSError *error = [Common createErrorWithDescription:msg
                                                 reason:NSLocalizedString(@"Unable make transfer", nil)
                                                   code:result];
    
    [self setSessionState:JCTransferFailed forSession:currentLine event:msg error:error];
    currentLine.sessionState = JCTransferFailed;
    _transferCompleted(false, error);
}

- (void) muteCall:(BOOL)mute
{
    
    [_mPortSIPSDK muteMicrophone:mute];
    
// For the MVP the call above suffices. For more advanced control over earch session
// the code below might come in handy.
    
//    if (!inConference) {
//        JCLineSession *selectedLine = [self findLineWithSessionState];
//        
//        if(selectedLine.mSessionState){
//            [_mPortSIPSDK muteSession:selectedLine.mSessionState
//                    muteIncomingAudio:FALSE
//                    muteOutgoingAudio:mute == YES ? TRUE : FALSE
//                    muteIncomingVideo:FALSE
//                    muteOutgoingVideo:mute == YES ? TRUE : FALSE];
//        }
//    }
//    else {
//        for (JCLineSession *line in self.lineSessions)
//        {
//            if (line.mSessionState)
//            {
//                [_mPortSIPSDK muteSession:line.mSessionState
//                        muteIncomingAudio:FALSE
//                        muteOutgoingAudio:mute == YES ? TRUE : FALSE
//                        muteIncomingVideo:FALSE
//                        muteOutgoingVideo:mute == YES ? TRUE : FALSE];            }
//        }
//    }
	
}

- (bool)setConference:(bool)conference
{
	if (conference)
	{
		int rt = [_mPortSIPSDK createConference:[UIView new] videoResolution:VIDEO_NONE displayLocalVideo:NO];
		if (rt == 0) {
			for (JCLineSession *line in self.lineSessions)
			{
				if (line.mSessionState)
				{
					if (line.isHolding)
					{
						[_mPortSIPSDK unHold:line.mSessionId];
						line.hold = false;
					}
					
					[_mPortSIPSDK joinToConference:line.mSessionId];
				}
			}
			
			inConference = true;
		}
		else
		{
			// failed to create conference
			inConference = false;
		}
	}
	else if (inConference)
	{
		inConference = false;
		// Before stop the conference, MUST place all lines to hold state
		for (JCLineSession *line in self.lineSessions)
		{
			if (line.mSessionState && !line.isHolding )
			{
				[_mPortSIPSDK hold:line.mSessionId];
				line.hold = true;
			}
		}
		
		[_mPortSIPSDK destroyConference];
	}
	
	return inConference;
}

- (void) setLoudspeakerStatus:(BOOL)enable
{
	[_mPortSIPSDK setLoudspeakerStatus:enable];
}

#pragma mark - Private -

-(void)setSessionState:(JCLineSessionState)state forSession:(JCLineSession *)lineSession event:(NSString *)event error:(NSError *)error
{
    if (!lineSession)
        return;
    
    
    NSLog(@"%@ Session Id: %ld", event, lineSession.mSessionId);
    switch (state)
    {
        case JCTransferSuccess:
            lineSession.sessionState = state;
            if (_transferCompleted) {
                _transferCompleted(YES, error);
                _transferCompleted = nil;
            }
            break;
        case JCCallCanceled:
        {
            if (lineSession.mRecvCallState)
            {
                [MissedCall addMissedCallWithLineSession:lineSession];
            }
        }
        case JCInviteFailure:
        case JCCallFailed:
        case JCTransferFailed:
            if (_transferCompleted) {
                _transferCompleted(NO, error);
                _transferCompleted = nil;
            }
            else {
                [self.delegate removeLineSession:lineSession];
                [lineSession reset];
            }
            break;
        default:
            lineSession.sessionState = state;
            break;
    }
}

-(void)setSessionState:(JCLineSessionState)state forSessionId:(long)sessionId event:(NSString *)event error:(NSError *)error
{
    [self setSessionState:state forSession:[self findSession:sessionId] event:event error:error];
}

#pragma mark - Delegate Handlers -

#pragma mark Call Events

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
    
    
    
    [idleLine setCallTitle:[NSString stringWithUTF8String:callerDisplayName]];
    NSString *newDetail = (NSString *)idleLine.callDetail;
    NSRange stripRange = [newDetail rangeOfString:@"@"];
    
    NSRange striped = NSMakeRange(stripRange.location, (newDetail.length - stripRange.location));
    newDetail = [newDetail stringByReplacingCharactersInRange:striped withString:@""];
    
    NSRange finalrange = NSMakeRange(4, newDetail.length-4);
    newDetail = [newDetail substringWithRange:finalrange];
    [idleLine setCallDetail:newDetail];
    
    // Notify delegate to add a line session.
    [self.delegate addLineSession:idleLine];
    
    [self setSessionState:JCInvite forSession:idleLine event:@"onInviteIncoming" error:nil];
};

- (void)onInviteTrying:(long)sessionId
{
	[self setSessionState:JCInviteTrying forSessionId:sessionId event:@"onInviteTrying" error:nil];
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
    
    [self setSessionState:JCInviteProgress forSession:selectedLine event:@"onInviteSessionProgress" error:nil] ;
}

- (void)onInviteRinging:(long)sessionId
			 statusText:(char*)statusText
			 statusCode:(int)statusCode
{
    JCLineSession *selectedLine = [self findSession:sessionId];
	if (selectedLine && !selectedLine.mExistEarlyMedia)
    {
        // No early media, you must play the local WAVE file for ringing tone
	}
    [self setSessionState:JCCallRinging forSession:selectedLine event:@"onInviteRinging" error:nil];
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
	
	/*if (existsAudio)
	{
        
	}*/
	
	[selectedLine setMSessionState:true];
	[selectedLine setMVideoState:existsVideo];
	
	// If this is the refer call then need set it to normal
	if (selectedLine.mIsReferCall)
	{
		[selectedLine setReferCall:false originalCallSessionId:0];
	}
    
    [self setSessionState:JCCallConnected forSession:selectedLine event:@"onInviteAnswered" error:nil];
}

- (void)onInviteFailure:(long)sessionId reason:(char*)reason code:(int)code
{
    NSString *event = [NSString stringWithFormat:@"onInviteFailure reason: %@ code: %i", [NSString stringWithCString:reason encoding:NSUTF8StringEncoding], code];
    
    NSError *error = [Common createErrorWithDescription:event
                                                 reason:[NSString stringWithUTF8String:reason]
                                                   code:code];
    
    [self setSessionState:JCInviteFailure forSessionId:sessionId event:event error:error];
}

- (void)onInviteConnected:(long)sessionId
{
    [self setSessionState:JCCallConnected forSessionId:sessionId event:@"onInviteConnected" error:nil];
}

- (void)onInviteClosed:(long)sessionId
{
    [self setSessionState:JCCallCanceled forSessionId:sessionId event:@"onInviteClosed" error:nil];
}

#pragma mark Not Implemented

- (void)onInviteUpdated:(long)sessionId
            audioCodecs:(char*)audioCodecs
            videoCodecs:(char*)videoCodecs
            existsAudio:(BOOL)existsAudio
            existsVideo:(BOOL)existsVideo
{
    // TODO: Implement.
    
    // NSLog(@"onInviteUpdated - Session ID: %ld", sessionId);
    // Checking does this call has video
    //	if (existsVideo)
    //	{
    //		[videoViewController onStartVideo:sessionId];
    //	}
    //  if (existsAudio)
    //  {
    //  }
}

- (void)onInviteBeginingForward:(char*)forwardTo
{
    // TODO: Implement.
}

- (void)onRemoteHold:(long)sessionId
{
    // TODO: Implement.
}

- (void)onRemoteUnHold:(long)sessionId audioCodecs:(char*)audioCodecs videoCodecs:(char*)videoCodecs existsAudio:(BOOL)existsAudio existsVideo:(BOOL)existsVideo
{
	// TODO: Implement.
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
	
	JCLineSession *idleLine = [self findIdleLine];
	
	if (!idleLine)
	{
		[_mPortSIPSDK rejectRefer:referId];
		return;
	}
	
	//auto accept refer
	// Hold currently call after accepted the REFER
    [_mPortSIPSDK hold:selectedLine.mSessionId];
    selectedLine.hold = true;
    
	long referSessionId = [_mPortSIPSDK acceptRefer:referId referSignaling:[NSString stringWithUTF8String:referSipMessage]];
	if (referSessionId <= 0)
	{
		[idleLine reset];
		[_mPortSIPSDK unHold:selectedLine.mSessionId];
        selectedLine.hold = false;
	}
	else
	{
		[idleLine setMSessionId:referSessionId];
		[idleLine setMSessionState:true];
		[idleLine setReferCall:true originalCallSessionId:selectedLine.mSessionId];
	}
}

- (void)onACTVTransferSuccess:(long)sessionId
{
    //[self setSessionState:JCTransferSuccess forSessionId:sessionId event:@"onACTVTransferSuccess" error:nil];
}

- (void)onACTVTransferFailure:(long)sessionId reason:(char*)reason code:(int)code
{
    NSString *event = [NSString stringWithFormat:@"onACTVTransferFailure reason: %@ code: %i", [NSString stringWithCString:reason encoding:NSUTF8StringEncoding], code];
    
    NSError *error = [Common createErrorWithDescription:event
                                                 reason:[NSString stringWithUTF8String:reason]
                                                   code:code];
    
    [self setSessionState:JCTransferFailed forSessionId:sessionId event:event error:error];
}

#pragma mark Not Implemented

- (void)onReferAccepted:(long)sessionId
{
    NSLog(@"%li", sessionId);
    [self setSessionState:JCTransferSuccess forSessionId:sessionId event:@"onACTVTransferSuccess" error:nil];
}

- (void)onReferRejected:(long)sessionId reason:(char*)reason code:(int)code
{
    NSLog(@"%li", sessionId);
}

- (void)onTransferTrying:(long)sessionId
{
    NSLog(@"%li", sessionId);
}

- (void)onTransferRinging:(long)sessionId
{
    NSLog(@"%li", sessionId);
}

- (void)onReceivedSignaling:(long)sessionId message:(char*)message
{
	// TODO: Implement.
    
    // This event will be fired when the SDK received a SIP message
	// you can use signaling to access the SIP message.
}

- (void)onSendingSignaling:(long)sessionId message:(char*)message
{
	// TODO: Implement.
    
    // This event will be fired when the SDK sent a SIP message
	// you can use signaling to access the SIP message.
}

- (void)onWaitingVoiceMessage:(char*)messageAccount
		urgentNewMessageCount:(int)urgentNewMessageCount
		urgentOldMessageCount:(int)urgentOldMessageCount
			  newMessageCount:(int)newMessageCount
			  oldMessageCount:(int)oldMessageCount
{
    // TODO: Implement.
}

- (void)onWaitingFaxMessage:(char*)messageAccount
	  urgentNewMessageCount:(int)urgentNewMessageCount
	  urgentOldMessageCount:(int)urgentOldMessageCount
			newMessageCount:(int)newMessageCount
			oldMessageCount:(int)oldMessageCount
{
    // TODO: Implement.
}

- (void)onRecvDtmfTone:(long)sessionId tone:(int)tone
{
	// TODO: Implement.
}

- (void)onRecvOptions:(char*)optionsMessage
{
	// TODO: Implement.
    
    //NSLog(@"Received an OPTIONS message:%s",optionsMessage);
}

- (void)onRecvInfo:(char*)infoMessage
{
	// TODO: Implement.
    
    //NSLog(@"Received an INFO message:%s",infoMessage);
}

#pragma mark - Messaging / Presence -

//Instant Message/Presence Event
- (void)onPresenceRecvSubscribe:(long)subscribeId
				fromDisplayName:(char*)fromDisplayName
						   from:(char*)from
						subject:(char*)subject
{
    // TODO: Implement.
}

- (void)onPresenceOnline:(char*)fromDisplayName
					from:(char*)from
			   stateText:(char*)stateText
{
    // TODO: Implement.
}


- (void)onPresenceOffline:(char*)fromDisplayName from:(char*)from
{
    // TODO: Implement.
}

- (void)onRecvMessage:(long)sessionId
			 mimeType:(char*)mimeType
		  subMimeType:(char*)subMimeType
		  messageData:(unsigned char*)messageData
	messageDataLength:(int)messageDataLength
{
	// TODO: Implement.
    
    /*JCLineSession *selectedLine = [self findSession:sessionId];
	if (!selectedLine)
	{
		return;
	}
	
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
	}*/
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
	// TODO: Implement.
    
    /*if (strcasecmp(mimeType,"text") == 0 && strcasecmp(subMimeType,"plain") == 0)
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
	}*/
}

- (void)onSendMessageSuccess:(long)sessionId messageId:(long)messageId
{
    // TODO: Implement.
}


- (void)onSendMessageFailure:(long)sessionId messageId:(long)messageId reason:(char*)reason code:(int)code
{
    // TODO: Implement.
}

- (void)onSendOutOfDialogMessageSuccess:(long)messageId
						fromDisplayName:(char*)fromDisplayName
								   from:(char*)from
						  toDisplayName:(char*)toDisplayName
									 to:(char*)to
{
    // TODO: Implement.
}


- (void)onSendOutOfDialogMessageFailure:(long)messageId
						fromDisplayName:(char*)fromDisplayName
								   from:(char*)from
						  toDisplayName:(char*)toDisplayName
									 to:(char*)to
								 reason:(char*)reason
								   code:(int)code
{
    // TODO: Implement.
}

#pragma mark - Other Events -

//Play file event
- (void)onPlayAudioFileFinished:(long)sessionId fileName:(char*)fileName
{
	// TODO: Implement.
}

- (void)onPlayVideoFileFinished:(long)sessionId
{
	// TODO: Implement.
}

//RTP/Audio/video stream callback data
- (void)onReceivedRTPPacket:(long)sessionId isAudio:(BOOL)isAudio RTPPacket:(unsigned char *)RTPPacket packetSize:(int)packetSize
{
	// TODO: Implement.
    
    /* !!! IMPORTANT !!!
	 
	 Don't call any PortSIP SDK API functions in here directly. If you want to call the PortSIP API functions or
	 other code which will spend long time, you should post a message to main thread(main window) or other thread,
	 let the thread to call SDK API functions or other code.
	 */
}

- (void)onSendingRTPPacket:(long)sessionId isAudio:(BOOL)isAudio RTPPacket:(unsigned char *)RTPPacket packetSize:(int)packetSize
{
	// TODO: Implement.
    
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
	// TODO: Implement.
    
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
	// TODO: Implement.
    
    /* !!! IMPORTANT !!!
	 
	 Don't call any PortSIP SDK API functions in here directly. If you want to call the PortSIP API functions or
	 other code which will spend long time, you should post a message to main thread(main window) or other thread,
	 let the thread to call SDK API functions or other code.
	 */
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
