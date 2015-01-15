//
//  SipHandler.m
//  JiveOne
//
//  The Sip Handler server as a wrapper to the port sip SDK and manages Line Session objects.
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "SipHandler.h"
#import "Common.h"
#import "JCAppSettings.h"
#import "JCSipHandlerError.h"

#ifdef __APPLE__
#include "TargetConditionals.h"
#endif

// Libraries
#import <PortSIPLib/PortSIPSDK.h>
#import <AVFoundation/AVFoundation.h>

// Managers
#import "JCBadgeManager.h"   // Sip directly reports voicemail count for v4 clients to badge manager

// Managed Objects
#import "IncomingCall.h"
#import "MissedCall.h"
#import "OutgoingCall.h"
#import "LineConfiguration.h"
#import "Line.h"
#import "PBX.h"

// View Controllers
#import "VideoViewController.h"

#define ALERT_TAG_REFER 100
#define OUTBOUND_SIP_SERVER_PORT 5061
#define AUTO_ANSWER_CHECK_COUNT 3

#if DEBUG
#define LOG_LEVEL PORTSIP_LOG_DEBUG
#else
#define LOG_LEVEL PORTSIP_LOG_NONE
#endif

#if TARGET_IPHONE_SIMULATOR
#define IS_SIMULATOR TRUE
#elif TARGET_OS_IPHONE
#define IS_SIMULATOR FALSE
#endif

NSString *const kSipHandlerAutoAnswerModeAutoHeader = @"Answer-Mode: auto";
NSString *const kSipHandlerAutoAnswerInfoIntercomHeader = @"Alert-Info: Intercom";
NSString *const kSipHandlerAutoAnswerAfterIntervalHeader = @"answer-after=0";

NSString *const kSipHandlerServerAgentname = @"Jive iOS Client";
NSString *const kSipHandlerLineErrorMessage = @"Unable to fetch the line configuration";
NSString *const kSipHandlerFetchPBXErrorMessage = @"Unable to fetch the line configuration";
NSString *const kSipHandlerRegisteredSelectorKey = @"registered";

@interface SipHandler() <PortSIPEventDelegate>
{
    PortSIPSDK *_mPortSIPSDK;
    CompletionHandler _connectionCompletionHandler;
    CompletionHandler _transferCompletionHandler;
	VideoViewController *_videoController;
	bool inConference;
	bool autoAnswer;
}

@property (nonatomic) NSMutableArray *lineSessions;

- (JCLineSession *)findSession:(long)sessionId;

@end

@implementation SipHandler

