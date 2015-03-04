//
//  JCBluetoothManager.m
//  JiveOne
//
//  Created by Robert Barclay on 11/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import AVFoundation;

#import "JCPhoneAudioManager.h"
#import "JCAppSettings.h"

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
    if (self)
    {
        // Register for Audio Session Notifications
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(audioSessionInterruptionSelector:) name:AVAudioSessionInterruptionNotification object:nil];
        [center addObserver:self selector:@selector(audioSessionRouteChangeSelector:) name:AVAudioSessionRouteChangeNotification object:nil];
        [center addObserver:self selector:@selector(audioSessionMediaServicesWereResetSelector:) name:AVAudioSessionMediaServicesWereResetNotification object:nil];
        if (&AVAudioSessionSilenceSecondaryAudioHintNotification) {  // iOS 8 only
            [center addObserver:self selector:@selector(audioSessionSilenceSecondaryAudioHintSelector:) name:AVAudioSessionSilenceSecondaryAudioHintNotification object:nil];
        }
    }
    return self;
}

#pragma mark - Public Methods

/* Access the Audio Session singlton and modify the AVAudioSessionPlayAndRecord property to allow Bluetooth.
 */
-(void)engageAudioSession
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (![session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil]) {
        
    }
    
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:nil]) {
        
    }
    
    if (![session setMode:AVAudioSessionModeVoiceChat error:nil]) {
        
    }
    
    // activate audio session
    if (![session setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil]) {
        
    }
    
    _engaged = true;
}

-(void)disengageAudioSession
{
    // deactivate session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (![session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error: nil]) {
        NSLog(@"Error Disabling Audio Session");
    }
    
    _engaged = false;
}

#pragma mark - Getters -

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
- (void)audioSessionInterruptionSelector:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    AVAudioSessionInterruptionType type = ((NSNumber *)[userInfo valueForKey:AVAudioSessionInterruptionTypeKey]).unsignedIntegerValue;
    if (type == AVAudioSessionInterruptionTypeBegan) {
        _interupted = true;
        [_delegate audioSessionInteruptionDidBegin:self];
        NSLog(@"Audio Session Interuption begin");
    } else {
        _interupted = false;
        [_delegate audioSessionInteruptionDidEnd:self];
        NSLog(@"Audio Session Interuption end");
    }
    
    AVAudioSessionInterruptionOptions options = ((NSNumber *)[userInfo valueForKey:AVAudioSessionInterruptionOptionKey]).unsignedIntegerValue;
    if (options == AVAudioSessionInterruptionOptionShouldResume) {
        NSLog(@"Audio Session Should Resume");
    }
}

/* Registered listeners will be notified when a route change has occurred.  Check the notification's userInfo dictionary for the
 route change reason and for a description of the previous audio route.
 */
- (void)audioSessionRouteChangeSelector:(NSNotification *)notification
{
    AVAudioSession *audioSession = notification.object;
    NSArray *inputs = audioSession.currentRoute.inputs;
    AVAudioSessionPortDescription *port = [inputs lastObject];
    JCPhoneAudioManagerInputType inputType = [self inputTypeFromString:port.portType];
    if (_inputType != inputType) {
        _inputType = inputType;
        [_delegate phoneAudioManager:self didChangeAudioRouteInputType:_inputType];
    }
    
    NSArray *outputs = audioSession.currentRoute.outputs;
    port = [outputs lastObject];
    JCPhoneAudioManagerOutputType outputType = [self outputTypeFromString:port.portType];
    if (_outputType != outputType) {
        _outputType = outputType;
        [_delegate phoneAudioManager:self didChangeAudioRouteOutputType:_outputType];
    }
    
    NSLog(@"Audio Session Route Changed: Input = %@, Output = %@", [self stringFromInputType:_inputType], [self stringfromOutputType:_outputType]);
}

/* Registered listeners will be notified when the media server restarts.  In the event that the server restarts,
 take appropriate steps to re-initialize any audio objects used by your application.  See Technical Q&A QA1749.
 */
