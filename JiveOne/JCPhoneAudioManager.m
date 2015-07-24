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
    JCAppSettings *_appSettings;
}

@property (strong, nonatomic) AVAudioPlayer *incomingCallAudioPlayer;
@property (strong, nonatomic) AVAudioPlayer *earlyMediaRingBackPlayer;

@property (assign) SystemSoundID incomingRingerSound;
@property int ringbackVolume;
@property int ringerVolume;

@end

@implementation JCPhoneAudioManager

- (instancetype)init {
    return [self initWithAppSettings:[JCAppSettings sharedSettings]];
}

- (instancetype)initWithAppSettings:(JCAppSettings *)settings
{
    self = [super init];
    if (self)
    {
        _appSettings = settings;
        
        _ringbackVolume = 1;  // Defined here in case we and to calibrate the ringback audio not to be as loud as ringer.
        _ringerVolume = 1;
        [self configureAudioSession];
        
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

-(void)dealloc {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}


#pragma mark - Incoming Call Ringer Methods

- (void) configureAudioSession {
    __autoreleasing NSError *error;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions: AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionDuckOthers error:&error];
    if (error){
        NSLog(@"Error setting Category! %@", [error description]);
    }
}

#pragma mark - Public Methods

-(void)playRingback{
    __autoreleasing NSError *error;
    if ([[AVAudioSession sharedInstance].currentRoute.description isEqualToString:AVAudioSessionPortBuiltInSpeaker.description]){
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error: &error];
        if (error){
            NSLog(@"Error doing a overide of not overriding stuffs %@", error.description);
        }
        
    }
    AVAudioPlayer *player = self.earlyMediaRingBackPlayer;
    player.volume = _ringerVolume;
    
    [player prepareToPlay];
    [player play];
}

- (void)playIncomingCallTone
{
    __autoreleasing NSError *error;
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    if (error){
        NSLog(@"Error doing a overide of not overriding stuffs %@", error.description);
    }
    AVAudioPlayer *player = self.incomingCallAudioPlayer;
    player.volume = _ringerVolume;
    
    [player prepareToPlay];
    [player play];
}

- (void) playIncomingCallToneDemo
{
    if (_incomingCallAudioPlayer.isPlaying) {
        [_incomingCallAudioPlayer stop];
        _incomingCallAudioPlayer = nil;
    }
   
    AVAudioPlayer *player = self.incomingCallAudioPlayer;
    player.numberOfLoops = 0;
    player.volume = _ringerVolume;
    
    if (_outputType != JCPhoneAudioManagerOutputSpeaker) {
         [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    }

    [player prepareToPlay];
    [player play];
}

-(void)stop {
    
    AVAudioPlayer *player = _incomingCallAudioPlayer;
    if (player && player.isPlaying) {
        [player stop];
        _incomingCallAudioPlayer = nil;
    }
    
    player = _earlyMediaRingBackPlayer;
    if (player && player.isPlaying) {
        [player stop];
        _earlyMediaRingBackPlayer = nil;
    }
}

-(void)checkState {
    if (_incomingCallAudioPlayer.isPlaying && _outputType == JCPhoneAudioManagerOutputReceiver) {
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    }
}

-(void)setSessionActive
{
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

#pragma mark - Getters -

-(AVAudioPlayer *)incomingCallAudioPlayer
{
    if (_incomingCallAudioPlayer) {
        return _incomingCallAudioPlayer;
    }
    
    NSString* ringTone = _appSettings.ringtone;
    NSString *path = [[NSBundle mainBundle] pathForResource:ringTone ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:path];
    
    _incomingCallAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    _incomingCallAudioPlayer.numberOfLoops = -1;
    _incomingCallAudioPlayer.volume = _ringerVolume;
    return _incomingCallAudioPlayer;
}

-(AVAudioPlayer *)earlyMediaRingBackPlayer
{
    if (_earlyMediaRingBackPlayer) {
        return _earlyMediaRingBackPlayer;
    }
    
    NSString* ringTone = @"calling";
    NSString *path = [[NSBundle mainBundle] pathForResource:ringTone ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:path];
    
    _earlyMediaRingBackPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];    // Setup audio players for Incoming call ringer
    _earlyMediaRingBackPlayer.numberOfLoops = -1;                                                                   // Loop till answerd
    _earlyMediaRingBackPlayer.volume = _ringbackVolume;
    return _earlyMediaRingBackPlayer;
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
- (void)audioSessionInterruptionSelector:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    AVAudioSessionInterruptionType type = ((NSNumber *)[userInfo valueForKey:AVAudioSessionInterruptionTypeKey]).unsignedIntegerValue;
    if (type == AVAudioSessionInterruptionTypeBegan) {
        _interupted = true;
        [_delegate audioSessionInteruptionDidBegin:self];
    } else {
        _interupted = false;
        [_delegate audioSessionInteruptionDidEnd:self];
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

#pragma mark - Private -
#define DEFAULT_TIME_INTERVAL 1

void vibration (SystemSoundID ssID, void *clientData)
{
    
    double delayInSeconds = DEFAULT_TIME_INTERVAL;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        AudioServicesPlaySystemSound(ssID);
    });
}

- (void)startVibrate
{
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, vibration, NULL);
}

-(void)stopVibrate{
    AudioServicesRemoveSystemSoundCompletion (kSystemSoundID_Vibrate);
    AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate);
}

@end
