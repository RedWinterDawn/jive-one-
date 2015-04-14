//
//  SipHandler.m
//  JiveOne
//
//  The Sip Handler server as a wrapper to the port sip SDK and manages Line Session objects.
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCSipManager.h"
#import "Common.h"
#import "JCAppSettings.h"
#import "JCSipNetworkQualityRequestOperation.h"
#import "JCPhoneNumber.h"

#ifdef __APPLE__
#include "TargetConditionals.h"
#endif

// Libraries
#import <PortSIPLib/PortSIPSDK.h>
#import <AVFoundation/AVFoundation.h>

// Managers
#import "JCBadgeManager.h"          // Sip directly reports voicemail count for v4 clients to badge manager
#import "JCPhoneAudioManager.h"     // Sip directly interacts with the audio session.

// Managed Objects
#import "IncomingCall.h"
#import "MissedCall.h"
#import "OutgoingCall.h"
#import "LineConfiguration.h"
#import "Line.h"
#import "PBX.h"
#import "Contact.h"

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
#define IS_SIMULATOR 1
#elif TARGET_OS_IPHONE
#define IS_SIMULATOR 0
#endif

#define DEFAULT_PHONE_REGISTRATION_TIMEOUT_INTERVAL 15

NSString *const kSipHandlerAutoAnswerModeAutoHeader = @"Answer-Mode: auto";
NSString *const kSipHandlerAutoAnswerInfoIntercomHeader = @"Alert-Info: Intercom";
NSString *const kSipHandlerAutoAnswerAfterIntervalHeader = @"answer-after=0";

NSString *const kSipHandlerServerAgentname = @"Jive iOS Client";
NSString *const kSipHandlerLineErrorMessage = @"Unable to fetch the line configuration";
NSString *const kSipHandlerFetchPBXErrorMessage = @"Unable to fetch the line configuration";
NSString *const kSipHandlerRegisteredSelectorKey = @"registered";

@interface JCSipManager() <PortSIPEventDelegate, JCPhoneAudioManagerDelegate>
{
    PortSIPSDK *_mPortSIPSDK;
    CompletionHandler _transferCompletionHandler;
	VideoViewController *_videoController;
    NSOperationQueue *_operationQueue;
	bool autoAnswer;
    
    NSTimer *_registrationTimeoutTimer;
    NSTimeInterval _registrationTimeoutInterval;
    BOOL _reregisterAfterActiveCallEnds;
    NSUInteger _numberOfLines;
}

@property (nonatomic) NSMutableSet *lineSessions;

- (JCLineSession *)findSession:(long)sessionId;

@end

@implementation JCSipManager

-(instancetype)initWithNumberOfLines:(NSUInteger)lines delegate:(id<SipHandlerDelegate>)delegate error:(NSError *__autoreleasing *)error;
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        
        _lineSessions = [NSMutableSet new];
        for (int i = 0; i < lines; i++)
            [_lineSessions addObject:[JCLineSession new]];
        
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.name = @"SipHandler Operation Queue";
        
        _audioManager = [JCPhoneAudioManager new];
        _audioManager.delegate = self;
        
        _registrationTimeoutInterval = DEFAULT_PHONE_REGISTRATION_TIMEOUT_INTERVAL;
        _numberOfLines = lines;
    }
    return self;
}

-(void)dealloc
{
    [self unregister];
}

#pragma mark - Registration -

-(void)registerToLine:(Line *)line
{
    __autoreleasing NSError *error;
    BOOL registered = [self registerToLine:line error:&error];
    if (!registered) {
        [_delegate sipHandler:self didFailToRegisterWithError:error];
    }
}

-(void)unregister
{
    if(_registered)
    {
        __autoreleasing NSError *error;
        for (JCLineSession *lineSession in _lineSessions) {
            [self hangUpSession:lineSession error:&error];
        }
        [_mPortSIPSDK unRegisterServer];
        [_mPortSIPSDK unInitialize];
        _registered = FALSE;
        [_delegate sipHandlerDidUnregister:self];
    }
}

#pragma mark Private

/**
 * Initializes the PortSIPSDK, setting the number of lines, licence and audio and video settings. 
 * Should be called before the line is registered.
 */
-(BOOL)initialize:(NSError *__autoreleasing *)error;
{
    if (_mPortSIPSDK) {
        [_mPortSIPSDK unRegisterServer];
        [_mPortSIPSDK unInitialize];
    }
    
    // Initialize the port sip sdk.
    _mPortSIPSDK = [PortSIPSDK new];
    _mPortSIPSDK.delegate = self;
    int errorCode = [_mPortSIPSDK initialize:TRANSPORT_UDP
                                    loglevel:LOG_LEVEL
                                     logPath:nil
                                     maxLine:(int)_numberOfLines
                                       agent:kSipHandlerServerAgentname
                            audioDeviceLayer:IS_SIMULATOR
                            videoDeviceLayer:IS_SIMULATOR];
    
    if(errorCode) {
        _mPortSIPSDK = nil;
        _lineSessions = nil;
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:errorCode reason:@"Error initializing port sip sdk"];
        }
        return FALSE;
    }
    
    // Check License Key
    errorCode = [_mPortSIPSDK setLicenseKey:kPortSIPKey];
    if(errorCode) {
        [_mPortSIPSDK unInitialize];
        _mPortSIPSDK = nil;
        _lineSessions = nil;
        if(error != NULL) {
            *error = [JCSipManagerError errorWithCode:errorCode reason:@"Port Sip License Key Failure"];
        }
        return FALSE;
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
    _initialized = TRUE;
    return TRUE;
}

-(BOOL)registerToLine:(Line *)line error:(NSError *__autoreleasing *)error;
{
    // Check if we are already registering.
    if (_registering) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_ALREADY_REGISTERING reason:@"Already Registering"];
        }
        return FALSE;
    }
    
    // Check to see if we are on a current call. If we are, we need to exit out, and wait until the
    // call has completed before we do anything. We do not want to end the call.
    _reregisterAfterActiveCallEnds = FALSE;
    if (self.isActive) {
        _reregisterAfterActiveCallEnds = TRUE;
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_ALREADY_REGISTERING reason:@"Already Registering"];
        }
        return FALSE;
    }
    
    // If we are registered to a line, we need to unregister from that line, and reconnect.
    if (_registered || _line != line) {
        [self unregister];
    }
    
    BOOL initialized = [self initialize:error];
    if (!initialized) {
        return FALSE;
    }
    
    if (!line) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_REGISTER_LINE_IS_EMPTY reason:@"Line is empty"];
        }
        return FALSE;
    }
    
    if (!line.lineConfiguration) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_REGISTER_LINE_CONFIGURATION_IS_EMPTY reason:@"Line Configuration is empty"];
        }
        return FALSE;
    }
    
    if (!line.pbx) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_REGISTER_LINE_PBX_IS_EMPTY reason:@"Line PBX is empty"];
        }
        return FALSE;
    }
    
    NSString *userName = line.lineConfiguration.sipUsername;
    if (!userName) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_REGISTER_USER_IS_EMPTY reason:@"User is empty"];
        }
        return FALSE;
    }
    
    NSString *server = line.pbx.isV5 ? line.lineConfiguration.outboundProxy : line.lineConfiguration.registrationHost;
    if (!server) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_REGISTER_SERVER_IS_EMPTY reason:@"Server is empty"];
        }
        return FALSE;
    }
    
    NSString *password = line.lineConfiguration.sipPassword;
    if (!password) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_REGISTER_PASSWORD_IS_EMPTY reason:@"Password is empty"];
        }
        return FALSE;
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
        if (error) {
            *error = [JCSipManagerError errorWithCode:errorCode reason:@"Error Setting the User"];
        }
        return FALSE;
    }
    
    _line = line;
    errorCode = [_mPortSIPSDK registerServer:3600 retryTimes:9];
    if(errorCode) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:errorCode reason:@"Error starting Registration"];
        }
        return FALSE;
    }
    
    _registrationTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:_registrationTimeoutInterval
                                                                 target:self
                                                               selector:@selector(registrationTimedOut:)
                                                               userInfo:nil
                                                                repeats:NO];
    _registering = TRUE;
    return TRUE;
}