-(instancetype)initWithNumberOfLines:(NSInteger)lines delegate:(id<SipHandlerDelegate>)delegate error:(NSError *__autoreleasing *)error;
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        
        _lineSessions = [NSMutableArray new];
        for (int i = 0; i < lines; i++)
            [_lineSessions addObject:[JCLineSession new]];
        
        // Initialize the port sip sdk.
        _mPortSIPSDK = [PortSIPSDK new];
        _mPortSIPSDK.delegate = self;
        int errorCode = [_mPortSIPSDK initialize:TRANSPORT_UDP
                                  loglevel:LOG_LEVEL
                                   logPath:NULL
                                   maxLine:(int)lines
                                     agent:kSipHandlerServerAgentname
                        virtualAudioDevice:IS_SIMULATOR
                        virtualVideoDevice:IS_SIMULATOR];
        
        if(errorCode) {
            _mPortSIPSDK = nil;
            _lineSessions = nil;
            *error = [JCSipHandlerError errorWithCode:errorCode reason:@"Error initializing port sip sdk"];
            return self;
        }
        
        // Check License Key
        errorCode = [_mPortSIPSDK setLicenseKey:kPortSIPKey];
        if(errorCode) {
            [_mPortSIPSDK unInitialize];
            _mPortSIPSDK = nil;
            _lineSessions = nil;
            *error = [JCSipHandlerError errorWithCode:errorCode reason:@"Port Sip License Key Failure"];
            return self;
        }
        
        // Configure codecs. These return error codes, but are not critical if they fail.
        
        // Used Audio Codecs
        [_mPortSIPSDK addAudioCodec:AUDIOCODEC_PCMU];
        [_mPortSIPSDK addAudioCodec:AUDIOCODEC_G729];
        [_mPortSIPSDK addAudioCodec:AUDIOCODEC_G722];
        
        // Not used Audio Codecs
        //[_mPortSIPSDK addAudioCodec:AUDIOCODEC_SPEEX];
        //[_mPortSIPSDK addAudioCodec:AUDIOCODEC_PCMA];
        //[_mPortSIPSDK addAudioCodec:AUDIOCODEC_GSM];
        //[_mPortSIPSDK addAudioCodec:AUDIOCODEC_ILBC];
        //[_mPortSIPSDK addAudioCodec:AUDIOCODEC_AMR];
        //[_mPortSIPSDK addAudioCodec:AUDIOCODEC_SPEEXWB];
        
        // Used Video Codecs
        [_mPortSIPSDK addVideoCodec:VIDEO_CODEC_H264];
        
        // Not Used Video Codecs
        //[_mPortSIPSDK addVideoCodec:VIDEO_CODEC_H263];
        //[_mPortSIPSDK addVideoCodec:VIDEO_CODEC_H263_1998];
        
        [_mPortSIPSDK setVideoBitrate:100];             //video send bitrate,100kbps
        [_mPortSIPSDK setVideoFrameRate:10];
        [_mPortSIPSDK setVideoResolution:VIDEO_CIF];
        [_mPortSIPSDK setAudioSamples:20 maxPtime:60];  //ptime 20
        [_mPortSIPSDK setVideoDeviceId:1];              //1 - FrontCamra 0 - BackCamra
        //[_mPortSIPSDK setVideoOrientation:180];
        
        //Enable SRTP
        [_mPortSIPSDK setSrtpPolicy:SRTP_POLICY_NONE];
        
        //set RTC keep alives
        [_mPortSIPSDK setRtpKeepAlive:true keepAlivePayloadType:126 deltaTransmitTimeMS:30000];
        
        _videoController = [VideoViewController new];
    }
    return self;
}

-(void)dealloc
{
    [self unregister];
    [_mPortSIPSDK unInitialize];
}

#pragma mark - Registration -

-(void)registerToLine:(Line *)line
{
    // If we are registered to a line, we need to unregister from that line, and reconnect.
    if (_registered) {
        [self unregister];
    }
    
    if (!line) {
        [_delegate sipHandler:self didFailToRegisterWithError:[JCSipHandlerError errorWithCode:JC_SIP_REGISTER_LINE_IS_EMPTY reason:@"Line is empty"]];
        return;
    }
    
    if (!line.lineConfiguration) {
        [_delegate sipHandler:self didFailToRegisterWithError:[JCSipHandlerError errorWithCode:JC_SIP_REGISTER_LINE_CONFIGURATION_IS_EMPTY reason:@"Line Configuration is empty"]];
        return;
    }
    
    if (!line.pbx) {
        [_delegate sipHandler:self didFailToRegisterWithError:[JCSipHandlerError errorWithCode:JC_SIP_REGISTER_LINE_PBX_IS_EMPTY reason:@"Line PBX is empty"]];
        return;
    }
    
    NSString *userName = line.lineConfiguration.sipUsername;
    if (!userName) {
        [_delegate sipHandler:self didFailToRegisterWithError:[JCSipHandlerError errorWithCode:JC_SIP_REGISTER_USER_IS_EMPTY reason:@"User is empty"]];
        return;
    }
    
    NSString *server = line.pbx.isV5 ? line.lineConfiguration.outboundProxy : line.lineConfiguration.registrationHost;
    if (!server) {
        [_delegate sipHandler:self didFailToRegisterWithError:[JCSipHandlerError errorWithCode:JC_SIP_REGISTER_SERVER_IS_EMPTY reason:@"Server is empty"]];
        return;
    }
    
    NSString *password = line.lineConfiguration.sipPassword;
    if (!password) {
        [_delegate sipHandler:self didFailToRegisterWithError:[JCSipHandlerError errorWithCode:JC_SIP_REGISTER_PASSWORD_IS_EMPTY reason:@"Password is empty"]];
        return;
    }
    
    int errorCode = [_mPortSIPSDK setUser:userName
                              displayName:line.lineConfiguration.display
                                 authName:userName
                                 password:password
                                  localIP:@"0.0.0.0"                      // Auto select IP address
                             localSIPPort:(10000 + arc4random()%1000)     // Generate a random port in the 10,000 range
                               userDomain:@""
                                SIPServer:server
                            SIPServerPort:OUTBOUND_SIP_SERVER_PORT
                               STUNServer:@""
                           STUNServerPort:0
                           outboundServer:line.lineConfiguration.outboundProxy
                       outboundServerPort:OUTBOUND_SIP_SERVER_PORT];
    
    if(errorCode) {
        [_delegate sipHandler:self didFailToRegisterWithError:[JCSipHandlerError errorWithCode:errorCode reason:@"Error Setting the User"]];
        return;
    }
    
    _line = line;
    errorCode = [_mPortSIPSDK registerServer:3600 retryTimes:9];
    if(errorCode) {
        [_delegate sipHandler:self didFailToRegisterWithError:[JCSipHandlerError errorWithCode:errorCode reason:@"Error starting Registration"]];
        return;
    }
}

