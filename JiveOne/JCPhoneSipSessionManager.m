//
//  SipManager.m
//  JiveOne
//
//  The Sip Handler server as a wrapper to the port sip SDK and manages Line Session objects.
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneSipSessionManager.h"
#import "JCPhoneSipSessionNetworkQualityRequestOperation.h"

// Libraries
#import <PortSIPLib/PortSIPSDK.h>

// Managers
#import "JCBadgeManager.h"          // Sip directly reports voicemail count for v4 clients to badge manager
#import "JCPhoneAudioManager.h"     // Sip directly interacts with the audio session.

// View Controllers
#import "JCPhoneVideoViewController.h"

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
#define PHONE_STRINGS_NAME @"Phone"

NSString *const kSipHandlerAutoAnswerModeAutoHeader = @"Answer-Mode: auto";
NSString *const kSipHandlerAutoAnswerInfoIntercomHeader = @"Alert-Info: Intercom";
NSString *const kSipHandlerAutoAnswerAfterIntervalHeader = @"answer-after=0";

NSString *const kSipHandlerServerAgentname = @"Jive iOS Client";
NSString *const kSipHandlerRegisteredSelectorKey = @"registered";

@interface JCPhoneSipSessionManager() <PortSIPEventDelegate, JCPhoneAudioManagerDelegate>
{
    PortSIPSDK *_mPortSIPSDK;
    JCPhoneVideoViewController *_videoController;
    NSOperationQueue *_operationQueue;
	BOOL _autoAnswer;
    
    NSTimer *_registrationTimeoutTimer;
    NSTimeInterval _registrationTimeoutInterval;
    BOOL _reregisterAfterActiveCallEnds;
    NSUInteger _numberOfLines;
}

@property (nonatomic) NSMutableSet *lineSessions;

- (JCPhoneSipSession *)findSession:(long)sessionId;

@end

@implementation JCPhoneSipSessionManager

-(instancetype)initWithNumberOfLines:(NSUInteger)lines audioManager:(JCPhoneAudioManager *)audioManager delegate:(id<JCPhoneSipSessionManagerDelegate>)delegate error:(NSError *__autoreleasing *)error
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        
        _lineSessions = [NSMutableSet new];
        for (int i = 0; i < lines; i++)
            [_lineSessions addObject:[JCPhoneSipSession new]];
        
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.name = @"SipHandler Operation Queue";
        
        _audioManager = audioManager;
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

-(BOOL)registerToProvisioning:(id<JCPhoneProvisioningDataSource>)provisioning
{
    __autoreleasing NSError *error;
    BOOL registered = [self registerToProvisioning:provisioning error:&error];
    if (!registered) {
        [_delegate sipHandler:self didFailToRegisterWithError:error];
    }
    return registered;
}

-(void)unregister
{
    __autoreleasing NSError *error;
    for (JCPhoneSipSession *lineSession in _lineSessions) {
        [self hangUpSession:lineSession error:&error];
    }
    
    [_mPortSIPSDK unRegisterServer];
    [_mPortSIPSDK unInitialize];
    _registered = FALSE;
    [_delegate sipHandlerDidUnregister:self];
}

-(void)reRegister
{
    [self unregister];
    [self registerToProvisioning:_provisioning];
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
            *error = [JCSipManagerError errorWithCode:errorCode];
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
            *error = [JCSipManagerError errorWithCode:errorCode];
        }
        return FALSE;
    }
    
    // Configure codecs. These return error codes, but are not critical if they fail.
    
    // Used Audio Codecs
    [_mPortSIPSDK addAudioCodec:AUDIOCODEC_PCMU];
    [_mPortSIPSDK addAudioCodec:AUDIOCODEC_G729];
    [_mPortSIPSDK addAudioCodec:AUDIOCODEC_G722];
    [_mPortSIPSDK addAudioCodec:AUDIOCODEC_PCMA];
    [_mPortSIPSDK addAudioCodec:AUDIOCODEC_OPUS];
    
    // Not used Audio Codecs
    //[_mPortSIPSDK addAudioCodec:AUDIOCODEC_SPEEX];
    
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
    
    _videoController = [JCPhoneVideoViewController new];
    _initialized = TRUE;
    return TRUE;
}

-(BOOL)registerToProvisioning:(id<JCPhoneProvisioningDataSource>)provisioning error:(NSError *__autoreleasing *)error;
{
    // Check if we are already registering.
    if (_registering) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_ALREADY_REGISTERING];
        }
        return FALSE;
    }
    
    // Check to see if we are on a current call. If we are, we need to exit out, and wait until the
    // call has completed before we do anything. We do not want to end the call.
    _reregisterAfterActiveCallEnds = FALSE;
    if (self.isActive) {
        _reregisterAfterActiveCallEnds = TRUE;
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_ALREADY_REGISTERING];
        }
        return FALSE;
    }
    
    // If we are registered to a line, we need to unregister from that line, and reconnect.
    if (_registered && _provisioning != provisioning) {
        [self unregister];
    }
    
    BOOL initialized = [self initialize:error];
    if (!initialized) {
        return FALSE;
    }
    
    if (!provisioning) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_REGISTER_LINE_IS_EMPTY];
        }
        return FALSE;
    }
    
    if (!provisioning.isProvisioned) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_REGISTER_LINE_CONFIGURATION_IS_EMPTY];
        }
        return FALSE;
    }
    
    NSString *userName = provisioning.username;
    if (!userName) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_REGISTER_USER_IS_EMPTY];
        }
        return FALSE;
    }
    
    NSString *server = provisioning.server;
    if (!server) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_REGISTER_SERVER_IS_EMPTY];
        }
        return FALSE;
    }
    
    NSString *password = provisioning.password;
    if (!password) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_REGISTER_PASSWORD_IS_EMPTY];
        }
        return FALSE;
    }
    
    NSString *ouboundProxy = provisioning.outboundProxy;

    
    int errorCode = [_mPortSIPSDK setUser:userName
                              displayName:provisioning.displayName
                                 authName:userName
                                 password:password
                                  localIP:@"0.0.0.0"                      // Auto select IP address
                             localSIPPort:(10000 + arc4random()%1000)     // Generate a random port in the 10,000 range
                               userDomain:server
                                SIPServer:ouboundProxy
                            SIPServerPort:OUTBOUND_SIP_SERVER_PORT
                               STUNServer:@""
                           STUNServerPort:0
                           outboundServer:@""
                       outboundServerPort:0];
    
    
    
    if(errorCode) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:errorCode];
        }
        return FALSE;
    }
    
    _provisioning = provisioning;
    errorCode = [_mPortSIPSDK registerServer:3600 retryTimes:9];
    if(errorCode) {
        if (error) {
            *error = [JCSipManagerError errorWithCode:errorCode];
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
        [_audioManager checkState];
    }
    
    if (!self.isActive && !_registered && _provisioning) {
        [self registerToProvisioning:_provisioning];
    }
}