#pragma mark Registration PortSIP SDK Delegate Events

-(void)registrationTimedOut:(NSTimer *)timer
{
    [_registrationTimeoutTimer invalidate];
    _registrationTimeoutTimer = nil;
    _registering = FALSE;
    _registered = FALSE;
    [_delegate sipHandler:self didFailToRegisterWithError:[JCSipManagerError errorWithCode:JC_SIP_REGISTRATION_TIMEOUT]];
}

- (void)onRegisterSuccess:(char*) statusText statusCode:(int)statusCode
{
    [_registrationTimeoutTimer invalidate];
    _registrationTimeoutTimer = nil;
    _registering = FALSE;
    _registered = TRUE;
    [_delegate sipHandlerDidRegister:self];
}

- (void)onRegisterFailure:(char*) statusText statusCode:(int)statusCode
{
    [_registrationTimeoutTimer invalidate];
    _registrationTimeoutTimer = nil;
    _registering = FALSE;
    _registered = FALSE;
    [_delegate sipHandler:self didFailToRegisterWithError:[JCSipManagerError errorWithCode:JC_SIP_REGISTRATION_FAILURE underlyingError:[JCSipManagerError errorWithCode:statusCode]]];
}

#pragma mark - Backgrounding -

-(void)startKeepAwake
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
    
    if (!self.isActive && !_registered && _line) {
        [self registerToLine:_line];
    }
}

#pragma mark - Line Session Public Methods -

- (BOOL)makeCall:(id<JCPhoneNumberDataSource>)number videoCall:(BOOL)videoCall error:(NSError *__autoreleasing *)error
{
	// Check to see if we can make a call. We can make a call if we have an idle line session. If we
    // do not have one, exit with error.
    JCLineSession *lineSession = [self findIdleLine];
    if (!lineSession) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_CALL_NO_IDLE_LINE];
        }
        return NO;
    }
    
    // Try to to place all current calls that are active on hold.
    __autoreleasing NSError *holdError;
    if (![self holdLines:&holdError]) {
        if (error != NULL) {
            *error = holdError;
        }
        return NO;
    }
    
    // Intitiate the call. If we fail, set error and return. Errors from this method are negative
    // numbers, and positive numbers are success and thier session id.
    NSInteger result = [_mPortSIPSDK call:number.dialableNumber sendSdp:TRUE videoCall:videoCall];
    if(result <= 0) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:result reason:@"Unable to create call"];
        }
        [self setSessionState:JCCallFailed forSession:lineSession event:@"makeCall:" error:nil];
        return NO;
    }
    
    // Configure the line session.
    lineSession.sessionId = result;
    lineSession.number = number;
    
    [self setSessionState:JCCallInitiated forSession:lineSession event:@"Initiating Call" error:nil];
    return YES;
}

- (BOOL)answerSession:(JCLineSession *)lineSession error:(NSError *__autoreleasing *)error
{
    if (!lineSession) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_LINE_SESSION_IS_EMPTY reason:@"Line Session in empty"];
        }
        return NO;
    }
    
    // Try to to place all current calls that are active on hold.
    __autoreleasing NSError *holdError;
    if (![self holdLines:&holdError]) {
        if (error != NULL) {
            *error = holdError;
        }
        return NO;
    }
    
    if (lineSession.isActive && !lineSession.isIncoming) {
        return YES;
    }
    
    NSInteger errorCode = [_mPortSIPSDK answerCall:lineSession.sessionId videoCall:lineSession.isVideo];
    if (errorCode) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:errorCode reason:@"Unable to answer the call"];
        }
        [self setSessionState:JCCallFailed forSession:lineSession event:nil error:nil];
        return NO;
    }
    
    [self setSessionState:JCCallAnswerInitiated forSession:lineSession event:nil error:nil];
    return YES;
}

- (BOOL)hangUpAllSessions:(NSError *__autoreleasing *)error
{
    NSSet *lineSessions = [self findAllActiveLines];
    
    __autoreleasing NSError *hangupError;
    for (JCLineSession *lineSession in lineSessions) {
        [self hangUpSession:lineSession error:&hangupError];
        if (hangupError) {
            break;
        }
    }
    
    if (hangupError) {
        if (error != NULL) {
            *error = hangupError;
        }
        return NO;
    }
    return YES;
}

- (BOOL)hangUpSession:(JCLineSession *)lineSession error:(NSError *__autoreleasing *)error
{
    if (lineSession.incoming)
    {
        int errorCode = [_mPortSIPSDK rejectCall:lineSession.sessionId code:486];
        if (errorCode) {
            if(error != NULL) {
                *error = [JCSipManagerError errorWithCode:errorCode reason:@"Error trying to manually reject incomming call"];
            }
            return NO;
        }
            
        [self setSessionState:JCCallCanceled forSession:lineSession event:@"Manually Rejected Incoming Call" error:nil];
        return YES;
    }
    
    NSInteger errorCode = [_mPortSIPSDK hangUp:lineSession.sessionId];
    if (errorCode) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:errorCode reason:@"Error Trying to Hang up"];
        }
        return NO;
    }
        
    [self setSessionState:JCCallCanceled forSession:lineSession event:@"Hangup Call" error:nil];
    return YES;
}

- (BOOL)holdLines:(NSError *__autoreleasing *)error
{
    NSSet *lineSessions = [self findAllActiveLinesNotHolding];
    if (lineSessions.count > 0) {
        return [self holdLineSessions:lineSessions error:error];
    }
    return YES;
}

- (BOOL)holdLineSessions:(NSSet *)lineSessions error:(NSError *__autoreleasing *)error
{
    __autoreleasing NSError *holdError;
    for (JCLineSession *lineSession in lineSessions) {
        if (![self holdLineSession:lineSession error:&holdError]) {
            break;
        }
    }
    
    if (holdError) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:holdError.code reason:@"Error holding the line sessions" underlyingError:holdError];
        }
        return false;
    }
    return true;
}

- (BOOL)holdLineSession:(JCLineSession *)lineSession error:(NSError *__autoreleasing *)error
{
    if (lineSession.isHolding) {
        return YES;
    }
    
    NSInteger errorCode = [_mPortSIPSDK hold:lineSession.sessionId];
    if (errorCode) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:errorCode reason:@"Error placing calls on hold"];
        }
        return NO;
    }
    
    lineSession.hold = TRUE;
    return YES;
}

- (BOOL)unholdLines:(NSError *__autoreleasing *)error
{
    NSSet *lineSessions = [self findAllActiveLinesOnHold];
    return [self unholdLineSessions:lineSessions error:error];
}

- (BOOL)unholdLineSessions:(NSSet *)lineSessions error:(NSError *__autoreleasing *)error
{
    __autoreleasing NSError *holdError;
    for (JCLineSession *lineSession in lineSessions) {
        if (![self unholdLineSession:lineSession error:&holdError]) {
            break;
        }
    }
    
    if (holdError) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:holdError.code reason:@"Error unholding the line session while after joing the conference" underlyingError:holdError];
        }
        return FALSE;
    }
    return TRUE;
}