-(void)unregister
{
    if(_registered)
    {
        for (JCLineSession *lineSession in _lineSessions) {
            [self hangUpSession:lineSession completion:NULL];
        }
        [_mPortSIPSDK unRegisterServer];
        _registered = NO;
        [_delegate sipHandlerDidUnregister:self];
    }
}

#pragma mark - Backgrounding -

- (void)startKeepAwake
{
    if (_mPortSIPSDK) {
        [_mPortSIPSDK startKeepAwake];
    }
}

-(void)stopKeepAwake
{
    if (_mPortSIPSDK) {
        [_mPortSIPSDK stopKeepAwake];
    }
}

#pragma mark - Line Session Public Methods -

- (JCLineSession *)makeCall:(NSString *)dialString videoCall:(BOOL)videoCall contactName:(NSString *)contactName;
{
	JCLineSession *lineSession = [self findIdleLine];
    if (!lineSession) {
        return nil;
    }
	
	long sessionId = [_mPortSIPSDK call:dialString sendSdp:TRUE videoCall:videoCall];
	if(sessionId >= 0)
	{
		[lineSession setMSessionId:sessionId];
        lineSession.active = TRUE;
		
		[lineSession setCallTitle:contactName ? contactName : dialString];
		[lineSession setCallDetail:dialString];
        [OutgoingCall addOutgoingCallWithLineSession:lineSession line:_line];
	}
	else
	{
        NSError *error = [Common createErrorWithDescription:NSLocalizedString(@"Call Failed", nil) reason:NSLocalizedString(@"Unable to create call", nil) code:sessionId];
        [self setSessionState:JCCallFailed forSession:lineSession event:@"makeCall:" error:error];
	}
	return lineSession;
}

- (void)answerSession:(JCLineSession *)lineSession
{
	[self answerSession:lineSession completion:NULL];
}

- (void)answerSession:(JCLineSession *)lineSession completion:(CompletionHandler)completion
{
    if (!lineSession)
        return;
    
    int error = [_mPortSIPSDK answerCall:lineSession.mSessionId videoCall:FALSE];
    if(error == 0)
    {
        if (lineSession.mRecvCallState) {
            [IncomingCall addIncommingCallWithLineSession:lineSession line:_line];
        }
        
        [lineSession setMRecvCallState:false];
        [lineSession setMVideoState:false];
        
        if (completion != NULL) {
            completion(true, nil);
        }
    }
    else {
        NSString *event = @"Unable to answer the call";
        NSError *msg = [NSError errorWithDomain:@"Unable to answer the call" code:error userInfo:nil];
        [self setSessionState:JCCallFailed forSession:lineSession event:event error:msg];
        if (completion != NULL) {
            completion(false, msg);
        }
    }
}