#pragma mark - Line Session Public Methods -

- (BOOL)makeCall:(id<JCPhoneNumberDataSource>)number videoCall:(BOOL)videoCall error:(NSError *__autoreleasing *)error
{
	// Check to see if we can make a call. We can make a call if we have an idle line session. If we
    // do not have one, exit with error.
    JCPhoneSipSession *lineSession = [self findIdleLine];
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
            *error = [JCSipManagerError errorWithCode:JC_SIP_MAKE_CALL_ERROR
                                      underlyingError:[JCSipManagerError errorWithCode:result]];
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

- (BOOL)answerSession:(JCPhoneSipSession *)lineSession error:(NSError *__autoreleasing *)error
{
    if (!lineSession) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_LINE_SESSION_IS_EMPTY];
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
            *error = [JCSipManagerError errorWithCode:JC_SIP_ANSWER_CALL_ERROR
                                      underlyingError:[JCSipManagerError errorWithCode:errorCode]];
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
    for (JCPhoneSipSession *lineSession in lineSessions) {
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

- (BOOL)hangUpSession:(JCPhoneSipSession *)lineSession error:(NSError *__autoreleasing *)error
{
    if (lineSession.incoming)
    {
        int errorCode = [_mPortSIPSDK rejectCall:lineSession.sessionId code:486];
        if (errorCode) {
            if(error != NULL) {
                *error = [JCSipManagerError errorWithCode:JC_SIP_REJECT_CALL_ERROR
                                          underlyingError:[JCSipManagerError errorWithCode:errorCode]];
            }
            return NO;
        }
            
        [self setSessionState:JCCallCanceled forSession:lineSession event:@"Manually Rejected Incoming Call" error:nil];
        return YES;
    }
    
    NSInteger errorCode = [_mPortSIPSDK hangUp:lineSession.sessionId];
    if (errorCode) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_HANGUP_CALL_ERROR
                                      underlyingError:[JCSipManagerError errorWithCode:errorCode]];
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
    for (JCPhoneSipSession *lineSession in lineSessions) {
        if (![self holdLineSession:lineSession error:&holdError]) {
            break;
        }
    }
    
    if (holdError) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_HOLD_CALLS_ERROR
                                      underlyingError:holdError];
        }
        return false;
    }
    return true;
}

- (BOOL)holdLineSession:(JCPhoneSipSession *)lineSession error:(NSError *__autoreleasing *)error
{
    if (lineSession.isHolding) {
        return YES;
    }
    
    NSInteger errorCode = [_mPortSIPSDK hold:lineSession.sessionId];
    if (errorCode) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_HOLD_CALL_ERROR
                                      underlyingError:[JCSipManagerError errorWithCode:errorCode]];
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
    for (JCPhoneSipSession *lineSession in lineSessions) {
        if (![self unholdLineSession:lineSession error:&holdError]) {
            break;
        }
    }
    
    if (holdError) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_UNHOLD_CALLS_ERROR
                                      underlyingError:holdError];
        }
        return FALSE;
    }
    return TRUE;
}

-(BOOL)unholdLineSession:(JCPhoneSipSession *)lineSession error:(NSError *__autoreleasing *)error
{
    if (!lineSession.isHolding) {
        return YES;
    }
    
    NSInteger errorCode = [_mPortSIPSDK unHold:lineSession.sessionId];
    if (errorCode) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_UNHOLD_CALL_ERROR
                                      underlyingError:[JCSipManagerError errorWithCode:errorCode]];
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
            *error = [JCSipManagerError errorWithCode:JC_SIP_CONFERENCE_CALL_ALREADY_STARTED];
        }
        return FALSE;
    }
    
    NSInteger errorCode = [_mPortSIPSDK createConference:[UIView new] videoResolution:VIDEO_NONE displayLocalVideo:NO];
    if (errorCode) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_CONFERENCE_CALL_CREATION_ERROR
                                      underlyingError:[JCSipManagerError errorWithCode:errorCode]];
        }
        return false;
    }
    
    _conferenceCall = true;
    for (JCPhoneSipSession *lineSession in lineSessions) {
        
        if (lineSession.isHolding) {
            __autoreleasing NSError *holdError;
            if (![self unholdLineSession:lineSession error:&holdError]) {
                if (error != NULL) {
                    *error = [JCSipManagerError errorWithCode:JC_SIP_CONFERENCE_CALL_UNHOLD_CALL_START_ERROR
                                              underlyingError:holdError];
                }
                break;
            }
        }
        
        errorCode = [_mPortSIPSDK joinToConference:lineSession.sessionId];
        if (errorCode) {
            if (error != NULL) {
                *error = [JCSipManagerError errorWithCode:JC_SIP_CONFERENCE_CALL_ADD_CALL_ERROR
                                          underlyingError:[JCSipManagerError errorWithCode:errorCode]];
            }
            break;
        }
        
        [self setSessionState:JCCallConference forSession:lineSession event:nil error:nil];
    }
    
    if (!errorCode) {
        [_delegate sipHandler:self didCreateConferenceCallWithSessions:lineSessions];
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
            *error = [JCSipManagerError errorWithCode:JC_SIP_CONFERENCE_CALL_ALREADY_ENDED];
        }
        return FALSE;
    }
    
    // Before stop the conference, MUST place all lines to hold state
    if (lineSessions.count > 1) {
        for (JCPhoneSipSession *lineSession in lineSessions) {
            if (!lineSession.isHolding){
                __autoreleasing NSError *holdError;
                if(![self holdLineSession:lineSession error:&holdError]) {
                    if (error != NULL) {
                        *error = [JCSipManagerError errorWithCode:JC_SIP_CONFERENCE_CALL_END_CALL_HOLD_ERROR
                                                  underlyingError:holdError];
                    }
                    return false;
                }
            }
            lineSession.conference = FALSE;
            [self setSessionState:JCCallConnected forSession:lineSession event:nil error:nil];
        }
    } else {
        JCPhoneSipSession *lineSession = lineSessions.allObjects.firstObject;
        lineSession.conference = FALSE;
        [self setSessionState:JCCallConnected forSession:lineSession event:nil error:nil];
    }
    
    [_mPortSIPSDK destroyConference];
    _conferenceCall = FALSE;
    [_delegate sipHandler:self didEndConferenceCallForSessions:lineSessions];
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
    JCPhoneSipSession *session = [self findActiveLine];
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
	JCPhoneSipSession *b = [self findActiveLine];
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
    JCPhoneSipSession *b = [self findActiveLine];
    b.transfer = TRUE;
    return [self makeCall:number videoCall:NO error:error];
}