-(BOOL)unholdLineSession:(JCLineSession *)lineSession error:(NSError *__autoreleasing *)error
{
    if (!lineSession.isHolding) {
        return YES;
    }
    
    NSInteger errorCode = [_mPortSIPSDK unHold:lineSession.sessionId];
    if (errorCode) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:errorCode reason:@"Error placing calls on hold"];
        }
        return NO;
    }

    lineSession.hold = FALSE;
    return YES;
}

- (BOOL)createConference:(NSError *__autoreleasing *)error
{
    NSSet *lineSessions = [self findAllActiveLines];
    return [self createConferenceWithLineSessions:lineSessions error:error];
}

-(BOOL)createConferenceWithLineSessions:(NSSet *)lineSessions error:(NSError *__autoreleasing *)error
{
    if (_conferenceCall) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_CONFERENCE_CALL_ALREADY_STARTED reason:@"Conference call already started"];
        }
        return FALSE;
    }
    
    NSInteger errorCode = [_mPortSIPSDK createConference:[UIView new] videoResolution:VIDEO_NONE displayLocalVideo:NO];
    if (errorCode) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:errorCode reason:@"Error Creating Conference"];
        }
        return false;
    }
    
    _conferenceCall = true;
    for (JCLineSession *lineSession in lineSessions) {
        
        if (lineSession.isHolding) {
            __autoreleasing NSError *holdError;
            if (![self unholdLineSession:lineSession error:&holdError]) {
                if (error != NULL) {
                    *error = [JCSipManagerError errorWithCode:holdError.code reason:@"Error unholding the line session while after joing the conference" underlyingError:holdError];
                }
                break;
            }
        }
        
        errorCode = [_mPortSIPSDK joinToConference:lineSession.sessionId];
        if (errorCode) {
            if (error != NULL) {
                *error = [JCSipManagerError errorWithCode:errorCode reason:@"Error Joining line session to conference"];
            }
            break;
        }
        
        [self setSessionState:JCCallConference forSession:lineSession event:nil error:nil];
    }
    
    if (!errorCode) {
        [_delegate sipHandler:self didCreateConferenceCallWithLineSessions:lineSessions];
        return TRUE;
    }
    
    [_mPortSIPSDK destroyConference];
    _conferenceCall = false;
    return false;
}

-(BOOL)endConference:(NSError *__autoreleasing *)error
{
    NSSet *lineSessions = [self findAllActiveLines];
    return [self endConferenceCallForLineSessions:lineSessions error:error];
}

-(BOOL)endConferenceCallForLineSessions:(NSSet *)lineSessions error:(NSError *__autoreleasing *)error
{
    if (!_conferenceCall) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_CONFERENCE_CALL_ALREADY_ENDED reason:@"Conference call already started"];
        }
        return FALSE;
    }
    
    // Before stop the conference, MUST place all lines to hold state
    if (lineSessions.count > 1) {
        for (JCLineSession *lineSession in lineSessions) {
            if (!lineSession.isHolding){
                __autoreleasing NSError *holdError;
                if(![self holdLineSession:lineSession error:&holdError]) {
                    if (error != NULL) {
                        *error = [JCSipManagerError errorWithCode:holdError.code reason:@"Error placing calls on hold after ending a conference" underlyingError:holdError];
                    }
                    return false;
                }
            }
            lineSession.conference = FALSE;
            [self setSessionState:JCCallConnected forSession:lineSession event:nil error:nil];
        }
    } else {
        JCLineSession *lineSession = lineSessions.allObjects.firstObject;
        lineSession.conference = FALSE;
        [self setSessionState:JCCallConnected forSession:lineSession event:nil error:nil];
    }
    
    [_mPortSIPSDK destroyConference];
    _conferenceCall = FALSE;
    [_delegate sipHandler:self didEndConferenceCallForLineSessions:lineSessions];
    return true;
}

- (void) muteCall:(BOOL)mute
{
    _mute = mute;
    [_mPortSIPSDK muteMicrophone:mute];
}

-(void)setLoudSpeakerEnabled:(BOOL)loudSpeakerEnabled
{
    [_mPortSIPSDK setLoudspeakerStatus:loudSpeakerEnabled];
}

- (void) pressNumpadButton:(char )dtmf
{
    JCLineSession *session = [self findActiveLine];
    if(session && session.isActive){
        [_mPortSIPSDK sendDtmf:session.sessionId dtmfMethod:DTMF_RFC2833 code:dtmf dtmfDration:160 playDtmfTone:TRUE];
    }
}

#pragma mark - Transfers -

//  We are A. B and C represent remote lines that we are connecting to. A blind transfer shifts an
//  established call leg from A -> B to B -> C, following this proccess:
//
//  1) LOCAL: A using a idle line calls B, and establishes a line session on A.
//  2) REMOTE: B using an idle line answers the call from A, and establishes a line session on B.
//  3) LOCAL: A talks to B.
//
//  Blind transfer
//  ---------------------------
//  4) LOCAL: A places B on hold.
//  5) LOCAL: A tags B's session with refer to number of C.
//  6) LOCAL: A refers B to C.
//
//  V4:
//
//  7) REMOTE: C get incoming call from B.
//  8) REMOTE: C answers incoming call from B.
//  9) LOCAL: A gets message ACTVTransferSuccess on line session for B.
//  10) LOCAL: A hangs up call to B.
//  11) LOCAL: A clears the line session that was used for B.
//
//  If the extension is invalid, it still answers, so we do not get an error back, so we cannot
//  catch the error. For actual failures, the onACTVTransferFailure should get called and notify us
//  of the error.
//
//
//  V5:
//
//  1) LOCAL: A using a idle line calls B, and establishes a line session on A.
//  2) REMOTE: B using an idle line answers the call from A, and establishes a line session on B.
//  3) LOCAL: A talks to B.
//
//  Blind transfer
//  ---------------------------
//  4) LOCAL: A places B on hold.
//  5) LOCAL: A tags B's session with refer to number of C.
//  6) LOCAL: A refers B to C.
//

- (BOOL)startBlindTransferToNumber:(id<JCPhoneNumberDataSource>)number error:(NSError *__autoreleasing *)error
{
    // Find the active line. It is the one we will be refering to the number passed.
	JCLineSession *b = [self findActiveLine];
    if (!b) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_CALL_NO_ACTIVE_LINE];
        }
        return NO;
    }
    
    // Try to place the current call on hold before we refer it off the the other number.
    if (![self holdLineSession:b error:error]) {
        return NO;
    }
	
    // Tell PortSip to refer the session id to the passed number. If sucessful, the PortSip
    // deleagate method will inform us if the transfer was successful or a failure.
    b.transfer = TRUE;
	NSInteger errorCode = [_mPortSIPSDK refer:b.sessionId referTo:number.dialableNumber];
    if (errorCode) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:errorCode];
        }
        [self setSessionState:JCTransferFailed forSession:b event:nil error:nil];
        return NO;
    }
    
    return YES;
}


#pragma mark Warm Transfers

//
//  Warm transfer shifts an established call leg from A -> B to B -> C, following this process:
//
//  1) LOCAL: A using an idle line calls B, and establishes a line session on A.
//  2) REMOTE: B using an idle line answers the call from A, and establishes a line session on B.
//  3) LOCAL: A talks to B.
//
//  Start Warm Transfer
//  ---------------------------
//  4) LOCAL: A tags B with the number for C as a referToNumber
//  5) LOCAL: A places B on hold.
//  6) LOCAL: A using anouther idle session, establishes a call with C.
//  7) LOCAL: A has no idle line remaining, with B and C both using a line session each.
//
//  8) REMOTE: C using an idle line session, answers the call from A.
//  9) LOCAL: A talks to C. B is still connected on hold.
//
//  Finish Warm Transfer
//  ---------------------------
//  10) Local: A instructs C to take over the line session with B, refer B to C number which was store on B's
//     line session.
//  11) A get
//