- (void)hangUpSession:(JCLineSession *)lineSession completion:(CompletionHandler)completion
{
    if (lineSession.isActive)
    {
        int error = [_mPortSIPSDK hangUp:lineSession.mSessionId];
        if (error == 0) {
            [self setSessionState:JCCallCanceled forSession:lineSession event:@"Hangup Call" error:nil];
            if (completion != NULL) {
                completion(true, nil);
            }
        }
        else
        {
            if (completion != NULL) {
                completion(false, [NSError errorWithDomain:@"Error Trying to Hang up" code:error userInfo:nil]);
            }
        }
    }
    else if (lineSession.mRecvCallState)
    {
        int error = [_mPortSIPSDK rejectCall:lineSession.mSessionId code:486];
        if (error == 0) {
            [self setSessionState:JCCallCanceled forSession:lineSession event:@"Manually Reject Incoming Call" error:nil];
            if (completion != NULL) {
                completion(true, nil);
            }
        }
        else
        {
            if (completion != NULL) {
                completion(false, [NSError errorWithDomain:@"Error Trying to reject Call" code:error userInfo:nil]);
            }
        }
    }
    else
    {
        
    }
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
        NSLog(@"%@", [self.lineSessions description]);
    }
}

- (void)blindTransferToNumber:(NSString *)number completion:(void (^)(BOOL, NSError *))completion
{
    // Find the active line. It is the one we will be refering to the number passed.
	JCLineSession *lineSession = [self findActiveLine];
	if (!lineSession || lineSession.isActive == false)
	{
        completion(false, [NSError errorWithDomain:@"Need to make the call established first" code:0 userInfo:nil]);
		return;
	}
	
    // Tell PortSip to refer the session id to the passed number. If sucessful, the PortSip deleagate method will inform
    // us and we will call the completion block.
    _transferCompletionHandler = completion;
	int result = [_mPortSIPSDK refer:lineSession.mSessionId referTo:number];
    if (result != 0)
    {
        NSString *msg = NSLocalizedString(@"Blind Transfer failed", nil);
        NSError *error = [Common createErrorWithDescription:msg reason:NSLocalizedString(@"Unable to make blind transfer", nil) code:result];
        [self setSessionState:JCTransferFailed forSession:lineSession event:msg error:error];
        completion(false, [NSError errorWithDomain:msg code:0 userInfo:nil]);
        _transferCompletionHandler = nil;
    }
    return;
}

- (void)warmTransferToNumber:(NSString *)number completion:(void (^)(BOOL success, NSError *error))completion
{
	JCLineSession *receivingSession = [self findActiveLine];
    if (!receivingSession || !receivingSession.isActive)
    {
        completion(false, [NSError errorWithDomain:@"Need to make the call established first" code:0 userInfo:nil]);
        return;
    }
    
	JCLineSession *sessionToTransfer = [self findLineWithHoldState];
    if (!sessionToTransfer || !sessionToTransfer.isActive) {
        completion(false, [NSError errorWithDomain:@"Unable to find session on hold to warm transfer" code:0 userInfo:nil]);
        return;
    }
	
    _transferCompletionHandler = completion;
    int result = [_mPortSIPSDK attendedRefer:receivingSession.mSessionId replaceSessionId:sessionToTransfer.mSessionId referTo:number];
    if (result != 0) {
        NSString *msg = NSLocalizedString(@"Warm Transfer failed", nil);
        NSError *error = [Common createErrorWithDescription:msg reason:NSLocalizedString(@"Unable make transfer", nil) code:result];
        [self setSessionState:JCTransferFailed forSession:receivingSession event:msg error:error];
        completion(false, error);
        _transferCompletionHandler = nil;
    }
}

- (void) muteCall:(BOOL)mute
{
    [_mPortSIPSDK muteMicrophone:mute];
}

