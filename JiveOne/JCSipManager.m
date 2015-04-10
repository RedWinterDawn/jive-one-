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
#import "JCSipHandlerError.h"
#import "JCSipNetworkQualityRequestOperation.h"

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
                                     maxLine:_numberOfLines
                                       agent:kSipHandlerServerAgentname
                            audioDeviceLayer:IS_SIMULATOR
                            videoDeviceLayer:IS_SIMULATOR];
    
    if(errorCode) {
        _mPortSIPSDK = nil;
        _lineSessions = nil;
        if (error != NULL) {
            *error = [JCSipHandlerError errorWithCode:errorCode reason:@"Error initializing port sip sdk"];
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
            *error = [JCSipHandlerError errorWithCode:errorCode reason:@"Port Sip License Key Failure"];
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
            *error = [JCSipHandlerError errorWithCode:JC_SIP_ALREADY_REGISTERING reason:@"Already Registering"];
        }
        return FALSE;
    }
    
    // Check to see if we are on a current call. If we are, we need to exit out, and wait until the
    // call has completed before we do anything. We do not want to end the call.
    _reregisterAfterActiveCallEnds = FALSE;
    if (self.isActive) {
        _reregisterAfterActiveCallEnds = TRUE;
        if (error) {
            *error = [JCSipHandlerError errorWithCode:JC_SIP_ALREADY_REGISTERING reason:@"Already Registering"];
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
            *error = [JCSipHandlerError errorWithCode:JC_SIP_REGISTER_LINE_IS_EMPTY reason:@"Line is empty"];
        }
        return FALSE;
    }
    
    if (!line.lineConfiguration) {
        if (error) {
            *error = [JCSipHandlerError errorWithCode:JC_SIP_REGISTER_LINE_CONFIGURATION_IS_EMPTY reason:@"Line Configuration is empty"];
        }
        return FALSE;
    }
    
    if (!line.pbx) {
        if (error) {
            *error = [JCSipHandlerError errorWithCode:JC_SIP_REGISTER_LINE_PBX_IS_EMPTY reason:@"Line PBX is empty"];
        }
        return FALSE;
    }
    
    NSString *userName = line.lineConfiguration.sipUsername;
    if (!userName) {
        if (error) {
            *error = [JCSipHandlerError errorWithCode:JC_SIP_REGISTER_USER_IS_EMPTY reason:@"User is empty"];
        }
        return FALSE;
    }
    
    NSString *server = line.pbx.isV5 ? line.lineConfiguration.outboundProxy : line.lineConfiguration.registrationHost;
    if (!server) {
        if (error) {
            *error = [JCSipHandlerError errorWithCode:JC_SIP_REGISTER_SERVER_IS_EMPTY reason:@"Server is empty"];
        }
        return FALSE;
    }
    
    NSString *password = line.lineConfiguration.sipPassword;
    if (!password) {
        if (error) {
            *error = [JCSipHandlerError errorWithCode:JC_SIP_REGISTER_PASSWORD_IS_EMPTY reason:@"Password is empty"];
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
            *error = [JCSipHandlerError errorWithCode:errorCode reason:@"Error Setting the User"];
        }
        return FALSE;
    }
    
    _line = line;
    errorCode = [_mPortSIPSDK registerServer:3600 retryTimes:9];
    if(errorCode) {
        if (error) {
            *error = [JCSipHandlerError errorWithCode:errorCode reason:@"Error starting Registration"];
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
    [_delegate sipHandler:self didFailToRegisterWithError:[JCSipHandlerError errorWithCode:JC_SIP_REGISTRATION_TIMEOUT]];
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
    [_delegate sipHandler:self didFailToRegisterWithError:[JCSipHandlerError errorWithCode:statusCode reason:@"Registration failed"]];
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

- (BOOL)makeCall:(NSString *)dialString videoCall:(BOOL)videoCall error:(NSError *__autoreleasing *)error
{
	// Check to see if we can make a call. We can make a call if we have an idle line session. If we
    // do not have one, exit with error.
    JCLineSession *lineSession = [self findIdleLine];
    if (!lineSession) {
        if (error != NULL) {
            *error = [JCSipHandlerError errorWithCode:JC_SIP_CALL_NO_IDLE_LINE];
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
    NSInteger result = [_mPortSIPSDK call:dialString sendSdp:TRUE videoCall:videoCall];
    if(result <= 0) {
        if (error != NULL) {
            *error = [JCSipHandlerError errorWithCode:result reason:@"Unable to create call"];
        }
        [self setSessionState:JCCallFailed forSession:lineSession event:@"makeCall:" error:nil];
        return NO;
    }
    
    NSString *callerId = dialString;
    Contact *contact = [Contact contactForExtension:dialString pbx:_line.pbx];
    if (contact) {
        callerId = contact.extension;
    }
    
    // Configure the line session.
    lineSession.sessionId = result;
    [lineSession setCallTitle:callerId];
    [lineSession setCallDetail:dialString];
    
    [self setSessionState:JCCallInitiated forSession:lineSession event:@"Initiating Call" error:nil];
    return YES;
}

- (BOOL)answerSession:(JCLineSession *)lineSession error:(NSError *__autoreleasing *)error
{
    if (!lineSession) {
        if (error != NULL) {
            *error = [JCSipHandlerError errorWithCode:JC_SIP_LINE_SESSION_IS_EMPTY reason:@"Line Session in empty"];
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
            *error = [JCSipHandlerError errorWithCode:errorCode reason:@"Unable to answer the call"];
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
                *error = [JCSipHandlerError errorWithCode:errorCode reason:@"Error trying to manually reject incomming call"];
            }
            return NO;
        }
            
        [self setSessionState:JCCallCanceled forSession:lineSession event:@"Manually Rejected Incoming Call" error:nil];
        return YES;
    }
    
    NSInteger errorCode = [_mPortSIPSDK hangUp:lineSession.sessionId];
    if (errorCode) {
        if (error != NULL) {
            *error = [JCSipHandlerError errorWithCode:errorCode reason:@"Error Trying to Hang up"];
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
            *error = [JCSipHandlerError errorWithCode:holdError.code reason:@"Error holding the line sessions" underlyingError:holdError];
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
            *error = [JCSipHandlerError errorWithCode:errorCode reason:@"Error placing calls on hold"];
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
            *error = [JCSipHandlerError errorWithCode:holdError.code reason:@"Error unholding the line session while after joing the conference" underlyingError:holdError];
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
            *error = [JCSipHandlerError errorWithCode:errorCode reason:@"Error placing calls on hold"];
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
            *error = [JCSipHandlerError errorWithCode:JC_SIP_CONFERENCE_CALL_ALREADY_STARTED reason:@"Conference call already started"];
        }
        return FALSE;
    }
    
    NSInteger errorCode = [_mPortSIPSDK createConference:[UIView new] videoResolution:VIDEO_NONE displayLocalVideo:NO];
    if (errorCode) {
        if (error != NULL) {
            *error = [JCSipHandlerError errorWithCode:errorCode reason:@"Error Creating Conference"];
        }
        return false;
    }
    
    _conferenceCall = true;
    for (JCLineSession *lineSession in lineSessions) {
        
        if (lineSession.isHolding) {
            __autoreleasing NSError *holdError;
            if (![self unholdLineSession:lineSession error:&holdError]) {
                if (error != NULL) {
                    *error = [JCSipHandlerError errorWithCode:holdError.code reason:@"Error unholding the line session while after joing the conference" underlyingError:holdError];
                }
                break;
            }
        }
        
        errorCode = [_mPortSIPSDK joinToConference:lineSession.sessionId];
        if (errorCode) {
            if (error != NULL) {
                *error = [JCSipHandlerError errorWithCode:errorCode reason:@"Error Joining line session to conference"];
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
            *error = [JCSipHandlerError errorWithCode:JC_SIP_CONFERENCE_CALL_ALREADY_ENDED reason:@"Conference call already started"];
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
                        *error = [JCSipHandlerError errorWithCode:holdError.code reason:@"Error placing calls on hold after ending a conference" underlyingError:holdError];
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

- (BOOL)startBlindTransferToNumber:(NSString *)number error:(NSError *__autoreleasing *)error
{
    // Find the active line. It is the one we will be refering to the number passed.
	JCLineSession *b = [self findActiveLine];
    if (!b) {
        if (error != NULL) {
            *error = [JCSipHandlerError errorWithCode:JC_SIP_CALL_NO_ACTIVE_LINE];
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
	NSInteger errorCode = [_mPortSIPSDK refer:b.sessionId referTo:number];
    if (errorCode) {
        if (error != NULL) {
            *error = [JCSipHandlerError errorWithCode:errorCode];
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
-(BOOL)startWarmTransferToNumber:(NSString *)number error:(NSError *__autoreleasing *)error
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
            *error = [JCSipHandlerError errorWithCode:JC_SIP_CALL_NO_ACTIVE_LINE];
        }
        return NO;
    }
    
    JCLineSession *b = [self findTransferLine];
    if (!b) {
        if (error != NULL) {
            *error = [JCSipHandlerError errorWithCode:JC_SIP_CALL_NO_REFERRAL_LINE];
        }
        return NO;
    }
    
    NSInteger errorCode = [_mPortSIPSDK attendedRefer:c.sessionId replaceSessionId:b.sessionId referTo:c.callDetail];
    if (errorCode) {
        if(error != NULL) {
            *error = [JCSipHandlerError errorWithCode:errorCode];
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
        NSError *error = [JCSipHandlerError errorWithCode:errorCode];
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
    NSError *error = [JCSipHandlerError errorWithCode:code reason:[NSString stringWithCString:reason encoding:NSUTF8StringEncoding]];
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
    NSError *error = [JCSipHandlerError errorWithCode:code reason:[NSString stringWithCString:reason encoding:NSUTF8StringEncoding]];
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
            lineSession.contact = [Contact contactForExtension:lineSession.callDetail pbx:_line.pbx];
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
            lineSession.contact = [Contact contactForExtension:lineSession.callDetail pbx:_line.pbx];
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
    
    [self setSessionState:state forSession:[self findSession:sessionId] event:event error:error];
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
	
    // Setup the line session.
    lineSession.sessionId = sessionId;      // Attach a session id to the line session.
    lineSession.video = existsVideo;    // Flag if video call.
	[lineSession setCallTitle:[NSString stringWithUTF8String:callerDisplayName]];                      // Get Call Title
	[lineSession setCallDetail:[self formatCallDetail:[NSString stringWithUTF8String:caller]]];        // Get Call Detail.
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