/**
 * Set the currently active line session (B) to have the refer to number on it before we initiate 
 * the other call (C). We will look for this call when we go to finish the transfer, and hand it off.
 */
-(BOOL)startWarmTransferToNumber:(id<JCPhoneNumberDataSource>)number error:(NSError *__autoreleasing *)error
{
    JCLineSession *b = [self findActiveLine];
    b.transfer = TRUE;
    return [self makeCall:number videoCall:NO error:error];
}

-(BOOL)finishWarmTransfer:(NSError *__autoreleasing *)error
{
    JCLineSession *c = [self findActiveLine];
    if (!c) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_CALL_NO_ACTIVE_LINE];
        }
        return NO;
    }
    
    JCLineSession *b = [self findTransferLine];
    if (!b) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_CALL_NO_REFERRAL_LINE];
        }
        return NO;
    }
    
    NSInteger errorCode = [_mPortSIPSDK attendedRefer:c.sessionId replaceSessionId:b.sessionId referTo:c.number.name];
    if (errorCode) {
        if(error != NULL) {
            *error = [JCSipManagerError errorWithCode:errorCode];
        }
        [self setSessionState:JCTransferFailed forSession:b event:nil error:nil];
        return NO;
    }
    return YES;
}

#pragma mark Transfer PortSIP SDK Delegate Events


/*!
 *  This event will be triggered when we received a REFER message.
 *
 *  @param sessionId       The session ID of the call.
 *  @param referId         The ID of the REFER message, pass it to acceptRefer or rejectRefer
 *  @param to              The refer target.
 *  @param from            The sender of REFER message.
 *  @param referSipMessage The SIP message of "REFER", pass it to "acceptRefer" function.
 */
- (void)onReceivedRefer:(long)sessionId referId:(long)referId to:(char*)to from:(char*)from referSipMessage:(char*)referSipMessage
{
    // YOU Are B.
    // A represents the call leg between A -> B and C will represent the call leg between B -> C.
    
    NSString *receiver = [NSString stringWithUTF8String:to];
    NSString *sender   = [NSString stringWithUTF8String:from];
    NSLog(@"sender: %@ receiver: %@", sender, receiver);
    
    JCLineSession *a = [self findSession:sessionId];
    JCLineSession *c = [self findIdleLine];
    if (!a || !c) {
        [_mPortSIPSDK rejectRefer:referId];
        return;
    }
    
    // Hold current call from A before we accept the refer to C
    //__autoreleasing NSError *error;
    //[self holdLineSession:a error:&error];
    
    NSInteger errorCode = [_mPortSIPSDK acceptRefer:referId referSignaling:[NSString stringWithUTF8String:referSipMessage]];
    if (errorCode <= 0) {
        NSError *error = [JCSipManagerError errorWithCode:errorCode];
        NSLog(@"%@", [error description]);
        
        // Error recovery
        //[self unholdLineSession:a error:&error];
        //return;
    }
    
    c.sessionId = errorCode; // In this case, the error code is the session Id.
    c.active = true;
    //[c setReferCall:true originalCallSessionId:a.sessionId];
    [self setSessionState:JCTransferIncoming forSession:c event:@"onReceivedRefer" error:nil];
}

/**
 * This callback will be triggered when the remote side calls "acceptRefer" to accept the REFER,
 * which means the transfer was successfull.
 */
- (void)onReferAccepted:(long)sessionId
{
    [self setSessionState:JCTransferAccepted forSessionId:sessionId event:@"onReferAccepted" error:nil];
}

/**
 * This callback will be triggered when the remote side calls "rejectRefer" to reject the REFER
 */
- (void)onReferRejected:(long)sessionId reason:(char*)reason code:(int)code
{
    NSError *error = [JCSipManagerError errorWithCode:code reason:[NSString stringWithCString:reason encoding:NSUTF8StringEncoding]];
    [self setSessionState:JCTransferRejected forSessionId:sessionId event:@"onReferRejected" error:error];
    [self setSessionState:JCCallConnected forSessionId:sessionId event:nil error:nil];
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
 * When the refer call succeeds, this event will be triggered. The ACTV means Active. For example:
 * A established the call with B, A transfer B to C, C accepted the refer call, A received this event.
 */
- (void)onACTVTransferSuccess:(long)sessionId
{
    [self setSessionState:JCTransferSuccess forSessionId:sessionId event:@"onACTVTransferSuccess" error:nil];
    
    __autoreleasing NSError *error;
    JCLineSession *lineSession = [self findSession:sessionId];
    if (![self hangUpSession:lineSession error:&error]) {
        NSLog(@"%@", [error description]);
    }
}

/**
 * When the refer call fails, this event will be triggered. The ACTV means Active. For example: A
 * established the call with B, A transfer B to C, C rejected this refer call, A will received this
 * event.
 */
- (void)onACTVTransferFailure:(long)sessionId reason:(char*)reason code:(int)code
{
    NSError *error = [JCSipManagerError errorWithCode:code reason:[NSString stringWithCString:reason encoding:NSUTF8StringEncoding]];
    [self setSessionState:JCTransferFailed forSessionId:sessionId event:@"onACTVTransferFailure" error:error];
    [self setSessionState:JCCallConnected forSessionId:sessionId event:nil error:nil];
}

#pragma mark - Getters -

-(BOOL)isActive
{
    NSSet *activeLines = [self findAllActiveLines];
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
        if (sessionId == line.sessionId) {
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
            !line.isIncoming){
            return line;
        }
    }
    return nil;
}

- (JCLineSession *)findLineWithRecevingState
{
    for (JCLineSession *line in self.lineSessions) {
        if (!line.isActive &&
            line.isIncoming){
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
            !line.isIncoming) {
            return line;
        }
    }
    return nil;
}

- (JCLineSession *)findIdleLine
{
    for (JCLineSession *line in self.lineSessions){
        if (!line.isActive &&
            !line.isIncoming){
            return line;
        }
    }
    return nil;
}

- (JCLineSession *)findTransferLine
{
    for (JCLineSession *line in self.lineSessions){
        if (line.isTransfer){
            return line;
        }
    }
    return nil;
}

- (NSSet *)findAllActiveLines
{
    NSMutableSet *activeLines = [NSMutableSet setWithCapacity:self.lineSessions.count];
    for (JCLineSession *line in self.lineSessions)
    {
        if (line.isActive) {
            [activeLines addObject:line];
        }
    }
    return activeLines;
}

- (NSSet *)findAllActiveLinesOnHold
{
    NSMutableSet *lineSessions = [NSMutableSet setWithCapacity:self.lineSessions.count];
    for (JCLineSession *line in self.lineSessions) {
        if (line.isActive && line.isHolding) {
            [lineSessions addObject:line];
        }
    }
    return lineSessions;
}

- (NSSet *)findAllActiveLinesNotHolding
{
    NSMutableSet *lineSessions = [NSMutableSet setWithCapacity:self.lineSessions.count];
    for (JCLineSession *line in self.lineSessions) {
        if (line.isActive && !line.isHolding) {
            [lineSessions addObject:line];
        }
    }
    return lineSessions;
}

#pragma mark Session State