- (bool)setConference:(bool)conference
{
	if (conference)
	{
		int rt = [_mPortSIPSDK createConference:[UIView new] videoResolution:VIDEO_NONE displayLocalVideo:NO];
		if (rt == 0) {
			for (JCLineSession *line in self.lineSessions)
			{
				if (line.isActive)
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
			if (line.isActive && !line.isHolding )
			{
				[_mPortSIPSDK hold:line.mSessionId];
				line.hold = true;
			}
		}
		
		[_mPortSIPSDK destroyConference];
	}
	
	return inConference;
}

-(void)setLoudSpeakerEnabled:(BOOL)loudSpeakerEnabled
{
    [_mPortSIPSDK setLoudspeakerStatus:loudSpeakerEnabled];
}

- (void) pressNumpadButton:(char )dtmf
{
    JCLineSession *session = [self findActiveLine];
    if(session && session.isActive)
    {
        [_mPortSIPSDK sendDtmf:session.mSessionId dtmfMethod:DTMF_RFC2833 code:dtmf dtmfDration:160 playDtmfTone:TRUE];
    }
}

#pragma mark - Getters -

-(BOOL)isActive
{
    NSArray *activeLines = [self findAllActiveLines];
    if (activeLines.count > 0) {
        return TRUE;
    }
    return FALSE;
}

#pragma mark - Private -

#pragma mark Find line methods

- (JCLineSession *)findSession:(long)sessionId
{
    for (JCLineSession *line in self.lineSessions) {
        if (sessionId == line.mSessionId) {
            return line;
        }
    }
    return nil;
}

- (JCLineSession *)findActiveLine
{
    for (JCLineSession *line in self.lineSessions) {
        if (line.isActive &&
            !line.isHolding &&
            !line.mRecvCallState){
            return line;
        }
    }
    return nil;
}

- (JCLineSession *)findLineWithRecevingState
{
    for (JCLineSession *line in self.lineSessions) {
        if (!line.isActive &&
            line.mRecvCallState){
            return line;
        }
    }
    return nil;
}

- (JCLineSession *)findLineWithHoldState
{
    for (JCLineSession *line in self.lineSessions) {
        if (line.isActive &&
            line.isHolding &&
            !line.mRecvCallState) {
            return line;
        }
    }
    return nil;
}

- (JCLineSession *)findIdleLine
{
    for (JCLineSession *line in self.lineSessions){
        if (!line.isActive &&
            !line.mRecvCallState){
            return line;
        }
    }
    return nil;
}

- (NSArray *) findAllActiveLines
{
    NSMutableArray *activeLines = [NSMutableArray new];
    for (JCLineSession *line in self.lineSessions)
    {
        if (line.isActive) {
            [activeLines addObject:line];
        }
    }
    return activeLines;
}

#pragma mark Session State

-(void)setSessionState:(JCLineSessionState)state forSession:(JCLineSession *)lineSession event:(NSString *)event error:(NSError *)error
{
    if (!lineSession) {
        return;
    }
    
    NSLog(@"%@ Session Id: %ld", event, lineSession.mSessionId);
    switch (state)
    {
        case JCTransferSuccess:
        {
            lineSession.sessionState = state;
            if (_transferCompletionHandler) {
                _transferCompletionHandler(YES, error);
                _transferCompletionHandler = nil;
            }
            [self.delegate sipHandler:self willRemoveLineSession:lineSession];
            [lineSession reset];
            break;
        }
        case JCTransferFailed:
        {
            lineSession.sessionState = state;
            NSLog(@"%@", [self.lineSessions description]);
            if (_transferCompletionHandler) {
                _transferCompletionHandler(NO, error);
                _transferCompletionHandler = nil;
            }
            break;
        }
        case JCCallFailed:
        case JCCallCanceled:
        {
            lineSession.sessionState = state;
            NSLog(@"%@", [self.lineSessions description]);
            if (lineSession.mRecvCallState)
            {
                [MissedCall addMissedCallWithLineSession:lineSession line:_line];
            }
            [self.delegate sipHandler:self willRemoveLineSession:lineSession];
            [lineSession reset];
            break;
        }
        
        // Session is an incoming call -> notify delegate to add it.
        case JCCallIncoming:
            lineSession.sessionState = state;               // Set the session state.
            [self.delegate sipHandler:self didAddLineSession:lineSession];     // Notify the delegate to add a line.
            if (autoAnswer) {
                autoAnswer = false;
                [self.delegate sipHandler:self receivedIntercomLineSession:lineSession];
            }
            break;
        
        case JCCallConnected:
            lineSession.updatable = TRUE;
        case JCCallAnswered:
            lineSession.active = TRUE;
        default:
            lineSession.sessionState = state;
            break;
    }
    
    NSLog(@"%@", [self.lineSessions description]);
}

-(void)setSessionState:(JCLineSessionState)state forSessionId:(long)sessionId event:(NSString *)event error:(NSError *)error
{
    JCLineSession *lineSession = [self findSession:sessionId];
    if (!lineSession)
    {
        NSLog(@"invalid session id: %ld for event: %@", sessionId, event);
        return;
    }
    
    [self setSessionState:state forSession:[self findSession:sessionId] event:event error:error];
}

#pragma mark - PortSIP SDK Delegate Handlers -

#pragma mark Resgistration Events

- (void)onRegisterSuccess:(char*) statusText statusCode:(int)statusCode
{
    _registered = TRUE;
    [_delegate sipHandlerDidRegister:self];
}

- (void)onRegisterFailure:(char*) statusText statusCode:(int)statusCode
{
    _registered = FALSE;
    [_delegate sipHandler:self didFailToRegisterWithError:[JCSipHandlerError errorWithCode:statusCode reason:@"Registration failed"]];
}

#pragma mark Incoming Call Events

/**
 * Informs us of an incoming event.
 */
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
	
    // Setup the line session.
    idleLine.mRecvCallState = true;              // Flag as being in a receiving state.
	[idleLine setMSessionId:sessionId];          // Attach a session id to the line session.
    [idleLine setMVideoState:existsVideo];                                                          // Flag if video call.
	[idleLine setCallTitle:[NSString stringWithUTF8String:callerDisplayName]];                      // Get Call Title
	[idleLine setCallDetail:[self formatCallDetail:[NSString stringWithUTF8String:caller]]];        // Get Call Detail.
    [self setSessionState:JCCallIncoming forSession:idleLine event:@"onInviteIncoming" error:nil];  // Set the session state.
};

