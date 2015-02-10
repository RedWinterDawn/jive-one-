//
//  JCSipHandlerError.m
//  JiveOne
//
//  Created by Robert Barclay on 1/14/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSipHandlerError.h"

NSString *const kJCSipHandlerErrorDomain = @"SipErrorDomain";

@implementation JCSipHandlerError

+(instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    return [self errorWithDomain:kJCSipHandlerErrorDomain code:code userInfo:userInfo];
}

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error
{
    return [self errorWithDomain:kJCSipHandlerErrorDomain code:code reason:reason underlyingError:error];
}

+(NSString *)failureReasonFromCode:(NSInteger)code
{
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
            return @"Audio Handle is NULL"
            ;
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
            
        default:
            return @"Unknown Error Has Occured";
            
    }
    return nil;
}

@end