-(void)setSessionState:(JCLineSessionState)state forSession:(JCLineSession *)lineSession event:(NSString *)event error:(NSError *)error
{
    if (!lineSession) {
        return;
    }
    
    NSLog(@"%@ Session Id: %ld", event, (long)lineSession.sessionId);
    switch (state)
    {
        case JCTransferRejected:
        case JCTransferFailed:
        {
            lineSession.transfer = NO;
            lineSession.sessionState = state;
            [_delegate sipHandler:self didFailTransferWithError:error];
            break;
        }
        case JCTransferSuccess:
        {
            [_delegate sipHandler:self didTransferCalls:self.lineSessions];
            lineSession.transfer = NO;
            lineSession.sessionState = state;
            break;
        }
        case JCCallFailed:
        case JCCallCanceled:
        {
            lineSession.active = FALSE;
            lineSession.updatable = FALSE;
            lineSession.sessionState = state;
            
            [_audioManager stop];
            
            // Notify
            if (lineSession.isIncoming){
                [MissedCall addMissedCallWithLineSession:lineSession line:_line];
            }
            [_delegate sipHandler:self willRemoveLineSession:lineSession];
            
            NSLog(@"%@", [self.lineSessions description]);
            [lineSession reset];  // clear up this line session for reuse.
            
            // Reregister is we have no active lines, and we were flagged to reregister.
            if (_reregisterAfterActiveCallEnds && !self.isActive) {
                _reregisterAfterActiveCallEnds = false;
                [self unregister];
                [self registerToLine:_line];
            }
            
            break;
        }
        
        // State when a call is initiated before we any trying, ringing, and answered events.
        // Initial State of a call
        case JCCallInitiated:
        {
            if (!self.isActive) {
                [_audioManager engageAudioSession];
            }
            
            lineSession.active = TRUE;
            lineSession.sessionState = state;
            
            // Notify
            [OutgoingCall addOutgoingCallWithLineSession:lineSession line:_line];
            [_delegate sipHandler:self didAddLineSession:lineSession];     // Notify the delegate to add a line.
            break;
        }
            
        // Session is an incoming call -> notify delegate to add it. Check Auto Answer to know if we
        // should be auto answer.
        case JCCallIncoming:
        {
            lineSession.incoming = TRUE;
            lineSession.sessionState = state;
            
            if (!self.isActive) {
                [_audioManager engageAudioSession];
            }
            
            // Notify of incoming call by starting the ringing for the incoming call.
            [_audioManager startRepeatingRingtone:YES];

            // Notify
            [_delegate sipHandler:self didAddLineSession:lineSession];     // Notify the delegate to add a line.
            if (autoAnswer) {
                autoAnswer = false;
                [_delegate sipHandler:self receivedIntercomLineSession:lineSession];
            }
            break;
        }
        case JCCallAnswerInitiated:
        {
            lineSession.incoming = NO;
            lineSession.active = YES;
            lineSession.sessionState = state;
            
            // Stop Ringing
            [_audioManager stop];
            
            // Notify
            [IncomingCall addIncommingCallWithLineSession:lineSession line:_line];
            [_delegate sipHandler:self didAnswerLineSession:lineSession];
            
            break;
        }
        case JCCallConnected:
        {
            lineSession.updatable = YES;
            lineSession.sessionState = state;
            
            // Stop Ringing
            [_audioManager stop];
            
            [self startNetworkQualityIndicatorForLineSession:lineSession];
            break;
        }
        case JCCallConference:
        {
            lineSession.conference = YES;
            lineSession.sessionState = state;
            break;
        }
        default:
            lineSession.sessionState = state;
            break;
    }
    
    [_delegate sipHandler:self didUpdateStatusForLineSessions:self.lineSessions];
    
    NSLog(@"%@", [self.lineSessions description]);
}

-(void)startNetworkQualityIndicatorForLineSession:(JCLineSession *)lineSession
{
    JCSipNetworkQualityRequestOperation *operation = [[JCSipNetworkQualityRequestOperation alloc] initWithSessionId:lineSession.sessionId portSipSdk:_mPortSIPSDK];
    __weak JCSipNetworkQualityRequestOperation *weakOperation = operation;
    operation.completionBlock = ^{
        
        if (weakOperation.isBelowNetworkThreshold) {
            [UIApplication showInfo:@"Poor Network Quality" duration:5.5];
        }

        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if (lineSession.sessionState != JCNoCall) {
                [self startNetworkQualityIndicatorForLineSession:lineSession];
            }
        });
    };
    [_operationQueue addOperation:operation];
}


-(void)setSessionState:(JCLineSessionState)state forSessionId:(long)sessionId event:(NSString *)event error:(NSError *)error
{
    JCLineSession *lineSession = [self findSession:sessionId];
    if (!lineSession)
    {
        NSLog(@"invalid session id: %ld for event: %@", sessionId, event);
        return;
    }
    
    [self setSessionState:state forSession:lineSession event:event error:error];
}

#pragma mark - Delegate Handlers -

#pragma mark JCPhoneAudioManagerDelegate -

-(void)audioSessionInteruptionDidBegin:(JCPhoneAudioManager *)manager
{
    // When we get a call that is being interuped, we place it on hold.
    JCLineSession *lineSession = [self findActiveLine];
    __autoreleasing NSError *error;
    [self holdLineSession:lineSession error:&error];
}

-(void)audioSessionInteruptionDidEnd:(JCPhoneAudioManager *)manager
{
//    [_audioManager engageAudioSession];
//    
//    NSSet *activeLines = [self findAllActiveLines];
//    for (JCLineSession *lineSession in activeLines) {
//        [_mPortSIPSDK updateCall:lineSession.sessionId enableAudio:lineSession.audio enableVideo:lineSession.video];
//        [_mPortSIPSDK muteSession:lineSession.sessionId muteIncomingAudio:FALSE muteOutgoingAudio:false muteIncomingVideo:false muteOutgoingVideo:false];
//        [_mPortSIPSDK enableAudioStreamCallback:lineSession.sessionId enable:TRUE callbackMode:AUDIOSTREAM_LOCAL_PER_CHANNEL];
//    }
//    
//    [_mPortSIPSDK muteMicrophone:FALSE];
//    [_mPortSIPSDK muteSpeaker:FALSE];
}

-(void)phoneAudioManager:(JCPhoneAudioManager *)manager didChangeAudioRouteInputType:(JCPhoneAudioManagerInputType)inputType
{
    // We have a chance to respond if we need to.
    [_delegate phoneAudioManager:manager didChangeAudioRouteInputType:inputType];
}

-(void)phoneAudioManager:(JCPhoneAudioManager *)manager didChangeAudioRouteOutputType:(JCPhoneAudioManagerOutputType)outputType
{
    // We have a chance to respond if we need to.
    [_delegate phoneAudioManager:manager didChangeAudioRouteOutputType:outputType];
}