-(NSString *)formatCallDetail:(NSString *)callDetail
{
    NSRange stripRange = [callDetail rangeOfString:@"@"];
    
    NSRange striped = NSMakeRange(stripRange.location, (callDetail.length - stripRange.location));
    callDetail = [callDetail stringByReplacingCharactersInRange:striped withString:@""];
    
    NSRange finalrange = NSMakeRange(4, callDetail.length-4);
    callDetail = [callDetail substringWithRange:finalrange];
    return callDetail;
}

#pragma mark Outgoing Call Events

/**
 * If the outgoing call is processing, this event is triggered.
 */
- (void)onInviteTrying:(long)sessionId
{
	[self setSessionState:JCCallTrying forSessionId:sessionId event:@"onInviteTrying" error:nil];
};

/**
 * Once the caller received the "183 session progress" message, this event will be triggered.
 */
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
    [self setSessionState:JCCallProgress forSession:selectedLine event:@"onInviteSessionProgress" error:nil] ;
}

/**
 * If the outgoing call is ringing, this event is triggered.
 */
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

/**
 * If the remote party answered the call, this event is triggered.
 */
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
	
	[selectedLine setMVideoState:existsVideo];
	
	// If this is the refer call then need set it to normal
	if (selectedLine.mIsReferCall)
	{
		[selectedLine setReferCall:false originalCallSessionId:0];
	}
    
    [self setSessionState:JCCallAnswered forSession:selectedLine event:@"onInviteAnswered" error:nil];
}


/**
 * If the outgoing call fails, this event is triggered.
 */
