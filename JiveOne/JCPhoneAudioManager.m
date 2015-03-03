//
//  JCBluetoothManager.m
//  JiveOne
//
//  Created by Robert Barclay on 11/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import AVFoundation;

#import "JCPhoneAudioManager.h"

@interface JCPhoneAudioManager ()
{
    JCPhoneAudioManagerOutputType _outputType;
    JCPhoneAudioManagerInputType _inputType;
}

@end

@implementation JCPhoneAudioManager

-(instancetype)init
{
    self = [super init];
    if (self) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(audioSessionInterruptionSelector:) name:AVAudioSessionInterruptionNotification object:nil];
        [center addObserver:self selector:@selector(audioSessionRouteChangeSelector:) name:AVAudioSessionRouteChangeNotification object:nil];
        [center addObserver:self selector:@selector(audioSessionMediaServicesWereLostSelector:) name:AVAudioSessionMediaServicesWereLostNotification object:nil];
        [center addObserver:self selector:@selector(audioSessionMediaServicesWereResetSelector:) name:AVAudioSessionMediaServicesWereResetNotification object:nil];
        
        
//        [center addObserver:self selector:@selector(audioSessionSilenceSecondaryAudioHintSelector:) name:AVAudioSessionSilenceSecondaryAudioHintNotification object:nil];
    }
    return self;
}

#pragma mark - Public Methods

/* Access the Audio Session singlton and modify the AVAudioSessionPlayAndRecord property to allow Bluetooth.
 */
-(BOOL)enableBluetoothAudio:(NSError *__autoreleasing *)error
{
    // deactivate session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (![session setActive:NO error:error]) {
        return FALSE;
    }
    
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:error]) {
        return FALSE;
    }
    
    if (![session setMode:AVAudioSessionModeVoiceChat error:error]) {
        return FALSE;
    }
    
    if (![session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:error]) {
        return FALSE;
    }
    
    // activate audio session
    if (![session setActive:YES error:nil]) {
        return FALSE;
    }
    
    return TRUE;
}

-(BOOL)disableBluetoothAudio:(NSError *__autoreleasing *)error
{
    // deactivate session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (![session setActive:NO error: nil]) {
        return FALSE;
    }
    
    if (![session setCategory:AVAudioSessionCategoryAmbient error:error]) {
        return FALSE;
    }
    
    if (![session setMode:AVAudioSessionModeVoiceChat error:error]) {
        return FALSE;
    }
    
    if (![session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:error]) {
        return FALSE;
    }
    
    // activate audio session
    if (![session setActive:YES error:nil]) {
        return FALSE;
    }
    
    return TRUE;
}

-(JCPhoneAudioManagerInputType)inputType
{
    if (_inputType == JCPhoneAudioManagerInputUnknown) {
        AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
        NSArray *inputs = currentRoute.inputs;
        AVAudioSessionPortDescription *port = [inputs lastObject];
        _inputType = [self inputTypeFromString:port.portType];
    }
    return _inputType;
}

-(JCPhoneAudioManagerOutputType)outputType
{
    if (_outputType == JCPhoneAudioManagerOutputUnknown) {
        AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
        NSArray *outputs = currentRoute.outputs;
        AVAudioSessionPortDescription *port = [outputs lastObject];
        _outputType = [self outputTypeFromString:port.portType];
    }
    return _outputType;
}


#pragma mark - Notification Handlers -

#pragma mark AVAudioSession

/* Registered listeners will be notified when the system has interrupted the audio session and when
 the interruption has ended.  Check the notification's userInfo dictionary for the interruption type -- either begin or end.
 In the case of an end interruption notification, check the userInfo dictionary for AVAudioSessionInterruptionOptions that
 indicate whether audio playback should resume.
 */