-(BOOL)finishWarmTransfer:(NSError *__autoreleasing *)error
{
    JCPhoneSipSession *c = [self findActiveLine];
    if (!c) {
        if (error != NULL) {
            *error = [JCSipManagerError errorWithCode:JC_SIP_CALL_NO_ACTIVE_LINE];
        }
        return NO;
    }
    
    JCPhoneSipSession *b = [self findTransferLine];
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
    
    JCPhoneSipSession *a = [self findSession:sessionId];
    JCPhoneSipSession *c = [self findIdleLine];
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
    JCPhoneSipSession *lineSession = [self findSession:sessionId];
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

- (JCPhoneSipSession *)findSession:(long)sessionId
{
    for (JCPhoneSipSession *line in self.lineSessions) {
        if (sessionId == line.sessionId) {
            return line;
        }
    }
    return nil;
}

- (JCPhoneSipSession *)findActiveLine
{
    for (JCPhoneSipSession *line in self.lineSessions) {
        if (line.isActive &&
            !line.isHolding &&
            !line.isIncoming){
            return line;
        }
    }
    return nil;
}

- (JCPhoneSipSession *)findLineWithRecevingState
{
    for (JCPhoneSipSession *line in self.lineSessions) {
        if (!line.isActive &&
            line.isIncoming){
            return line;
        }
    }
    return nil;
}

- (JCPhoneSipSession *)findLineWithHoldState
{
    for (JCPhoneSipSession *line in self.lineSessions) {
        if (line.isActive &&
            line.isHolding &&
            !line.isIncoming) {
            return line;
        }
    }
    return nil;
}

- (JCPhoneSipSession *)findIdleLine
{
    for (JCPhoneSipSession *line in self.lineSessions){
        if (!line.isActive &&
            !line.isIncoming){
            return line;
        }
    }
    return nil;
}

- (JCPhoneSipSession *)findTransferLine
{
    for (JCPhoneSipSession *line in self.lineSessions){
        if (line.isTransfer){
            return line;
        }
    }
    return nil;
}

- (NSSet *)findAllActiveLines
{
    NSMutableSet *activeLines = [NSMutableSet setWithCapacity:self.lineSessions.count];
    for (JCPhoneSipSession *line in self.lineSessions)
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
    for (JCPhoneSipSession *line in self.lineSessions) {
        if (line.isActive && line.isHolding) {
            [lineSessions addObject:line];
        }
    }
    return lineSessions;
}

- (NSSet *)findAllActiveLinesNotHolding
{
    NSMutableSet *lineSessions = [NSMutableSet setWithCapacity:self.lineSessions.count];
    for (JCPhoneSipSession *line in self.lineSessions) {
        if (line.isActive && !line.isHolding) {
            [lineSessions addObject:line];
        }
    }
    return lineSessions;
}

#pragma mark Session State

-(void)setSessionState:(JCPhoneSipSessionState)state forSession:(JCPhoneSipSession *)lineSession event:(NSString *)event error:(NSError *)error
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

            [_delegate sipHandler:self willRemoveSession:lineSession];
            
            NSLog(@"%@", [self.lineSessions description]);
            [lineSession reset];  // clear up this line session for reuse.
            
            // Reregister is we have no active lines, and we were flagged to reregister.
            if (_reregisterAfterActiveCallEnds && !self.isActive) {
                _reregisterAfterActiveCallEnds = false;
                [self reRegister];
            }
            
            break;
        }
        
        // State when a call is initiated before we any trying, ringing, and answered events.
        // Initial State of a call
        case JCCallInitiated:
        {
            if (!self.isActive) {
//                [_audioManager engageAudioSession];
                [_audioManager playRingback];

            }
            
            lineSession.active = TRUE;
            lineSession.sessionState = state;
            
            // Notify
            [_delegate sipHandler:self didAddSession:lineSession];     // Notify the delegate to add a line.
            break;
        }
            
        // Session is an incoming call -> notify delegate to add it. Check Auto Answer to know if we
        // should be auto answer.
        case JCCallIncoming:
        {
            lineSession.incoming = TRUE;
            lineSession.sessionState = state;
            
            if (!self.isActive) {
//                [_audioManager engageAudioSession];
                [_audioManager playIncomingCallTone];
            }
            
            // Notify of incoming call by starting the ringing for the incoming call.
//            [_audioManager startRepeatingRingtone:YES];
            [_audioManager playIncomingCallTone];


            // Notify
            [_delegate sipHandler:self didAddSession:lineSession];     // Notify the delegate to add a line.
            if (_autoAnswer) {
                _autoAnswer = false;
                [_delegate sipHandler:self receivedIntercomSession:lineSession];
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
            [_delegate sipHandler:self didAnswerSession:lineSession];
            
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
    
    [_delegate sipHandler:self didUpdateStatusForSessions:self.lineSessions];
    
    NSLog(@"%@", [self.lineSessions description]);
}

-(void)startNetworkQualityIndicatorForLineSession:(JCPhoneSipSession *)lineSession
{
    JCPhoneSipSessionNetworkQualityRequestOperation *operation = [[JCPhoneSipSessionNetworkQualityRequestOperation alloc] initWithSessionId:lineSession.sessionId portSipSdk:_mPortSIPSDK];
    __weak JCPhoneSipSessionNetworkQualityRequestOperation *weakOperation = operation;
    operation.completionBlock = ^{
        
        if (weakOperation.isBelowNetworkThreshold) {
            [UIApplication showInfo:NSLocalizedStringFromTable(@"Poor Network Quality", PHONE_STRINGS_NAME, @"Network Quality Indicator Popover Text")
                           duration:5.5];
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


-(void)setSessionState:(JCPhoneSipSessionState)state forSessionId:(long)sessionId event:(NSString *)event error:(NSError *)error
{
    JCPhoneSipSession *lineSession = [self findSession:sessionId];
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
    JCPhoneSipSession *lineSession = [self findActiveLine];
    __autoreleasing NSError *error;
    [self holdLineSession:lineSession error:&error];
    
    [_operationQueue cancelAllOperations];
    [UIApplication hideStatus];
}

-(void)audioSessionInteruptionDidEnd:(JCPhoneAudioManager *)manager
{
    NSSet *activeLineSessions = [self findAllActiveLines];
    for (JCPhoneSipSession *lineSession in activeLineSessions) {
        [self startNetworkQualityIndicatorForLineSession:lineSession];
    }
    
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
	JCPhoneSipSession *lineSession = [self findIdleLine];
    BOOL incomingCallsEnabled = [self.delegate shouldReceiveIncomingLineSession:self];
	if (!lineSession || !incomingCallsEnabled){
		[_mPortSIPSDK rejectCall:sessionId code:486];
		return;
	}
	
    lineSession.sessionId = sessionId;  // Attach a session id to the line session.
    lineSession.video = existsVideo;    // Flag if video call.
    
    NSString *name = [NSString stringWithUTF8String:callerDisplayName];
    NSString *number = [self formatCallDetail:[NSString stringWithUTF8String:caller]];
    lineSession.number = [self.delegate sipHandler:self phoneNumberForNumber:number name:name];
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
	JCPhoneSipSession *selectedLine = [self findSession:sessionId];
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
    JCPhoneSipSession *selectedLine = [self findSession:sessionId];
	if (selectedLine && !selectedLine.mExistEarlyMedia) {
//        [_audioManager startRingback];
        [_audioManager playRingback];
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
	JCPhoneSipSession *selectedLine = [self findSession:sessionId];
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
    
    if (code == 503)
    {
        [self reRegister];
    }
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
		_autoAnswer = true;
	}
	else {
		_autoAnswer = false;
	}
}

- (void)onSendingSignaling:(long)sessionId message:(char*)message
{
	// TODO: Implement.
    
    // This event will be fired when the SDK sent a SIP message
	// you can use signaling to access the SIP message.
//    NSLog(@"%ld - %s", sessionId, message);
}

- (void)onWaitingVoiceMessage:(char*)messageAccount
		urgentNewMessageCount:(int)urgentNewMessageCount
		urgentOldMessageCount:(int)urgentOldMessageCount
			  newMessageCount:(int)newMessageCount
			  oldMessageCount:(int)oldMessageCount
{
    if (!_provisioning.isV5) {
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
            return NSLocalizedStringFromTable(@"Invalid Session Id", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreAlreadyInitialized:
            return NSLocalizedStringFromTable(@"Already Initialized", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreNotInitialized:
            return NSLocalizedStringFromTable(@"Not Initialized", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreSDKObjectNull:
            return NSLocalizedStringFromTable(@"SDK Object is Null", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreArgumentNull:
            return NSLocalizedStringFromTable(@"Argument is Null", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreInitializeWinsockFailure:
            return NSLocalizedStringFromTable(@"Initialize Winsock Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreUserNameAuthNameEmpty:
            return NSLocalizedStringFromTable(@"User Name Auth Name is Empty", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreInitiazeStackFailure:
            return NSLocalizedStringFromTable(@"Initialize Stack Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECorePortOutOfRange:
            return NSLocalizedStringFromTable(@"Port out of range", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreAddTcpTransportFailure:
            return NSLocalizedStringFromTable(@"Add TCP Transport Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreAddTlsTransportFailure:
            return NSLocalizedStringFromTable(@"Add TLS Transport Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreAddUdpTransportFailure:
            return NSLocalizedStringFromTable(@"Add UDP Transport Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreMiniAudioPortOutOfRange:
            return NSLocalizedStringFromTable(@"Mini Audio Port out of range", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreMaxAudioPortOutOfRange:
            return NSLocalizedStringFromTable(@"Max Audio Port out of range", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreMiniVideoPortOutOfRange:
            return NSLocalizedStringFromTable(@"Mini Video Port out of range", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreMaxVideoPortOutOfRange:
            return NSLocalizedStringFromTable(@"Max Video Port out of range", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreMiniAudioPortNotEvenNumber:
            return NSLocalizedStringFromTable(@"Mini Audio Port out of range", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreMaxAudioPortNotEvenNumber:
            return NSLocalizedStringFromTable(@"Max Audio Port Not Even Number", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreMiniVideoPortNotEvenNumber:
            return NSLocalizedStringFromTable(@"Mini Video Port Not Even Number", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreMaxVideoPortNotEvenNumber:
            return NSLocalizedStringFromTable(@"Max Video Port Not Event Number", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreAudioVideoPortOverlapped:
            return NSLocalizedStringFromTable(@"Audio and Video Port Overlapped", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreAudioVideoPortRangeTooSmall:
            return NSLocalizedStringFromTable(@"Audio and Video Port Range to Small", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreAlreadyRegistered:
            return NSLocalizedStringFromTable(@"Already Registered", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreSIPServerEmpty:
            return NSLocalizedStringFromTable(@"Sip Server Path is Empty", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreExpiresValueTooSmall:
            return NSLocalizedStringFromTable(@"Expires Value is to small.", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreCallIdNotFound:
            return NSLocalizedStringFromTable(@"Call id not found.", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreNotRegistered:
            return NSLocalizedStringFromTable(@"Not Registered", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreCalleeEmpty:
            return NSLocalizedStringFromTable(@"Callee is empty", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreInvalidUri:
            return NSLocalizedStringFromTable(@"Invalid URI", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreAudioVideoCodecEmpty:
            return NSLocalizedStringFromTable(@"Audio Video Codec is empty", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreNoFreeDialogSession:
            return NSLocalizedStringFromTable(@"No Free Dialog Session", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreCreateAudioChannelFailed:
            return NSLocalizedStringFromTable(@"Create Audio Channel Failed", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreSessionTimerValueTooSmall:
            return NSLocalizedStringFromTable(@"Session Timer Value is to small", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreAudioHandleNull:
            return NSLocalizedStringFromTable(@"Audio Handle is NULL", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreVideoHandleNull:
            return NSLocalizedStringFromTable(@"Video Handle is NULL", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreCallIsClosed:
            return NSLocalizedStringFromTable(@"Call is Closed", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreCallAlreadyHold:
            return NSLocalizedStringFromTable(@"Call is Already on Hold", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreCallNotEstablished:
            return NSLocalizedStringFromTable(@"Call is not Established", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreCallNotHold:
            return NSLocalizedStringFromTable(@"Call Not on Hold", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreSipMessaegEmpty:
            return NSLocalizedStringFromTable(@"Sip Message is Empty", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreSipHeaderNotExist:
            return NSLocalizedStringFromTable(@"Sip Header does not exist", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreSipHeaderValueEmpty:
            return NSLocalizedStringFromTable(@"Sip Header value is empty", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreSipHeaderBadFormed:
            return NSLocalizedStringFromTable(@"Sip Header is badly formed", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreBufferTooSmall:
            return NSLocalizedStringFromTable(@"Buffer is to Small", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreSipHeaderValueListEmpty:
            return NSLocalizedStringFromTable(@"Header Value List is empty", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreSipHeaderParserEmpty:
            return NSLocalizedStringFromTable(@"Sip Header Parser is empty", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreSipHeaderValueListNull:
            return NSLocalizedStringFromTable(@"Sip Header value list is NULL", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreSipHeaderNameEmpty:
            return NSLocalizedStringFromTable(@"Sip Header name is empty", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreAudioSampleNotmultiple:
            return NSLocalizedStringFromTable(@"Audio Sample is not multiple of 10", PHONE_STRINGS_NAME, @"Port Sip Error");	//	The audio sample should be multiple of 10
            
        case ECoreAudioSampleOutOfRange:
            return NSLocalizedStringFromTable(@"Audio Sample Out of Range (10-60)", PHONE_STRINGS_NAME, @"Port Sip Error");	//	The audio sample range is 10 - 60
            
        case ECoreInviteSessionNotFound:
            return NSLocalizedStringFromTable(@"Invide Session not found", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreStackException:
            return NSLocalizedStringFromTable(@"Stack Exception", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreMimeTypeUnknown:
            return NSLocalizedStringFromTable(@"Mime Type Unknown", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreDataSizeTooLarge:
            return NSLocalizedStringFromTable(@"Data Size is too large", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreSessionNumsOutOfRange:
            return NSLocalizedStringFromTable(@"Session numbers out of range", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreNotSupportCallbackMode:
            return NSLocalizedStringFromTable(@"Not supported callback mode", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreNotFoundSubscribeId:
            return NSLocalizedStringFromTable(@"Not Found Subscribe Id", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreCodecNotSupport:
            return NSLocalizedStringFromTable(@"Codec Not Supported", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreCodecParameterNotSupport:
            return NSLocalizedStringFromTable(@"Codec parameter not supported", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECorePayloadOutofRange:
            return NSLocalizedStringFromTable(@"Payload is out of range (96-127)", PHONE_STRINGS_NAME, @"Port Sip Error");	//  Dynamic Payload range is 96 - 127
            
        case ECorePayloadHasExist:
            return NSLocalizedStringFromTable(@"Payload already exists. Duplicate payload values are not allowed", PHONE_STRINGS_NAME, @"Port Sip Error");	//  Duplicate Payload values are not allowed.
            
        case ECoreFixPayloadCantChange:
            return NSLocalizedStringFromTable(@"Fix Payload can't change", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreCodecTypeInvalid:
            return NSLocalizedStringFromTable(@"COde Type Invalid", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreCodecWasExist:
            return NSLocalizedStringFromTable(@"Codec already exits", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECorePayloadTypeInvalid:
            return NSLocalizedStringFromTable(@"Payload Type invalid", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreArgumentTooLong:
            return NSLocalizedStringFromTable(@"Argument too long", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreMiniRtpPortMustIsEvenNum:
            return NSLocalizedStringFromTable(@"Mini RTP Port is not even number", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreCallInHold:
            return NSLocalizedStringFromTable(@"Call is in hold", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreNotIncomingCall:
            return NSLocalizedStringFromTable(@"Not an Incomming Call", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreCreateMediaEngineFailure:
            return NSLocalizedStringFromTable(@"Create Media Engine Failre", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreAudioCodecEmptyButAudioEnabled:
            return NSLocalizedStringFromTable(@"Audio Codec Empty but Audio is enabled", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreVideoCodecEmptyButVideoEnabled:
            return NSLocalizedStringFromTable(@"Video Code is Empty but video is enabled", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreNetworkInterfaceUnavailable:
            return NSLocalizedStringFromTable(@"Network Interface is unavialable", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreWrongDTMFTone:
            return NSLocalizedStringFromTable(@"Wrong DTMF Tone", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreWrongLicenseKey:
            return NSLocalizedStringFromTable(@"Wrong License Key", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreTrialVersionLicenseKey:
            return NSLocalizedStringFromTable(@"Trial Version License Key", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreOutgoingAudioMuted:
            return NSLocalizedStringFromTable(@"Outgoing Audio is muted", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreOutgoingVideoMuted:
            return NSLocalizedStringFromTable(@"Outgoing Video is nuted", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        // IVR
        case ECoreIVRObjectNull:
            return NSLocalizedStringFromTable(@"IVR Object is Null", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreIVRIndexOutOfRange:
            return NSLocalizedStringFromTable(@"IVR Index is out of range", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreIVRReferFailure:
            return NSLocalizedStringFromTable(@"IVR Refer Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case ECoreIVRWaitingTimeOut:
            return NSLocalizedStringFromTable(@"IVR Waiting Timeout", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        // audio
        case EAudioFileNameEmpty:
            return NSLocalizedStringFromTable(@"Audio File Name is empty", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioChannelNotFound:
            return NSLocalizedStringFromTable(@"Audio Channel not found", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioStartRecordFailure:
            return NSLocalizedStringFromTable(@"Audio start recording failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioRegisterRecodingFailure:
            return NSLocalizedStringFromTable(@"Audio Register Recording Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioRegisterPlaybackFailure:
            return NSLocalizedStringFromTable(@"Audio Register Playback Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioGetStatisticsFailure:
            return NSLocalizedStringFromTable(@"Get Audio Statistics Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioPlayFileAlreadyEnable:
            return NSLocalizedStringFromTable(@"Audio Play File Already Enabled", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioPlayObjectNotExist:
            return NSLocalizedStringFromTable(@"Audio Play Object does not Exit", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioPlaySteamNotEnabled:
            return NSLocalizedStringFromTable(@"Audio Play stram not enabled", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioRegisterCallbackFailure:
            return NSLocalizedStringFromTable(@"Audio Register Callback Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioCreateAudioConferenceFailure:
            return NSLocalizedStringFromTable(@"Create Audio Conference Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioOpenPlayFileFailure:
            return NSLocalizedStringFromTable(@"Audio Open Play File Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioPlayFileModeNotSupport:
            return NSLocalizedStringFromTable(@"Audio Play File Mode not supported", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioPlayFileFormatNotSupport:
            return NSLocalizedStringFromTable(@"Audio Play File Format not supported", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioPlaySteamAlreadyEnabled:
            return NSLocalizedStringFromTable(@"Audio Play stream already enabled", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioCreateRecordFileFailure:
            return NSLocalizedStringFromTable(@"Create Audio Recording Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioCodecNotSupport:
            return NSLocalizedStringFromTable(@"Audio Codec not supported", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioPlayFileNotEnabled:
            return NSLocalizedStringFromTable(@"Audio Play File Not enabled", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioPlayFileGetPositionFailure:
            return NSLocalizedStringFromTable(@"Audio Play File Get Position Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioCantSetDeviceIdDuringCall:
            return NSLocalizedStringFromTable(@"Can't set Audio Device Id During Call", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EAudioVolumeOutOfRange:
            return NSLocalizedStringFromTable(@"Audio Volume out of range", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        // video
        case EVideoFileNameEmpty:
            return NSLocalizedStringFromTable(@"Video File Name Empty", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EVideoGetDeviceNameFailure:
            return NSLocalizedStringFromTable(@"Video Get Device Name Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EVideoGetDeviceIdFailure:
            return NSLocalizedStringFromTable(@"Video Get Device Id Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EVideoStartCaptureFailure:
            return NSLocalizedStringFromTable(@"Start Video Capture Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EVideoChannelNotFound:
            return NSLocalizedStringFromTable(@"Video Channel Not Found", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EVideoStartSendFailure:
            return NSLocalizedStringFromTable(@"Start Send Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EVideoGetStatisticsFailure:
            return NSLocalizedStringFromTable(@"Get Statistics Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EVideoStartPlayAviFailure:
            return NSLocalizedStringFromTable(@"Start Play AVI Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EVideoSendAviFileFailure:
            return NSLocalizedStringFromTable(@"Send Avi File Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EVideoRecordUnknowCodec:
            return NSLocalizedStringFromTable(@"Unknown Video Record Codec", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EVideoCantSetDeviceIdDuringCall:
            return NSLocalizedStringFromTable(@"Can't set device id durring call", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EVideoUnsupportCaptureRotate:
            return NSLocalizedStringFromTable(@"Unsupported Video Capture Rotation", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        case EVideoUnsupportCaptureResolution:
            return NSLocalizedStringFromTable(@"Unsupported Video Capture Resolution", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        // Device
        case EDeviceGetDeviceNameFailure:
            return NSLocalizedStringFromTable(@"Get Device Name Failure", PHONE_STRINGS_NAME, @"Port Sip Error");
            
        // Manager Errors
        case JC_SIP_ALREADY_REGISTERING:
            return NSLocalizedStringFromTable(@"Phone is already attempting to register", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_REGISTER_LINE_IS_EMPTY:
            return NSLocalizedStringFromTable(@"Line is empty", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_REGISTER_LINE_CONFIGURATION_IS_EMPTY:
            return NSLocalizedStringFromTable(@"Line Configuration is Empty", PHONE_STRINGS_NAME, @"Sip Manager Error");
         
        case JC_SIP_REGISTER_USER_IS_EMPTY:
            return NSLocalizedStringFromTable(@"User is Empty", PHONE_STRINGS_NAME, @"Sip Manager Error");
         
        case JC_SIP_REGISTER_SERVER_IS_EMPTY:
            return NSLocalizedStringFromTable(@"Server is empty", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_REGISTER_PASSWORD_IS_EMPTY:
            return NSLocalizedStringFromTable(@"Password is empty", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_REGISTRATION_TIMEOUT:
            return NSLocalizedStringFromTable(@"Phone is unable to register at this time. You may not be on an Approved network. If problem persists, contact your System Administrator to add your network.", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_REGISTRATION_FAILURE:
            return NSLocalizedStringFromTable(@"You may not be on an Approved network. If the problem persists, please contact your System Administrator to add your current network to the list of approved networks.", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_CALL_NO_IDLE_LINE:
            return NSLocalizedStringFromTable(@"No Idle Line", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_CALL_NO_ACTIVE_LINE:
            return NSLocalizedStringFromTable(@"No Active Line", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_LINE_SESSION_IS_EMPTY:
            return NSLocalizedStringFromTable(@"Line Session in empty", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_CALL_NO_REFERRAL_LINE:
            return NSLocalizedStringFromTable(@"No Referral line", PHONE_STRINGS_NAME, @"Sip Manager Error");
        
            
        case JC_SIP_MAKE_CALL_ERROR:
            return NSLocalizedStringFromTable(@"Unable to make a call", PHONE_STRINGS_NAME, @"Sip Manager Error");
    
        case JC_SIP_ANSWER_CALL_ERROR:
            return NSLocalizedStringFromTable(@"Unable to answer the call", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_REJECT_CALL_ERROR:
            return NSLocalizedStringFromTable(@"Error trying to manually reject incomming call", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_HANGUP_CALL_ERROR:
            return NSLocalizedStringFromTable(@"Error Trying to Hang up", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_HOLD_CALLS_ERROR:
            return NSLocalizedStringFromTable(@"Error holding the line sessions", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_HOLD_CALL_ERROR:
            return NSLocalizedStringFromTable(@"Error placing calls on hold", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_UNHOLD_CALLS_ERROR:
            return NSLocalizedStringFromTable(@"Error unholding the line session while after joing the conference", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_UNHOLD_CALL_ERROR:
            return NSLocalizedStringFromTable(@"Error placing calls on hold", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        // Conference calls
            
        case JC_SIP_CONFERENCE_CALL_ALREADY_STARTED:
            return NSLocalizedStringFromTable(@"Conference call already started", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_CONFERENCE_CALL_ALREADY_ENDED:
            return NSLocalizedStringFromTable(@"Conference call already ended", PHONE_STRINGS_NAME, @"Sip Manager Error");
         
        case JC_SIP_CONFERENCE_CALL_CREATION_ERROR:
            return NSLocalizedStringFromTable(@"Error Creating Conference", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_CONFERENCE_CALL_UNHOLD_CALL_START_ERROR:
            return NSLocalizedStringFromTable(@"Error unholding the line session while after joing the conference", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_CONFERENCE_CALL_ADD_CALL_ERROR:
            return NSLocalizedStringFromTable(@"Error Joining line session to conference", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        case JC_SIP_CONFERENCE_CALL_END_CALL_HOLD_ERROR:
            return NSLocalizedStringFromTable(@"Error placing calls on hold after ending a conference", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
        default:
            return NSLocalizedStringFromTable(@"Unknown Error Has Occured", PHONE_STRINGS_NAME, @"Sip Manager Error");
            
    }
    return nil;
}

+(NSString *)sipProtocolFailureReasonFromCode:(NSInteger)code {
    switch (code) {
        case 400:
            return NSLocalizedStringFromTable(@"Bad Request", PHONE_STRINGS_NAME, @"Sip Error");
        case 401:
            return NSLocalizedStringFromTable(@"Unauthorized", PHONE_STRINGS_NAME, @"Sip Error");
        case 402:
            return NSLocalizedStringFromTable(@"Payment Required", PHONE_STRINGS_NAME, @"Sip Error");
        case 403:
            return NSLocalizedStringFromTable(@"Forbidden", PHONE_STRINGS_NAME, @"Sip Error");
        case 404:
            return NSLocalizedStringFromTable(@"Not Found", PHONE_STRINGS_NAME, @"Sip Error");
        case 405:
            return NSLocalizedStringFromTable(@"Method Not Allowed", PHONE_STRINGS_NAME, @"Sip Error");
        case 406:
            return NSLocalizedStringFromTable(@"Not Acceptable", PHONE_STRINGS_NAME, @"Sip Error");
        case 407:
            return NSLocalizedStringFromTable(@"Proxy Authentication Required", PHONE_STRINGS_NAME, @"Sip Error");
        case 408:
            return NSLocalizedStringFromTable(@"Request Timeout", PHONE_STRINGS_NAME, @"Sip Error");
        case 409:
            return NSLocalizedStringFromTable(@"Conflict", PHONE_STRINGS_NAME, @"Sip Error");
        case 410:
            return NSLocalizedStringFromTable(@"Gone", PHONE_STRINGS_NAME, @"Sip Error");
        case 411:
            return NSLocalizedStringFromTable(@"Length Required", PHONE_STRINGS_NAME, @"Sip Error");
        case 412:
            return NSLocalizedStringFromTable(@"Conditional Request Failed", PHONE_STRINGS_NAME, @"Sip Error");
        case 413:
            return NSLocalizedStringFromTable(@"Request Entity Too Large", PHONE_STRINGS_NAME, @"Sip Error");
        case 414:
            return NSLocalizedStringFromTable(@"Request-URI Too Long", PHONE_STRINGS_NAME, @"Sip Error");
        case 415:
            return NSLocalizedStringFromTable(@"Unsupported Media Type", PHONE_STRINGS_NAME, @"Sip Error");
        case 416:
            return NSLocalizedStringFromTable(@"Unsupported URI Scheme", PHONE_STRINGS_NAME, @"Sip Error");
        case 417:
            return NSLocalizedStringFromTable(@"Unknown Resource-Priority", PHONE_STRINGS_NAME, @"Sip Error");
        case 420:
            return NSLocalizedStringFromTable(@"Bad Extension", PHONE_STRINGS_NAME, @"Sip Error");
        case 421:
            return NSLocalizedStringFromTable(@"Extension Required", PHONE_STRINGS_NAME, @"Sip Error");
        case 422:
            return NSLocalizedStringFromTable(@"Session Interval Too Small", PHONE_STRINGS_NAME, @"Sip Error");
        case 423:
            return NSLocalizedStringFromTable(@"Interval Too Brief", PHONE_STRINGS_NAME, @"Sip Error");
        case 424:
            return NSLocalizedStringFromTable(@"Bad Location Information", PHONE_STRINGS_NAME, @"Sip Error");
        case 428:
            return NSLocalizedStringFromTable(@"Use Identity Header", PHONE_STRINGS_NAME, @"Sip Error");
        case 429:
            return NSLocalizedStringFromTable(@"Provide Referrer Identity", PHONE_STRINGS_NAME, @"Sip Error");
        case 430:
            return NSLocalizedStringFromTable(@"Flow Failed", PHONE_STRINGS_NAME, @"Sip Error");
        case 433:
            return NSLocalizedStringFromTable(@"Anonymity Disallowed", PHONE_STRINGS_NAME, @"Sip Error");
        case 436:
            return NSLocalizedStringFromTable(@"Bad Identity-Info", PHONE_STRINGS_NAME, @"Sip Error");
        case 437:
            return NSLocalizedStringFromTable(@"Unsupported Certificate", PHONE_STRINGS_NAME, @"Sip Error");
        case 438:
            return NSLocalizedStringFromTable(@"Invalid Identity Header", PHONE_STRINGS_NAME, @"Sip Error");
        case 439:
            return NSLocalizedStringFromTable(@"First Hop Lacks Outbound Support", PHONE_STRINGS_NAME, @"Sip Error");
        case 470:
            return NSLocalizedStringFromTable(@"Consent Needed", PHONE_STRINGS_NAME, @"Sip Error");
        case 480:
            return NSLocalizedStringFromTable(@"Temporarily Unavailable", PHONE_STRINGS_NAME, @"Sip Error");
        case 481:
            return NSLocalizedStringFromTable(@"Call/Transaction Does Not Exist", PHONE_STRINGS_NAME, @"Sip Error");
        case 482:
            return NSLocalizedStringFromTable(@"Loop Detected", PHONE_STRINGS_NAME, @"Sip Error");
        case 483:
            return NSLocalizedStringFromTable(@"Too Many Hops", PHONE_STRINGS_NAME, @"Sip Error");
        case 484:
            return NSLocalizedStringFromTable(@"Address Incomplete", PHONE_STRINGS_NAME, @"Sip Error");
        case 485:
            return NSLocalizedStringFromTable(@"Ambiguous", PHONE_STRINGS_NAME, @"Sip Error");
        case 486:
            return NSLocalizedStringFromTable(@"Busy Here", PHONE_STRINGS_NAME, @"Sip Error");
        case 487:
            return NSLocalizedStringFromTable(@"Request Terminated", PHONE_STRINGS_NAME, @"Sip Error");
        case 488:
            return NSLocalizedStringFromTable(@"Not Acceptable Here", PHONE_STRINGS_NAME, @"Sip Error");
        case 489:
            return NSLocalizedStringFromTable(@"Bad Event", PHONE_STRINGS_NAME, @"Sip Error");
        case 491:
            return NSLocalizedStringFromTable(@"Request Pending", PHONE_STRINGS_NAME, @"Sip Error");
        case 493:
            return NSLocalizedStringFromTable(@"Undecipherable", PHONE_STRINGS_NAME, @"Sip Error");
        case 494:
            return NSLocalizedStringFromTable(@"Security Agreement Required", PHONE_STRINGS_NAME, @"Sip Error");
            
        // 5xx - Server Failure Responses */
        case 500:
            return NSLocalizedStringFromTable(@"Server Internal Error", PHONE_STRINGS_NAME, @"Sip Error");
        case 501:
            return NSLocalizedStringFromTable(@"Not Implemented", PHONE_STRINGS_NAME, @"Sip Error");
        case 502:
            return NSLocalizedStringFromTable(@"Bad Gateway", PHONE_STRINGS_NAME, @"Sip Error");
        case 503:
            return NSLocalizedStringFromTable(@"Service Unavailable", PHONE_STRINGS_NAME, @"Sip Error");
        case 504:
            return NSLocalizedStringFromTable(@"Server Time-out", PHONE_STRINGS_NAME, @"Sip Error");
        case 505:
            return NSLocalizedStringFromTable(@"Version Not Supported", PHONE_STRINGS_NAME, @"Sip Error");
        case 513:
            return NSLocalizedStringFromTable(@"Message Too Large", PHONE_STRINGS_NAME, @"Sip Error");
        case 580:
            return NSLocalizedStringFromTable(@"Precondition Failure", PHONE_STRINGS_NAME, @"Sip Error");
            
        // 6xx - Global Failure Responses
        case 600:
            return NSLocalizedStringFromTable(@"Busy Everywhere", PHONE_STRINGS_NAME, @"Sip Error");
        case 603:
            return NSLocalizedStringFromTable(@"Decline", PHONE_STRINGS_NAME, @"Sip Error");
        case 604:
            return NSLocalizedStringFromTable(@"Does Not Exist Anywhere", PHONE_STRINGS_NAME, @"Sip Error");
        case 606:
            return NSLocalizedStringFromTable(@"Not Acceptable", PHONE_STRINGS_NAME, @"Sip Error");
            
        default:
            return nil;
    }
}

+(NSString *)sipProtocolFailureDescriptionFromCode:(NSInteger)code {
    
    switch (code) {
            
        // 4xx - Client Failure Responses
        case 400:
            return NSLocalizedStringFromTable(@"Bad Request. The request could not be understood due to malformed syntax.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 401:
            return NSLocalizedStringFromTable(@"Unauthorized. The request requires user authentication.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 402:
            return NSLocalizedStringFromTable(@"Payment Required.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 403:
            return NSLocalizedStringFromTable(@"Forbidden. The server understood the request, but is refusing to fulfil it.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 404:
            return NSLocalizedStringFromTable(@"Not Found. The server has definitive information that the user does not exist at the domain specified in the Request-URI.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 405:
            return NSLocalizedStringFromTable(@"Method Not Allowed. The method specified in the Request -Line is understood, but not allowed for the address identified by the Request-URI.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 406:
            return NSLocalizedStringFromTable(@"Not Acceptable. The resource identified by the request is only capable of generating response entities that have content characteristics but not acceptable according to the Accept header field sent in the request.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 407:
            return NSLocalizedStringFromTable(@"Proxy Authentication Required. The request requires user authentication.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 408:
            return NSLocalizedStringFromTable(@"Request Timeout. Couldn't find the user in time. The server could not produce a response within a suitable amount of time, for example, if it could not determine the location of the user in time.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 409:
            return NSLocalizedStringFromTable(@"Conflict. User already registered.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 410:
            return NSLocalizedStringFromTable(@"Gone. The user existed once, but is not available here any more.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 411:
            return NSLocalizedStringFromTable(@"Length Required. The server will not accept the request without a valid Content - Length.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 412:
            return NSLocalizedStringFromTable(@"Conditional Request Failed. The given precondition has not been met.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 413:
            return NSLocalizedStringFromTable(@"Request Entity Too Large. Request body too large.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 414:
            return NSLocalizedStringFromTable(@"Request - URI Too Long. The server is refusing to service the request because the Request - URI is longer than the server is willing to interpret.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 415:
            return NSLocalizedStringFromTable(@"Unsupported Media Type. Request body in a format not supported.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 416:
            return NSLocalizedStringFromTable(@"Unsupported URI Scheme. Request - URI is unknown to the server.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 417:
            return NSLocalizedStringFromTable(@"Unknown Resource -Priority. There was a resource - priority option tag, but no Resource-Priority header.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 420:
            return NSLocalizedStringFromTable(@"Bad Extension. Bad SIP Protocol Extension used, not understood by the server.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 421:
            return NSLocalizedStringFromTable(@"Extension Required. The server needs a specific extension not listed in the Supported header.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 422:
            return NSLocalizedStringFromTable(@"Session Interval Too Small. The received request contains a Session-Expires header field with a duration below the minimum timer.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 423:
            return NSLocalizedStringFromTable(@"Interval Too Brief. Expiration time of the resource is too short.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 424:
            return NSLocalizedStringFromTable(@"Bad Location Information. The request's location content was malformed or otherwise unsatisfactory.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 428:
            return NSLocalizedStringFromTable(@"Use Identity Header. The server policy requires an Identity header, and one has not been provided.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 429:
            return NSLocalizedStringFromTable(@"Provide Referrer Identity. The server did not receive a valid Referred-By token on the request.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 430:
            return NSLocalizedStringFromTable(@"Flow Failed. A specific flow to a user agent has failed, although other flows may succeed.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 433:
            return NSLocalizedStringFromTable(@"Anonymity Disallowed. The request has been rejected because it was anonymous.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 436:
            return NSLocalizedStringFromTable(@"Bad Identity -Info. The request has an Identity -Info header, and the URI scheme in that header cannot be dereferenced.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 437:
            return NSLocalizedStringFromTable(@"Unsupported Certificate. The server was unable to validate a certificate for the domain that signed the request.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 438:
            return NSLocalizedStringFromTable(@"Invalid Identity Header. The server obtained a valid certificate that the request claimed was used to sign the request, but was unable to verify that signature.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 439:
            return NSLocalizedStringFromTable(@"First Hop Lacks Outbound Support. The first outbound proxy the user is attempting to register through does not support the 'outbound' feature of RFC 5626, although the registrar does.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 470:
            return NSLocalizedStringFromTable(@"Consent Needed. The source of the request did not have the permission of the recipient to make such a request.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 480:
            return NSLocalizedStringFromTable(@"Temporarily Unavailable. Callee currently unavailable.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 481:
            return NSLocalizedStringFromTable(@"Call/Transaction Does Not Exist. Server received a request that does not match any dialog or transaction.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 482:
            return NSLocalizedStringFromTable(@"Loop Detected. Server has detected a loop.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 483:
            return NSLocalizedStringFromTable(@"Too Many Hops. Max - Forwards header has reached the value '0'.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 484:
            return NSLocalizedStringFromTable(@"Address Incomplete. Request - URI incomplete.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 485:
            return NSLocalizedStringFromTable(@"Ambiguous. Request - URI is ambiguous.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 486:
            return NSLocalizedStringFromTable(@"Busy Here. Callee is busy.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 487:
            return NSLocalizedStringFromTable(@"Request Terminated. Request has terminated by bye or cancel.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 488:
            return NSLocalizedStringFromTable(@"Not Acceptable Here. Some aspect of the session description or the Request - URI is not acceptable.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 489:
            return NSLocalizedStringFromTable(@"Bad Event. The server did not understand an event package specified in an Event header field.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 491:
            return NSLocalizedStringFromTable(@"Request Pending. Server has some pending request from the same dialog.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 493:
            return NSLocalizedStringFromTable(@"Undecipherable. Request contains an encrypted MIME body, which recipient can not decrypt.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 494:
            return NSLocalizedStringFromTable(@"Security Agreement Required.", PHONE_STRINGS_NAME, @"Sip Error Description");
            
        // 5xx - Server Failure Responses
        case 500:
            return NSLocalizedStringFromTable(@"Server Internal Error. The server could not fulfill the request due to some unexpected condition.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 501:
            return NSLocalizedStringFromTable(@"Not Implemented. The server does not have the ability to fulfill the request, such as because it does not recognize the request method.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 502:
            return NSLocalizedStringFromTable(@"Bad Gateway. The server is acting as a gateway or proxy, and received an invalid response from a downstream server while attempting to fulfill the request.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 503:
            return NSLocalizedStringFromTable(@"Service Unavailable. The server is undergoing maintenance or is temporarily overloaded and so cannot process the request.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 504:
            return NSLocalizedStringFromTable(@"Server Time-out. The server attempted to access another server in attempting to process the request, and did not receive a prompt response.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 505:
            return NSLocalizedStringFromTable(@"Version Not Supported. The SIP protocol version in the request is not supported by the server.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 513:
            return NSLocalizedStringFromTable(@"Message Too Large. The request message length is longer than the server can process.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 580:
            return NSLocalizedStringFromTable(@"Precondition Failure. The server is unable or unwilling to meet some constraints specified in the offer.", PHONE_STRINGS_NAME, @"Sip Error Description");
            
        // 6xx - Global Failure Responses
        case 600:
            return NSLocalizedStringFromTable(@"Busy Everywhere. All possible destinations are busy. Destination knows there are no alternative destinations (such as a voicemail server) able to accept the call.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 603:
            return NSLocalizedStringFromTable(@"Decline. The destination does not wish to participate in the call", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 604:
            return NSLocalizedStringFromTable(@"Does Not Exist Anywhere. The server has authoritative information that the requested user does not exist anywhere.", PHONE_STRINGS_NAME, @"Sip Error Description");
        case 606:
            return NSLocalizedStringFromTable(@"Not Acceptable. The user's agent was contacted successfully but some aspects of the session description such as the requested media, bandwidth, or addressing style were not acceptable.", PHONE_STRINGS_NAME, @"Sip Error Description");
        default:
            return NSLocalizedStringFromTable(@"An Error has occurred. An unknown error has occured.", PHONE_STRINGS_NAME, @"Sip Error Description");
    }
    
}

@end