- (void)onInviteFailure:(long)sessionId reason:(char*)reason code:(int)code
{
    NSString *event = [NSString stringWithFormat:@"onInviteFailure reason: %@ code: %i", [NSString stringWithCString:reason encoding:NSUTF8StringEncoding], code];
    
    NSError *error = [Common createErrorWithDescription:event
                                                 reason:[NSString stringWithUTF8String:reason]
                                                   code:code];
    
    [self setSessionState:JCCallFailed forSessionId:sessionId event:event error:error];
}

/**
 * This event will be triggered when UAC sent/UAS received ACK(the call is connected). Some functions(hold, updateCall 
 * etc...) can called only after the call connected, otherwise the functions will return error.
 */
- (void)onInviteConnected:(long)sessionId
{
    [self setSessionState:JCCallConnected forSessionId:sessionId event:@"onInviteConnected" error:nil];
}

- (void)onInviteClosed:(long)sessionId
{
    [self setSessionState:JCCallCanceled forSessionId:sessionId event:@"onInviteClosed" error:nil];
}

#pragma mark - Transfer Events

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
        idleLine.active = true;
        [idleLine setReferCall:true originalCallSessionId:selectedLine.mSessionId];
        [self.delegate sipHandler:self willRemoveLineSession:selectedLine];
	}
    
    [self setSessionState:JCTransferIncoming forSessionId:sessionId event:@"onReceivedRefer" error:nil];
}

/**
 * This callback will be triggered once remote side called "acceptRefer" to accept the REFER
 */
- (void)onReferAccepted:(long)sessionId
{
    [self setSessionState:JCTransferAccepted forSessionId:sessionId event:@"onReferAccepted" error:nil];
}

/**
 * This callback will be triggered once remote side called "rejectRefer" to reject the REFER
 */
- (void)onReferRejected:(long)sessionId reason:(char*)reason code:(int)code
{
    [self setSessionState:JCTransferRejected forSessionId:sessionId event:@"onReferRejected" error:nil];
}

/**
 * When the refer call is processing, this event trigged.
 */
- (void)onTransferTrying:(long)sessionId
{
    [self setSessionState:JCTransferTrying forSessionId:sessionId event:@"onTransferTrying" error:nil];
}

/**
 * When the refer call is ringing, this event trigged.
 */
- (void)onTransferRinging:(long)sessionId
{
    [self setSessionState:JCTransferRinging forSessionId:sessionId event:@"onTransferRinging" error:nil];
}

/**
 * When the refer call is succeeds, this event will be triggered. The ACTV means Active. For example: A established the 
 * call with B, A transfer B to C, C accepted the refer call, A received this event.
 */
- (void)onACTVTransferSuccess:(long)sessionId
{
    [self setSessionState:JCTransferSuccess forSessionId:sessionId event:@"onACTVTransferSuccess" error:nil];
}

- (void)onACTVTransferFailure:(long)sessionId reason:(char*)reason code:(int)code
{
    NSString *event = [NSString stringWithFormat:@"onACTVTransferFailure reason: %@ code: %i", [NSString stringWithCString:reason encoding:NSUTF8StringEncoding], code];
    NSError *error = [Common createErrorWithDescription:event reason:[NSString stringWithUTF8String:reason] code:code];
    [self setSessionState:JCTransferFailed forSessionId:sessionId event:event error:error];
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

- (void)onReceivedSignaling:(long)sessionId message:(char*)message
{
	NSString *sipMessage = [NSString stringWithUTF8String:message];
	if (
        [sipMessage rangeOfString:kSipHandlerAutoAnswerModeAutoHeader].location != NSNotFound ||
		[sipMessage rangeOfString:kSipHandlerAutoAnswerInfoIntercomHeader].location != NSNotFound ||
		[sipMessage rangeOfString:kSipHandlerAutoAnswerAfterIntervalHeader].location != NSNotFound) {
		autoAnswer = true;
	}
	else {
		autoAnswer = false;
	}
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
    if (!_line.pbx.isV5) {
        [JCBadgeManager sharedManager].voicemails = newMessageCount;
    }    
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