- (void)audioSessionInterruptionSelector:(NSNotification *)notification {
    
//    NSLog(@"Audio Session Interuption %@", [notification.userInfo description]);
    
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    NSArray *inputsForRoute = currentRoute.inputs;
    NSArray *outputsForRoute = currentRoute.outputs;
    AVAudioSessionPortDescription *outPortDesc = [outputsForRoute objectAtIndex:0];
    NSLog(@"current outport type %@", outPortDesc.portType);
    AVAudioSessionPortDescription *inPortDesc = [inputsForRoute objectAtIndex:0];
    NSLog(@"current inPort type %@", inPortDesc.portType);
}

/* Registered listeners will be notified when a route change has occurred.  Check the notification's userInfo dictionary for the
 route change reason and for a description of the previous audio route.
 */
- (void)audioSessionRouteChangeSelector:(NSNotification *)notification {
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(audioSessionRouteChangeSelector:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    AVAudioSession *audioSession = notification.object;
    NSArray *outputs = audioSession.currentRoute.outputs;
    AVAudioSessionPortDescription *port = [outputs lastObject];
    _outputType = [self outputTypeFromString:port.portType];
    [_delegate phoneAudioManager:self didChangeAudioRouteOutputType:_outputType];
    
    NSArray *inputs = audioSession.currentRoute.inputs;
    port = [inputs lastObject];
    _inputType = [self inputTypeFromString:port.portType];
    [_delegate phoneAudioManager:self didChangeAudioRouteInputType:_inputType];
    
}

/* Registered listeners will be notified if the media server is killed.  In the event that the server is killed,
 take appropriate steps to handle requests that come in before the server resets.  See Technical Q&A QA1749.
 */
-(void)audioSessionMediaServicesWereLostSelector:(NSNotification *)notification
{
    NSLog(@"Audio Session Media Services Were Lost %@", [notification.userInfo description]);
}

/* Registered listeners will be notified when the media server restarts.  In the event that the server restarts,
 take appropriate steps to re-initialize any audio objects used by your application.  See Technical Q&A QA1749.
 */
-(void)audioSessionMediaServicesWereResetSelector:(NSNotification *)notification
{
    NSLog(@"Audio Session Media Services Were Reset %@", [notification.userInfo description]);
}

/* Registered listeners that are currently in the foreground and have active audio sessions will be notified
 when primary audio from other applications starts and stops.  Check the notification's userInfo dictionary
 for the notification type -- either begin or end.
 Foreground applications may use this notification as a hint to enable or disable audio that is secondary
 to the functionality of the application. For more information, see the related property secondaryAudioShouldBeSilencedHint.
 */
-(void)audioSessionSilenceSecondaryAudioHintSelector:(NSNotification *)notification
{
    NSLog(@"Audio Session Silence Secondary Audio %@", [notification.userInfo description]);
}

#pragma mark - Private -

#pragma mark Inputs

-(JCPhoneAudioManagerInputType)inputTypeFromString:(NSString *)type
{
    if ([type isEqualToString:AVAudioSessionPortLineIn])
        return JCPhoneAudioManagerInputLineIn;
    
    else if ([type isEqualToString:AVAudioSessionPortBuiltInMic])
        return JCPhoneAudioManagerInputMicrophone;
    
    else if ([type isEqualToString:AVAudioSessionPortHeadsetMic])
        return JCPhoneAudioManagerInputHeadphonesMic;
    
    else if ([type isEqualToString:AVAudioSessionPortBluetoothHFP])
        return JCPhoneAudioManagerInputBluetoothHFP;
    
    else if ([type isEqualToString:AVAudioSessionPortUSBAudio])
        return JCPhoneAudioManagerInputUSB;
    
    else if ([type isEqualToString:AVAudioSessionPortCarAudio])
        return JCPhoneAudioManagerInputCarAudio;
    
    return JCPhoneAudioManagerInputUnknown;
}

-(NSString *)stringFromInputType:(JCPhoneAudioManagerInputType)inputType
{
    switch (inputType) {
        case JCPhoneAudioManagerInputLineIn:
            return AVAudioSessionPortLineIn;
            
        case JCPhoneAudioManagerInputMicrophone:
            return AVAudioSessionPortBuiltInMic;
            
        case JCPhoneAudioManagerInputHeadphonesMic:
            return AVAudioSessionPortHeadsetMic;
            
        case JCPhoneAudioManagerInputBluetoothHFP:
            return AVAudioSessionPortBluetoothHFP;
            
        case JCPhoneAudioManagerInputUSB:
            return AVAudioSessionPortUSBAudio;
            
        case JCPhoneAudioManagerInputCarAudio:
            return AVAudioSessionPortCarAudio;
            
        default:
            return @"Unknown Input Type";
    }
}

#pragma mark Outputs

-(JCPhoneAudioManagerOutputType)outputTypeFromString:(NSString *)type
{
    if ([type isEqualToString:AVAudioSessionPortLineOut])
        return JCPhoneAudioManagerOutputLineOut;
    
    else if ([type isEqualToString:AVAudioSessionPortHeadphones])
        return JCPhoneAudioManagerOutputHeadphones;
    
    else if ([type isEqualToString:AVAudioSessionPortBluetoothA2DP])
        return JCPhoneAudioManagerOutputBluetooth;
    
    else if ([type isEqualToString:AVAudioSessionPortBluetoothLE])
        return JCPhoneAudioManagerOutputBluetoothLE;
    
    else if ([type isEqualToString:AVAudioSessionPortBuiltInReceiver])
        return JCPhoneAudioManagerOutputReceiver;
    
    else if ([type isEqualToString:AVAudioSessionPortBuiltInSpeaker])
        return JCPhoneAudioManagerOutputSpeaker;
    
    else if ([type isEqualToString:AVAudioSessionPortHDMI])
        return JCPhoneAudioManagerOutputHDMI;
    
    else if ([type isEqualToString:AVAudioSessionPortAirPlay])
        return JCPhoneAudioManagerOutputAirPlay;
    
    else if ([type isEqualToString:AVAudioSessionPortBluetoothHFP])
        return JCPhoneAudioManagerOutputBluetoothHFP;
    
    else if ([type isEqualToString:AVAudioSessionPortUSBAudio])
        return JCPhoneAudioManagerOutputUSB;
    
    else if ([type isEqualToString:AVAudioSessionPortCarAudio])
        return JCPhoneAudioManagerOutputCarAudio;
    
    return JCPhoneAudioManagerOutputUnknown;
}

-(NSString *)stringfromOutputType:(JCPhoneAudioManagerOutputType)outputType
{
    switch (outputType) {
        case JCPhoneAudioManagerOutputLineOut:
            return AVAudioSessionPortLineOut;
            
        case JCPhoneAudioManagerOutputHeadphones:
            return AVAudioSessionPortHeadphones;
            
        case JCPhoneAudioManagerOutputBluetooth:
            return AVAudioSessionPortBluetoothA2DP;
            
        case JCPhoneAudioManagerOutputBluetoothLE:
            return AVAudioSessionPortBluetoothLE;
            
        case JCPhoneAudioManagerOutputReceiver:
            return AVAudioSessionPortBuiltInReceiver;
            
        case JCPhoneAudioManagerOutputSpeaker:
            return AVAudioSessionPortBuiltInSpeaker;
            
        case JCPhoneAudioManagerOutputHDMI:
            return AVAudioSessionPortHDMI;
            
        case JCPhoneAudioManagerOutputAirPlay:
            return AVAudioSessionPortAirPlay;
            
            //        case JCPhoneAudioManagerOutputLineOut:
            //            return AVAudioSessionPortLineOut;
            //
            //        case JCPhoneAudioManagerOutputLineOut:
            //            return AVAudioSessionPortLineOut;
            
        default:
            return @"Unknown Ouput Type";
    }
}



@end