#pragma mark PortSIP SDK Delegate Handlers -
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
	JCLineSession *lineSession = [self findIdleLine];
	if (!lineSession){
		[_mPortSIPSDK rejectCall:sessionId code:486];
		return;
	}
	
    lineSession.sessionId = sessionId;  // Attach a session id to the line session.
    lineSession.video = existsVideo;    // Flag if video call.
    
    NSString *name = [NSString stringWithUTF8String:callerDisplayName];
    NSString *number = [self formatCallDetail:[NSString stringWithUTF8String:caller]];
    lineSession.number = [self.delegate phoneNumberForNumber:number name:name];
    [self setSessionState:JCCallIncoming forSession:lineSession event:@"onInviteIncoming" error:nil];  // Set the session state.
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
	if (!selectedLine) {
		return;
	}
	
	if (existsEarlyMedia) {
		// Checking does this call has video
		if (existsVideo) {
			// This incoming call has video
			// If more than one codecs using, then they are separated with "#",
			// for example: "g.729#GSM#AMR", "H264#H263", you have to parse them by yourself.
		}
		
		if (existsAudio) {
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
	if (selectedLine && !selectedLine.mExistEarlyMedia) {
        [_audioManager startRingback];
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
	if (!selectedLine){
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
    selectedLine.audio = existsAudio;
    selectedLine.video = existsVideo;
    
	// If this is the refer call then need set it to normal
    if(selectedLine.isRefer) {
        selectedLine.refer = NO;
        selectedLine.referedSessionId = INVALID_SESSION_ID;
    }
    
    [self setSessionState:JCCallAnswered forSession:selectedLine event:@"onInviteAnswered" error:nil];
}

/**
 * If the outgoing call fails, this event is triggered.
 */
- (void)onInviteFailure:(long)sessionId reason:(char*)reason code:(int)code
{
    NSString *reasonString = [NSString stringWithCString:reason encoding:NSUTF8StringEncoding];
    NSString *event = [NSString stringWithFormat:@"onInviteFailure reason: %@ code: %i", reasonString, code];
    NSError *error = [JCSipManagerError errorWithCode:code reason:reasonString];
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

/*!
 *  This event is triggered once remote side close the call.
 */
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
        [JCBadgeManager setVoicemails:newMessageCount];
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

NSString *const kJCSipHandlerErrorDomain = @"SipErrorDomain";

@implementation JCSipManagerError

+(instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    return [self errorWithDomain:kJCSipHandlerErrorDomain code:code userInfo:userInfo];
}

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error
{
    return [self errorWithDomain:kJCSipHandlerErrorDomain code:code reason:reason underlyingError:error];
}

+(NSString *)descriptionFromCode:(NSInteger)code
{
    if (code > 0) {
        return [self sipProtocolFailureDescriptionFromCode:code];
    }
    
    return [self failureReasonFromCode:code];
}

+(NSString *)failureReasonFromCode:(NSInteger)code
{
    if (code > 0) {
        return [self sipProtocolFailureReasonFromCode:code];
    }
    
    switch (code) {
        case INVALID_SESSION_ID:
            return @"Invalid Session Id";
            
        case ECoreAlreadyInitialized:
            return @"Already Initialized";
            
        case ECoreNotInitialized:
            return @"Not Initialized";
            
        case ECoreSDKObjectNull:
            return @"SDK Object is Null";
            
        case ECoreArgumentNull:
            return @"Argument is Null";
            
        case ECoreInitializeWinsockFailure:
            return @"Initialize Winsock Failure";
            
        case ECoreUserNameAuthNameEmpty:
            return @"User Name Auth Name is Empty";
            
        case ECoreInitiazeStackFailure:
            return @"Initialize Stack Failure";
            
        case ECorePortOutOfRange:
            return @"Port out of range";
            
        case ECoreAddTcpTransportFailure:
            return @"Add TCP Transport Failure";
            
        case ECoreAddTlsTransportFailure:
            return @"Add TLS Transport Failure";
            
        case ECoreAddUdpTransportFailure:
            return @"Add UDP Transport Failure";
            
        case ECoreMiniAudioPortOutOfRange:
            return @"Mini Audio Port out of range";
            
        case ECoreMaxAudioPortOutOfRange:
            return @"Max Audio Port out of range";
            
        case ECoreMiniVideoPortOutOfRange:
            return @"Mini Video Port out of range";
            
        case ECoreMaxVideoPortOutOfRange:
            return @"Max Video Port out of range";
            
        case ECoreMiniAudioPortNotEvenNumber:
            return @"Mini Audio Port out of range";
            
        case ECoreMaxAudioPortNotEvenNumber:
            return @"Max Audio Port Not Even Number";
            
        case ECoreMiniVideoPortNotEvenNumber:
            return @"Mini Video Port Not Even Number";
            
        case ECoreMaxVideoPortNotEvenNumber:
            return @"Max Video Port Not Event Number";
            
        case ECoreAudioVideoPortOverlapped:
            return @"Audio and Video Port Overlapped";
            
        case ECoreAudioVideoPortRangeTooSmall:
            return @"Audio and Video Port Range to Small";
            
        case ECoreAlreadyRegistered:
            return @"Already Registered";
            
        case ECoreSIPServerEmpty:
            return @"Sip Server Path is Empty";
            
        case ECoreExpiresValueTooSmall:
            return @"Expires Value is to small.";
            
        case ECoreCallIdNotFound:
            return @"Call id not found.";
            
        case ECoreNotRegistered:
            return @"Not Registered";
            
        case ECoreCalleeEmpty:
            return @"Callee is empty";
            
        case ECoreInvalidUri:
            return @"Invalid URI";
            
        case ECoreAudioVideoCodecEmpty:
            return @"Audio Video Codec is empty";
            
        case ECoreNoFreeDialogSession:
            return @"No Free Dialog Session";
            
        case ECoreCreateAudioChannelFailed:
            return @"Create Audio Channel Failed";
            
        case ECoreSessionTimerValueTooSmall:
            return @"Session Timer Value is to small";
            
        case ECoreAudioHandleNull:
            return @"Audio Handle is NULL";
            
        case ECoreVideoHandleNull:
            return @"Video Handle is NULL";
            
        case ECoreCallIsClosed:
            return @"Call is Closed";
            
        case ECoreCallAlreadyHold:
            return @"Call is Already on Hold";
            
        case ECoreCallNotEstablished:
            return @"Call is not Established";
            
        case ECoreCallNotHold:
            return @"Call Not on Hold";
            
        case ECoreSipMessaegEmpty:
            return @"Sip Message is Empty";
            
        case ECoreSipHeaderNotExist:
            return @"Sip Header does not exist";
            
        case ECoreSipHeaderValueEmpty:
            return @"Sip Header value is empty";
            
        case ECoreSipHeaderBadFormed:
            return @"Sip Header is badly formed";
            
        case ECoreBufferTooSmall:
            return @"Buffer is to Small";
            
        case ECoreSipHeaderValueListEmpty:
            return @"Header Value List is empty";
            
        case ECoreSipHeaderParserEmpty:
            return @"Sip Header Parser is empty";
            
        case ECoreSipHeaderValueListNull:
            return @"Sip Header value list is NULL";
            
        case ECoreSipHeaderNameEmpty:
            return @"Sip Header name is empty";
            
        case ECoreAudioSampleNotmultiple:
            return @"Audio Sample is not multiple of 10";	//	The audio sample should be multiple of 10
            
        case ECoreAudioSampleOutOfRange:
            return @"Audio Sample Out of Range (10-60)";	//	The audio sample range is 10 - 60
            
        case ECoreInviteSessionNotFound:
            return @"Invide Session not found";
            
        case ECoreStackException:
            return @"Stack Exception";
            
        case ECoreMimeTypeUnknown:
            return @"Mime Type Unknowen";
            
        case ECoreDataSizeTooLarge:
            return @"Data Size is too large";
            
        case ECoreSessionNumsOutOfRange:
            return @"Session numbers out of range";
            
        case ECoreNotSupportCallbackMode:
            return @"Not supported callback mode";
            
        case ECoreNotFoundSubscribeId:
            return @"Not Found Subscribe Id";
            
        case ECoreCodecNotSupport:
            return @"Codec Not Supported";
            
        case ECoreCodecParameterNotSupport:
            return @"Codec parameter not supported";
            
        case ECorePayloadOutofRange:
            return @"Payload is out of range (96-127)";	//  Dynamic Payload range is 96 - 127
            
        case ECorePayloadHasExist:
            return @"Payload already exists. Duplicate payload values are not allowed";	//  Duplicate Payload values are not allowed.
            
        case ECoreFixPayloadCantChange:
            return @"Fix Payload can't change";
            
        case ECoreCodecTypeInvalid:
            return @"COde Type Invalid";
            
        case ECoreCodecWasExist:
            return @"Codec already exits";
            
        case ECorePayloadTypeInvalid:
            return @"Payload Type invalid";
            
        case ECoreArgumentTooLong:
            return @"Argument too long";
            
        case ECoreMiniRtpPortMustIsEvenNum:
            return @"Mini RTP Port is not even number";
            
        case ECoreCallInHold:
            return @"Call is in hold";
            
        case ECoreNotIncomingCall:
            return @"Not an Incomming Call";
            
        case ECoreCreateMediaEngineFailure:
            return @"Create Media Engine Failre";
            
        case ECoreAudioCodecEmptyButAudioEnabled:
            return @"Audio Codec Empty but Audio is enabled";
            
        case ECoreVideoCodecEmptyButVideoEnabled:
            return @"Video Code is Empty but video is enabled";
            
        case ECoreNetworkInterfaceUnavailable:
            return @"Network Interface is unavialable";
            
        case ECoreWrongDTMFTone:
            return @"Wrong DTMF Tone";
            
        case ECoreWrongLicenseKey:
            return @"Wrong License Key";
            
        case ECoreTrialVersionLicenseKey:
            return @"Trial Version License Key";
            
        case ECoreOutgoingAudioMuted:
            return @"Outgoing Audio is muted";
            
        case ECoreOutgoingVideoMuted:
            return @"Outgoing Video is nuted";
            
        // IVR
        case ECoreIVRObjectNull:
            return @"IVR Object is Null";
            
        case ECoreIVRIndexOutOfRange:
            return @"IVR Index is out of range";
            
        case ECoreIVRReferFailure:
            return @"IVR Refer Failure";
            
        case ECoreIVRWaitingTimeOut:
            return @"IVR Waiting Timeout";
            
        // audio
        case EAudioFileNameEmpty:
            return @"Audio File Name is empty";
            
        case EAudioChannelNotFound:
            return @"Audio Channel not found";
            
        case EAudioStartRecordFailure:
            return @"Audio start recording failure";
            
        case EAudioRegisterRecodingFailure:
            return @"Audio Register Recording Failure";
            
        case EAudioRegisterPlaybackFailure:
            return @"Audio Register Playback Failure";
            
        case EAudioGetStatisticsFailure:
            return @"Get Audio Statistics Failure";
            
        case EAudioPlayFileAlreadyEnable:
            return @"Audio Play File Already Enabled";
            
        case EAudioPlayObjectNotExist:
            return @"Audio Play Object does not Exit";
            
        case EAudioPlaySteamNotEnabled:
            return @"Audio Play stram not enabled";;
            
        case EAudioRegisterCallbackFailure:
            return @"Audio Register Callback Failure";
            
        case EAudioCreateAudioConferenceFailure:
            return @"Create Audio Conference Failure";
            
        case EAudioOpenPlayFileFailure:
            return @"Audio Open Play File Failure";
            
        case EAudioPlayFileModeNotSupport:
            return @"Audio Play File Mode not supported";
            
        case EAudioPlayFileFormatNotSupport:
            return @"Audio Play File Format not supported";
            
        case EAudioPlaySteamAlreadyEnabled:
            return @"Audio Play stream already enabled";
            
        case EAudioCreateRecordFileFailure:
            return @"Create Audio Recording Failure";
            
        case EAudioCodecNotSupport:
            return @"Audio Codec not supported";
            
        case EAudioPlayFileNotEnabled:
            return @"Audio Play File Not enabled";
            
        case EAudioPlayFileGetPositionFailure:
            return @"Audio Play File Get Position Failure";
            
        case EAudioCantSetDeviceIdDuringCall:
            return @"Can't set Audio Device Id During Call";
            
        case EAudioVolumeOutOfRange:
            return @"Audio Volume out of range";
            
        // video
        case EVideoFileNameEmpty:
            return @"Video File Name Empty";
            
        case EVideoGetDeviceNameFailure:
            return @"Video Get Device Name Failure";
            
        case EVideoGetDeviceIdFailure:
            return @"Video Get Device Id Failure";
            
        case EVideoStartCaptureFailure:
            return @"Start Video Capture Failure";
            
        case EVideoChannelNotFound:
            return @"Video Channel Not Found";
            
        case EVideoStartSendFailure:
            return @"Start Send Failure";
            
        case EVideoGetStatisticsFailure:
            return @"Get Statistics Failure";
            
        case EVideoStartPlayAviFailure:
            return @"Start Play AVI Failure";
            
        case EVideoSendAviFileFailure:
            return @"Send Avi File Failure";
            
        case EVideoRecordUnknowCodec:
            return @"Unknown Video Record Codec";
            
        case EVideoCantSetDeviceIdDuringCall:
            return @"Can't set device id durring call";
            
        case EVideoUnsupportCaptureRotate:
            return @"Unsupported Video Capture Rotation";
            
        case EVideoUnsupportCaptureResolution:
            return @"Unsupported Video Capture Resolution";
            
        // Device
        case EDeviceGetDeviceNameFailure:
            return @"Get Device Name Failure";
            
        // Manager Errors
        case JC_SIP_ALREADY_REGISTERING:
            return @"Phone is already attempting to register";
            
        case JC_SIP_REGISTRATION_TIMEOUT:
            return @"Phone registration has encountered a fatal error and requires the application to be restarted.";
            
        case JC_SIP_REGISTRATION_FAILURE:
            return @"Please try again. If the problem persists, please contact support.";
            
        default:
            return @"Unknown Error Has Occured";
            
    }
    return nil;
}

+(NSString *)sipProtocolFailureReasonFromCode:(NSInteger)code {
    switch (code) {
        case 400:
            return @"Bad Request";
        case 401:
            return @"Unauthorized";
        case 402:
            return @"Payment Required";
        case 403:
            return @"Forbidden";
        case 404:
            return @"Not Found";
        case 405:
            return @"Method Not Allowed";
        case 406:
            return @"Not Acceptable";
        case 407:
            return @"Proxy Authentication Required";
        case 408:
            return @"Request Timeout";
        case 409:
            return @"Conflict";
        case 410:
            return @"Gone";
        case 411:
            return @"Length Required";
        case 412:
            return @"Conditional Request Failed";
        case 413:
            return @"Request Entity Too Large";
        case 414:
            return @"Request-URI Too Long";
        case 415:
            return @"Unsupported Media Type";
        case 416:
            return @"Unsupported URI Scheme";
        case 417:
            return @"Unknown Resource-Priority";
        case 420:
            return @"Bad Extension";
        case 421:
            return @"Extension Required";
        case 422:
            return @"Session Interval Too Small";
        case 423:
            return @"Interval Too Brief";
        case 424:
            return @"Bad Location Information";
        case 428:
            return @"Use Identity Header";
        case 429:
            return @"Provide Referrer Identity";
        case 430:
            return @"Flow Failed";
        case 433:
            return @"Anonymity Disallowed";
        case 436:
            return @"Bad Identity-Info";
        case 437:
            return @"Unsupported Certificate";
        case 438:
            return @"Invalid Identity Header";
        case 439:
            return @"First Hop Lacks Outbound Support";
        case 470:
            return @"Consent Needed";
        case 480:
            return @"Temporarily Unavailable";
        case 481:
            return @"Call/Transaction Does Not Exist";
        case 482:
            return @"Loop Detected";
        case 483:
            return @"Too Many Hops";
        case 484:
            return @"Address Incomplete";
        case 485:
            return @"Ambiguous";
        case 486:
            return @"Busy Here";
        case 487:
            return @"Request Terminated";
        case 488:
            return @"Not Acceptable Here";
        case 489:
            return @"Bad Event";
        case 491:
            return @"Request Pending";
        case 493:
            return @"Undecipherable";
        case 494:
            return @"Security Agreement Required";
            
        // 5xx - Server Failure Responses */
        case 500:
            return @"Server Internal Error";
        case 501:
            return @"Not Implemented";
        case 502:
            return @"Bad Gateway";
        case 503:
            return @"Service Unavailable";
        case 504:
            return @"Server Time-out";
        case 505:
            return @"Version Not Supported";
        case 513:
            return @"Message Too Large";
        case 580:
            return @"Precondition Failure";
            
        // 6xx - Global Failure Responses
        case 600:
            return @"Busy Everywhere";
        case 603:
            return @"Decline";
        case 604:
            return @"Does Not Exist Anywhere";
        case 606:
            return @"Not Acceptable";
            
        default:
            return nil;
    }
}

+(NSString *)sipProtocolFailureDescriptionFromCode:(NSInteger)code {
    
    switch (code) {
            
        // 4xx - Client Failure Responses
        case 400:
            return @"Bad Request. The request could not be understood due to malformed syntax.";
        case 401:
            return @"Unauthorized. The request requires user authentication.";
        case 402:
            return @"Payment Required.";
        case 403:
            return @"Forbidden. The server understood the request, but is refusing to fulfil it.";
        case 404:
            return @"Not Found. The server has definitive information that the user does not exist at the domain specified in the Request-URI.";
        case 405:
            return @"Method Not Allowed. The method specified in the Request -Line is understood, but not allowed for the address identified by the Request-URI.";
        case 406:
            return @"Not Acceptable. The resource identified by the request is only capable of generating response entities that have content characteristics but not acceptable according to the Accept header field sent in the request.";
        case 407:
            return @"Proxy Authentication Required. The request requires user authentication.";
        case 408:
            return @"Request Timeout. Couldn't find the user in time. The server could not produce a response within a suitable amount of time, for example, if it could not determine the location of the user in time.";
        case 409:
            return @"Conflict. User already registered.";
        case 410:
            return @"Gone. The user existed once, but is not available here any more.";
        case 411:
            return @"Length Required. The server will not accept the request without a valid Content - Length.";
        case 412:
            return @"Conditional Request Failed. The given precondition has not been met.";
        case 413:
            return @"Request Entity Too Large. Request body too large.";
        case 414:
            return @"Request - URI Too Long. The server is refusing to service the request because the Request - URI is longer than the server is willing to interpret.";
        case 415:
            return @"Unsupported Media Type. Request body in a format not supported.";
        case 416:
            return @"Unsupported URI Scheme. Request - URI is unknown to the server.";
        case 417:
            return @"Unknown Resource -Priority. There was a resource - priority option tag, but no Resource-Priority header.";
        case 420:
            return @"Bad Extension. Bad SIP Protocol Extension used, not understood by the server.";
        case 421:
            return @"Extension Required. The server needs a specific extension not listed in the Supported header.";
        case 422:
            return @"Session Interval Too Small. The received request contains a Session-Expires header field with a duration below the minimum timer.";
        case 423:
            return @"Interval Too Brief. Expiration time of the resource is too short.";
        case 424:
            return @"Bad Location Information. The request's location content was malformed or otherwise unsatisfactory.";
        case 428:
            return @"Use Identity Header. The server policy requires an Identity header, and one has not been provided.";
        case 429:
            return @"Provide Referrer Identity. The server did not receive a valid Referred-By token on the request.";
        case 430:
            return @"Flow Failed. A specific flow to a user agent has failed, although other flows may succeed.";
        case 433:
            return @"Anonymity Disallowed. The request has been rejected because it was anonymous.";
        case 436:
            return @"Bad Identity -Info. The request has an Identity -Info header, and the URI scheme in that header cannot be dereferenced.";
        case 437:
            return @"Unsupported Certificate. The server was unable to validate a certificate for the domain that signed the request.";
        case 438:
            return @"Invalid Identity Header. The server obtained a valid certificate that the request claimed was used to sign the request, but was unable to verify that signature.";
        case 439:
            return @"First Hop Lacks Outbound Support. The first outbound proxy the user is attempting to register through does not support the 'outbound' feature of RFC 5626, although the registrar does.";
        case 470:
            return @"Consent Needed. The source of the request did not have the permission of the recipient to make such a request.";
        case 480:
            return @"Temporarily Unavailable. Callee currently unavailable.";
        case 481:
            return @"Call/Transaction Does Not Exist. Server received a request that does not match any dialog or transaction.";
        case 482:
            return @"Loop Detected. Server has detected a loop.";
        case 483:
            return @"Too Many Hops. Max - Forwards header has reached the value '0'.";
        case 484:
            return @"Address Incomplete. Request - URI incomplete.";
        case 485:
            return @"Ambiguous. Request - URI is ambiguous.";
        case 486:
            return @"Busy Here. Callee is busy.";
        case 487:
            return @"Request Terminated. Request has terminated by bye or cancel.";
        case 488:
            return @"Not Acceptable Here. Some aspect of the session description or the Request - URI is not acceptable.";
        case 489:
            return @"Bad Event. The server did not understand an event package specified in an Event header field.";
        case 491:
            return @"Request Pending. Server has some pending request from the same dialog.";
        case 493:
            return @"Undecipherable. Request contains an encrypted MIME body, which recipient can not decrypt.";
        case 494:
            return @"Security Agreement Required.";
            
        // 5xx - Server Failure Responses
        case 500:
            return @"Server Internal Error. The server could not fulfill the request due to some unexpected condition.";
        case 501:
            return @"Not Implemented. The server does not have the ability to fulfill the request, such as because it does not recognize the request method.";
        case 502:
            return @"Bad Gateway. The server is acting as a gateway or proxy, and received an invalid response from a downstream server while attempting to fulfill the request.";
        case 503:
            return @"Service Unavailable. The server is undergoing maintenance or is temporarily overloaded and so cannot process the request.";
        case 504:
            return @"Server Time-out. The server attempted to access another server in attempting to process the request, and did not receive a prompt response.";
        case 505:
            return @"Version Not Supported. The SIP protocol version in the request is not supported by the server.";
        case 513:
            return @"Message Too Large. The request message length is longer than the server can process.";
        case 580:
            return @"Precondition Failure. The server is unable or unwilling to meet some constraints specified in the offer.";
            
        // 6xx - Global Failure Responses
        case 600:
            return @"Busy Everywhere. All possible destinations are busy. Destination knows there are no alternative destinations (such as a voicemail server) able to accept the call.";
        case 603:
            return @"Decline. The destination does not wish to participate in the call";
        case 604:
            return @"Does Not Exist Anywhere. The server has authoritative information that the requested user does not exist anywhere.";
        case 606:
            return @"Not Acceptable. The user's agent was contacted successfully but some aspects of the session description such as the requested media, bandwidth, or addressing style were not acceptable.";
        default:
            return @"An Error has occurred. An unknown error has occured. ";
    }
    
}

@end