-(void)audioSessionMediaServicesWereResetSelector:(NSNotification *)notification
{
    if (_engaged) {
        [self engageAudioSession];
    }
    else {
        [self disengageAudioSession];
    }
    
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
    NSDictionary *userInfo = notification.userInfo;
    AVAudioSessionSilenceSecondaryAudioHintType type = (AVAudioSessionSilenceSecondaryAudioHintType)[userInfo valueForKey:AVAudioSessionSilenceSecondaryAudioHintTypeKey];
    if (type == AVAudioSessionSilenceSecondaryAudioHintTypeBegin) {
        NSLog(@"Audio Session Silence Secondary Audio will begin");
    } else if(type == AVAudioSessionSilenceSecondaryAudioHintTypeEnd) {
        NSLog(@"Audio Session Silence Secondary Audio did end.");
    }
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
            
        case JCPhoneAudioManagerOutputBluetoothHFP:
            return AVAudioSessionPortBluetoothHFP;
            
        case JCPhoneAudioManagerOutputUSB:
            return AVAudioSessionPortUSBAudio;
            
        case JCPhoneAudioManagerOutputCarAudio:
            return AVAudioSessionPortCarAudio;
            
        default:
            return @"Unknown Ouput Type";
    }
}



@end

#pragma mark - Alerts -

#define DEFAULT_TIME_INTERVAL 1

static AVAudioPlayer *ringbackAudioPlayer;
static SystemSoundID ringtoneID;
static BOOL active;

@implementation JCPhoneAudioManager (Alerts)

- (void)vibrate
{
    [self startRepeatingVibration:NO];
}

- (void)startRepeatingVibration:(BOOL)repeating
{
    active = repeating;
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, vibration, NULL);
}

- (void)stop
{
    active = false;
    
    if (ringtoneID) {
        AudioServicesRemoveSystemSoundCompletion (ringtoneID);
        AudioServicesDisposeSystemSoundID(ringtoneID);
        ringtoneID = false;
    }
    
    __autoreleasing NSError *error;
    if (![[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error]) {
        NSLog(@"%@", error);
    }
    
    if (ringbackAudioPlayer) {
        [ringbackAudioPlayer stop];
        ringbackAudioPlayer = nil;
    }
}

- (void)ring
{
    [self startRepeatingRingtone:NO];
}

- (void)startRepeatingRingtone:(BOOL)repeating
{
    active = repeating;
    @try {
        NSURL *url = [NSURL fileURLWithPath:@"/System/Library/Audio/UISounds/vc~ringing.caf"];
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if (self.outputType == JCPhoneAudioManagerOutputReceiver) {
            __autoreleasing NSError *error;
            if (![audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error]) {
                NSLog(@"%@", error);
            }
        }
        
        AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)url, &ringtoneID);
        AudioServicesPlaySystemSound(ringtoneID);
        CFBridgingRelease((__bridge CFURLRef)url);
        AudioServicesAddSystemSoundCompletion(ringtoneID, NULL, NULL, ringtone, NULL);
        
        if ([JCAppSettings sharedSettings].isVibrateOnRing)
            [self startRepeatingVibration:repeating];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.description);
    }
}

- (void)startRingback
{
    if (!ringbackAudioPlayer) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"calling" ofType:@"mp3"];
        NSURL *url = [NSURL fileURLWithPath:path];
        __autoreleasing NSError *error;
        ringbackAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        [ringbackAudioPlayer prepareToPlay];
    }
    
    if (!ringbackAudioPlayer.isPlaying) {
        [ringbackAudioPlayer play];
    }
}

#pragma mark - Private -

void vibration (SystemSoundID ssID, void *clientData)
{
    if (!active)
        return;
    
    double delayInSeconds = DEFAULT_TIME_INTERVAL;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!active)
            return;
        AudioServicesPlaySystemSound(ssID);
    });
}

void ringtone (SystemSoundID ssID, void *clientData)
{
    if (!active)
        return;
    
    double delayInSeconds = DEFAULT_TIME_INTERVAL;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!active)
            return;
        AudioServicesPlaySystemSound(ssID);
    });
}

@end
