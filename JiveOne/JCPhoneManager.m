//
//  JCPhoneManager.m
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import AVFoundation;
@import CoreTelephony;

#define MAX_LINES 2

#import "JCPhoneManager.h"
#import "JCPhoneManagerError.h"

// Managers
#import "JCBluetoothManager.h"
#import "SipHandler.h"
#import "LineConfiguration+V4Client.h"
#import "JCAppSettings.h"

// Objects
#import "JCLineSession.h"
#import "JCConferenceCallCard.h"
#import "Contact.h"

// View Controllers
#import "JCCallerViewController.h"
#import "UIViewController+HUD.h"

NSString *const kJCPhoneManager911String = @"911";
NSString *const kJCPhoneManager611String = @"611";

@interface JCPhoneManager ()<SipHandlerDelegate, JCCallCardDelegate>
{
    JCBluetoothManager *_bluetoothManager;
    SipHandler *_sipHandler;
    JCCallerViewController *_callViewController;
    BOOL _reconnectWhenCallFinishes;
	NSString *_warmTransferNumber;
    CTCallCenter *_externalCallCenter;
}

@property (copy)void (^externalCallCompletionHandler)(BOOL connected);
@property (nonatomic) BOOL externalCallConnected;
@property (nonatomic) BOOL externalCallDisconnected;

@property (nonatomic, readwrite, getter=isConnected) BOOL connected;
@property (nonatomic, readwrite, getter=isConnecting) BOOL connecting;
@property (nonatomic, readwrite) JCPhoneManagerOutputType outputType;

@end

@implementation JCPhoneManager

-(id)init
{
    self = [super init];
    if (self)
    {
        // Open bluetooth manager to turn on audio support for bluetooth before we get started.
        _bluetoothManager = [[JCBluetoothManager alloc] init];
        
        // Register for Audio Route Changes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionRouteChangeSelector:) name:AVAudioSessionRouteChangeNotification object:nil];
        
        // Initialize the Sip Handler.
        __autoreleasing NSError *error;
        _sipHandler = [[SipHandler alloc] initWithNumberOfLines:MAX_LINES delegate:self error:&error];
        if (!error) {
            _initialized = TRUE;
        } else {
            [UIApplication showSimpleAlert:@"Warning" message:@"There was an error loading the phone" code:error.code];
        }
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Connection -

/**
 *  Registers the phone manager to a particualar line.
 *
 *  If we are already connecting, we limit them so that they can not make multiple concurrent
 *  reconnect events at the same time.
 */
-(void)connectToLine:(Line *)line completion:(CompletionHandler)completion
{
    self.completion = completion;
    
    // Check if we are initialized.
    if(!_initialized) {
        [self reportError:[JCPhoneManagerError errorWithCode:JS_PHONE_SIP_NOT_INITIALIZED]];
        return;
    }
    
    // If we are already connecting, exit out. We only allow one connection attempt at a time.
    if (_connecting) {
        [self notifyCompletionBlock:false error:[JCPhoneManagerError errorWithCode:JS_PHONE_ALREADY_CONNECTING]];
        return;
    }
    
    // Check if we have a line. If not, we fail. We cannot register if we did not receive a line.
    if (!line) {
        [self notifyCompletionBlock:false error:[JCPhoneManagerError errorWithCode:JS_PHONE_LINE_IS_NULL]];
        return;
    }
    
    // Check to see if we are on a current call. If we are, we need to exit out, and wait until the
    // call has completed.
    _reconnectWhenCallFinishes = FALSE;
    if (self.calls.count > 0) {
        _reconnectWhenCallFinishes = TRUE;
        return;
    }
    
    // If we are connected, we need to disconnect.
    if (self.isConnected) {
        [self disconnect];
    }
    
    // Retrive the current network status. Check if the status is Cellular data, and do not connect
    // if we are configured to be wifi only.
    if ([AFNetworkReachabilityManager sharedManager].isReachableViaWWAN && [JCAppSettings sharedSettings].isWifiOnly) {
        _networkType = JCPhoneManagerNoNetwork;
        [self notifyCompletionBlock:false error:[JCPhoneManagerError errorWithCode:JS_PHONE_WIFI_DISABLED]];
        return;
    }
    
    self.connecting = TRUE;
    _networkType = (JCPhoneManagerNetworkType)[AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
        
    // If we have a line configuration for the line, try to register it.
    if (line.lineConfiguration){
        [_sipHandler registerToLine:line];
        return;
    }
        
    // If we do not have a line configuration, we need to request it.
    NSLog(@"Phone Requesting Line Configuration");
    [UIApplication showStatus:@"Selecting Line..."];
    [LineConfiguration downloadLineConfigurationForLine:line completion:^(BOOL success, NSError *error) {
        [UIApplication hideStatus];
        if (success) {
            [_sipHandler registerToLine:line];
        } else {
            self.connecting = FALSE;
            [self reportError:[JCPhoneManagerError errorWithCode:JC_PHONE_LINE_CONFIGURATION_REQUEST_ERROR underlyingError:error]];
        }
    }];
}

-(void)disconnect
{
    NSLog(@"Phone Disconnect");
    [_sipHandler unregister];
    self.calls = nil;
    self.connected = FALSE;
    self.connecting = FALSE;
}

-(void)startKeepAlive
{
    NSLog(@"Starting Keep Alive");
    if (!self.isActiveCall) {
        [_sipHandler startKeepAwake];
    }
}

-(void)stopKeepAlive
{
    NSLog(@"Stopping Keep Alive");
    [_sipHandler stopKeepAwake];
    if (!self.isActiveCall) {
        Line *line = _sipHandler.line;
        [_sipHandler unregister];
        [_bluetoothManager enableBluetoothAudio];
        [_sipHandler registerToLine:line];
    }
    else if(self.calls.count == 1 && ((JCCallCard *)self.calls.lastObject).lineSession.isIncoming){
        [_bluetoothManager enableBluetoothAudio];
    }
}

#pragma mark SipHandlerDelegate

-(void)sipHandlerDidRegister:(SipHandler *)sipHandler
{
    NSLog(@"Phone Manager Sip Handler did register");
    self.connecting = FALSE;
    self.connected = sipHandler.registered;
    [self notifyCompletionBlock:YES error:nil];
}

-(void)sipHandlerDidUnregister:(SipHandler *)sipHandler
{
    NSLog(@"Phone Manager Sip Handler did unregister");
    self.connecting = FALSE;
    self.connected = sipHandler.registered;
}

-(void)sipHandler:(SipHandler *)sipHandler didFailToRegisterWithError:(NSError *)error
{
    self.connecting = FALSE;
    self.connected = sipHandler.registered;
    [self reportError:error];
}

#pragma mark - Dialing -

/**
 *  Dial a given number string. Notify Caller on completion in block.
 *
 *  Do 911 call detection. If the number matches an emergency number, and the device can make a call 
 *  try to call. If we get a connected or dialing. Handle 911 call detection event if there is no 
 *  sip handler.
 *
 *  If we are not an emergency number, then try to connect and dial. If already connected, will dial
 *  immediately, otherwise tries to register, then dial. If we are uable to connect, we call 
 *  completion handler with success being false.
 */
-(void)dialNumber:(NSString *)dialString type:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion
{
    if ([self isEmergencyNumber:dialString] && [UIDevice currentDevice].canMakeCall) {
        [self dialEmergencyNumber:dialString type:dialType completion:completion];
        return;
    }
    
    [self connectAndDial:dialString type:dialType completion:completion];
}

-(void)connectAndDial:(NSString *)dialString type:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion
{
    if (self.isConnected) {
        [self dial:dialString type:dialType completion:completion];
        return;
    }
    
    [self connectToLine:self.line
             completion:^(BOOL success, NSError *error) {
                 if (success){
                     [self dial:dialString type:dialType completion:completion];
                     return;
                 }
                 
                 if (completion) {
                     completion(false, nil);
                 }
             }];
}

-(BOOL)isEmergencyNumber:(NSString *)dialString
{
    return [dialString isEqualToString:kJCPhoneManager911String];
    
    // TODO: Localization, detecting the emergency number based on localization for the device and cellular positioning for the carrier device.
}

-(void)dialEmergencyNumber:(NSString *)emergencyNumber type:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion
{
    #ifdef DEBUG
    emergencyNumber = kJCPhoneManager611String;
    #endif
    
    // Add notification observing of the application active event. We only observed this in this one event, since we
    // know we are causing the application to loose focus, we want to handle events when we return.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    __unsafe_unretained JCPhoneManager *weakSelf = self;
    self.externalCallCompletionHandler = ^(BOOL connected){
        if (connected) {
            completion(false, nil);
        }
        else{
            [weakSelf connectAndDial:emergencyNumber type:dialType completion:completion];
        }
    };
    
    // Configure event handling to observe the iPhone Dialer. If we are connected, flagged that we ar connected for
    // later use.
    self.externalCallConnected = false;
    self.externalCallDisconnected = false;
    _externalCallCenter = [[CTCallCenter alloc] init];
    [_externalCallCenter setCallEventHandler:^(CTCall *call){
        if ([call.callState isEqualToString: CTCallStateConnected]) {
            weakSelf.externalCallConnected = TRUE;
        }
        else if ([call.callState isEqualToString:CTCallStateDialing]) {
            weakSelf.externalCallDisconnected = FALSE;
        }
        else if ([call.callState isEqualToString:CTCallStateDisconnected]) {
            weakSelf.externalCallDisconnected = TRUE;
        }
    }];
    
    // Initiate call using the iPhone's dialer.
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", emergencyNumber]]];
}

-(void)dial:(NSString *)dialNumber type:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion
{
    if (dialType == JCPhoneManagerBlindTransfer) {
        [self blindTransferToNumber:dialNumber completion:completion];
    } else if (dialType == JCPhoneManagerWarmTransfer) {
        [self warmTransferToNumber:dialNumber completion:completion];
    } else {
        [self simpleDialNumber:dialNumber completion:completion];
    }
}

-(void)blindTransferToNumber:(NSString *)number completion:(CompletionHandler)completion
{
    [UIApplication showStatus:@"Transfering..."];
    __autoreleasing NSError *error;
    BOOL success = [_sipHandler startBlindTransferToNumber:number error:&error];
    if (completion) {
        if (!success) {
            [UIApplication hideStatus];
            completion(NO, [JCPhoneManagerError errorWithCode:JC_PHONE_BLIND_TRANSFER_FAILED reason:@"Unable to perform transfer at this time. Please Try Again." underlyingError:error]);
        } else {
            completion(YES, nil);
        }
    }
}

-(void)warmTransferToNumber:(NSString *)number completion:(CompletionHandler)completion
{
    _warmTransferNumber = number;
    __autoreleasing NSError *error;
    BOOL success = [_sipHandler startWarmTransferToNumber:number error:&error];
    if (completion) {
        completion(success, error);
    }
}

-(void)simpleDialNumber:(NSString *)number completion:(CompletionHandler)completion
{
    __autoreleasing NSError *error;
    BOOL success = [_sipHandler makeCall:number videoCall:NO error:&error];
    if (completion) {
        completion(success, error);
    }
}

-(void)finishWarmTransfer:(CompletionHandler)completion
{
    __autoreleasing NSError *error;
    BOOL success = [_sipHandler finishWarmTransfer:&error];
    if (completion) {
        completion(success, error);
    }
}

#pragma mark - Phone Actions -

-(void)answerCall:(JCCallCard *)callCard completion:(CompletionHandler)completion
{
    __autoreleasing NSError *error;
    BOOL success = [_sipHandler answerSession:callCard.lineSession error:&error];
    if (completion) {
        completion(success, error);
    }
}

-(void)hangUpCall:(JCCallCard *)callCard completion:(CompletionHandler)completion;
{
    __autoreleasing NSError *error;
    BOOL success;
    
    if ([callCard isKindOfClass:[JCConferenceCallCard class]]) {
        success = [_sipHandler endConference:&error];
        if(success){
            success = [_sipHandler hangUpAllSessions:&error];
        }
    }
    else {
        success = [_sipHandler hangUpSession:callCard.lineSession error:&error];
    }
    
    if (completion) {
        completion(success, error);
    }
}

-(void)holdCall:(JCCallCard *)callCard completion:(CompletionHandler)completion
{
    __autoreleasing NSError *error;
    BOOL success;
    
    // If we are in a conference call, all the child cards show recieve the hold call state.
    if ([callCard isKindOfClass:[JCConferenceCallCard class]]) {
        success = [_sipHandler holdLines:&error];
    }
    else {
        success = [_sipHandler holdLineSession:callCard.lineSession error:&error];
    }
    
    if (completion) {
        completion(success, error);
    }
}

-(void)unholdCall:(JCCallCard *)callCard completion:(CompletionHandler)completion
{
    __autoreleasing NSError *error;
    BOOL success;
    if ([callCard isKindOfClass:[JCConferenceCallCard class]]) {
        success = [_sipHandler unholdLines:&error];
    } else {
        // If we are not in a conference call, all other call should be placed on hold while we are
        // not on hold on a line. When a line is placed on hold, then only it should be placed on
        // hold. If it is returning from hold, all other lines should be placed on hold that are not
        // already on hold.
        for (JCCallCard *card in _calls){
            if (card != callCard){
                [_sipHandler holdLineSession:card.lineSession error:&error];
            }
        }
        success = [_sipHandler unholdLineSession:callCard.lineSession error:&error];
    }
    
    if (completion) {
        completion(success, error);
    }
}

-(void)mergeCalls:(CompletionHandler)completion
{
    // If we are already in a conference call, we do not try to start new one on top of it (it kinda
    // crashes when you do something as crazy as that, i wonder why?).
    if (self.isConferenceCall) {
        if (completion) {
            completion(NO, [JCPhoneManagerError errorWithCode:JC_PHONE_CONFERENCE_CALL_ALREADY_EXISTS]);
        }
        return;
    }
    
    // Create the conference call.
    __autoreleasing NSError *error;
    BOOL success = [_sipHandler createConference:&error];
    if (completion) {
        if (success) {
            completion(YES, nil);
        } else {
            completion(NO, [JCPhoneManagerError errorWithCode:JC_PHONE_FAILED_TO_CREATE_CONFERENCE_CALL underlyingError:error]);
        }
    }
}

-(void)splitCalls:(CompletionHandler)completion
{
    if (!self.isConferenceCall) {
        if (completion) {
            completion(NO, [JCPhoneManagerError errorWithCode:JC_PHONE_NO_CONFERENCE_CALL_TO_END]);
        }
        return;
    }
    
    // End Conference Call
    __autoreleasing NSError *error;
    BOOL success = [_sipHandler endConference:&error];
    if (completion) {
        if(success) {
            completion(YES, nil);
        }
        else {
            completion(NO, [JCPhoneManagerError errorWithCode:JC_PHONE_FAILED_ENDING_CONFERENCE_CALL underlyingError:error]);
        }
    }
}

-(void)swapCalls:(CompletionHandler)completion
{
    JCCallCard *inactiveCall = [self findInactiveCallCard];
    [self unholdCall:inactiveCall completion:completion];
}

-(void)muteCall:(BOOL)mute
{
    [_sipHandler muteCall:mute];
}

-(void)setLoudSpeakerEnabled:(BOOL)loudSpeakerEnabled
{
    [_sipHandler setLoudSpeakerEnabled:loudSpeakerEnabled];
}

-(void)numberPadPressedWithInteger:(NSInteger)numberPadNumber
{
    [_sipHandler pressNumpadButton:numberPadNumber];
}

-(void)dismissCallViewController
{
    if (_callViewController.presentedViewController != nil) {
        [_callViewController.presentedViewController dismissViewControllerAnimated:NO completion:NULL];
    }
    [_callViewController dismissViewControllerAnimated:YES completion:NULL];
    _callViewController = nil;
}

#pragma mark SipHandlerDelegate

-(void)sipHandler:(SipHandler *)sipHandler receivedIntercomLineSession:(JCLineSession *)session
{
    if(![JCAppSettings sharedSettings].isIntercomEnabled) {
        return;
    }
    
    JCCallCard *callCard = [self callCardForLineSession:session];
    if (!callCard) {
        return;
    }
    
    [self answerCall:callCard completion:^(BOOL success, NSError *error) {
        if (success) {
            // Determine if the speaker should be turned on. If we are on the built in reciever, it means we
            // are not on Bluetooth, or Airplay, etc., and are on the internal built in speaker, so we can,
            // and should enable speaker mode.
            BOOL shouldTurnOnSpeaker = FALSE;
            NSArray *currentOutputs = [AVAudioSession sharedInstance].currentRoute.outputs;
            for( AVAudioSessionPortDescription *port in currentOutputs ){
                if ([port.portType isEqualToString:AVAudioSessionPortBuiltInReceiver]) {
                    shouldTurnOnSpeaker = TRUE;
                }
            }
            sipHandler.loudSpeakerEnabled = shouldTurnOnSpeaker;
        }
    }];
}

-(void)sipHandler:(SipHandler *)sipHandler didAddLineSession:(JCLineSession *)lineSession
{
    // If we are backgrounded, push out a local notification
    if ([UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground) {
        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        if (localNotif){
            localNotif.alertBody =[NSString  stringWithFormat:@"Call from <%@>%@", lineSession.callTitle, lineSession.callDetail];
            localNotif.soundName = UILocalNotificationDefaultSoundName;
            localNotif.applicationIconBadgeNumber = 1;
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
        }
    }
    
    // Create and add the call card to the calls array
    JCCallCard *callCard = [[JCCallCard alloc] initWithLineSession:lineSession];
    callCard.delegate = self;
    NSMutableArray *calls = self.calls;
    [calls addObject:callCard];
    
    // Sort the array and fetch the resulting new index of the call card.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:NSStringFromSelector(@selector(started)) ascending:NO];
    [calls sortUsingDescriptors:@[sortDescriptor]];
    self.calls = calls;
    
    if(!_callViewController)
    {
        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        _callViewController = [rootViewController.storyboard instantiateViewControllerWithIdentifier:@"CallerViewController"];
        _callViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [rootViewController presentViewController:_callViewController animated:YES completion:NULL];
    } else {
        [_callViewController reload];
    }
}

-(void)sipHandler:(SipHandler *)sipHandler didAnswerLineSession:(JCLineSession *)lineSession
{
    JCCallCard *callCard = [self callCardForLineSession:lineSession];
    callCard.started = [NSDate date];
    if (_callViewController) {
        [_callViewController reload];
    }
}

-(void)sipHandler:(SipHandler *)sipHandler willRemoveLineSession:(JCLineSession *)session
{
    // Check to see if the line session happens to be a conference call. if it is, we need to end
    // the conference call. This will end the conference call, and it will be removed because it
    // will have been marked as inactive.
    if (session.isConference) {
        __autoreleasing NSError *error;
        [_sipHandler endConference:&error];
        return;
    }
    
    JCCallCard *callCard = [self callCardForLineSession:session];
    if (callCard) {
        [self.calls removeObject:callCard];
    }
    
    // Check to see if all the calls are gone, and perform actions closing out the caller view
    // controller, re registration if we have switched networks while on the call, and to start keep
    // alive if we were in the background when the call ends.
    NSInteger count = self.calls.count;
    if (_callViewController) {
        if (count == 0) {
            [self dismissCallViewController];
        } else {
            [_callViewController reload];
        }
    }
    
    if (_reconnectWhenCallFinishes && count == 0) {
        _reconnectWhenCallFinishes = false;
        [self connectToLine:self.line completion:self.completion];
    }
    
    // If when removing the call we are backgrounded, we tell the sip handler to operate in background mode.
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if ((state == UIApplicationStateBackground || state == UIApplicationStateInactive) && count == 0) {
        [_sipHandler startKeepAwake];
    }
}

-(void)sipHandler:(SipHandler *)sipHandler didCreateConferenceCallWithLineSessions:(NSSet *)lineSessions
{
    // Add the conference call Card
    JCConferenceCallCard *conferenceCallCard = [[JCConferenceCallCard alloc] initWithLineSessions:lineSessions];
    conferenceCallCard.delegate = self;
    
    // Blow away the previous call cards on the call array, replacing with the conference call card.
    _calls = [NSMutableArray arrayWithObject:conferenceCallCard];
    
    if (_callViewController) {
        [_callViewController startConferenceCall];
    }
}

-(void)sipHandler:(SipHandler *)sipHandler didEndConferenceCallForLineSessions:(NSSet *)lineSessions
{
    // Blow away the call cards, we are going to make new ones
    _calls = [NSMutableArray arrayWithCapacity:lineSessions.count];
    
    // Create a call card for each line session. We only re-add active lines. If we had a call fail,
    // we would have called for the conference call to have ended, and the failed line would have
    // been marked as inactive when the state changed, so we would not add it here, so the UI can
    // recover.
    for (JCLineSession *lineSession in lineSessions) {
        if(lineSession.isActive) {
            JCCallCard *callCard = [[JCCallCard alloc] initWithLineSession:lineSession];
            callCard.delegate = self;
            [_calls addObject:callCard];
        }
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:NSStringFromSelector(@selector(started)) ascending:NO];
    [_calls sortUsingDescriptors:@[sortDescriptor]];
    
    if (_callViewController) {
        [_callViewController stopConferenceCall];
    }
}

-(void)sipHandler:(SipHandler *)sipHandler didUpdateStatusForLineSessions:(NSSet *)lineSessions
{
    // Checks all active calls to see if they are updatable on status update.
    BOOL updatable = YES;
    for (JCLineSession *lineSession in lineSessions) {
        if (lineSession.isActive) {
            if (!lineSession.isUpdatable) {
                updatable = NO;
                break;
            }
        }
    }
    
    // Use the updatable state to update the call view controller UI.
    if (_callViewController) {
        _callViewController.mergeBtn.enabled        = updatable;
        _callViewController.swapBtn.enabled         = updatable;
        _callViewController.warmTransfer.enabled    = updatable;
        _callViewController.blindTransfer.enabled   = updatable;
        _callViewController.addBtn.enabled          = updatable;
    }
}

-(void)sipHandler:(SipHandler *)sipHandler didTransferCalls:(NSSet *)lineSessions
{
    [_callViewController hideStatus];
    
    // TODO: determine which line sessions are what.
    JCLineSession *transferLine;
    JCLineSession *receivingLine;
    
    for (JCLineSession *lineSession in lineSessions) {
        if (lineSession.isTransfer) {
            transferLine = lineSession;
        }
        else {
            receivingLine = lineSession;
        }
    }
    [_callViewController presentWarmTransferSuccessWithSession:transferLine receivingSession:receivingLine];
    [self performSelector:@selector(dismissCallViewController) withObject:nil afterDelay:3];
}

-(void)sipHandler:(SipHandler *)sipHandler didFailTransferWithError:(NSError *)error
{
    [_callViewController hideStatus];
    [_callViewController showError:error];
}

#pragma mark - Getters -

-(NSMutableArray *)calls
{
	if (!_calls)
		_calls = [NSMutableArray array];
	return _calls;
}

-(Line *)line
{
    if (_sipHandler) {
        return _sipHandler.line;
    }
    return nil;
}

-(BOOL)isActiveCall
{
    return (self.calls.count > 0);
}

-(BOOL)isConferenceCall
{
    return _sipHandler.isConferenceCall;
}

#pragma mark - General Private Methods -

-(JCCallCard *)findInactiveCallCard
{
    for (JCCallCard *callCard in self.calls) {
        if (callCard.lineSession.isHolding == TRUE) {
            return callCard;
        }
    }
    return nil;
}

-(JCCallCard *)callCardForLineSession:(JCLineSession *)lineSession
{
    for (JCCallCard *callCard in self.calls) {
        if (callCard.lineSession.sessionId == lineSession.sessionId){
            return callCard;
        }
    }
    return nil;
}

#pragma mark - Notification Selectors -

#pragma mark UIApplication

-(void)applicationDidBecomeActive:(NSNotification *)notification
{
    NSLog(@"application did become active");
    if (self.externalCallDisconnected)
    {
        NSLog(@"deregistering did become active, and processing call");
        
        if (self.externalCallCompletionHandler != NULL) {
            self.externalCallCompletionHandler(self.externalCallConnected);
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    }
}

#pragma mark AVAudioSession

-(void)audioSessionRouteChangeSelector:(NSNotification *)notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(audioSessionRouteChangeSelector:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    AVAudioSession *audioSession = notification.object;
    NSArray *outputs = audioSession.currentRoute.outputs;
    AVAudioSessionPortDescription *port = [outputs lastObject];
    _outputType = [self outputTypeFromString:port.portType];
    if (_callViewController) {
        _callViewController.speakerBtn.selected = (_outputType == JCPhoneManagerOutputSpeaker);
    }
}

-(JCPhoneManagerOutputType)outputTypeFromString:(NSString *)type
{
    if ([type isEqualToString:AVAudioSessionPortLineOut]) {
        return JCPhoneManagerOutputLineOut;
        
    } else if ([type isEqualToString:AVAudioSessionPortHeadphones]) {
        return JCPhoneManagerOutputHeadphones;
        
    } else if ([type isEqualToString:AVAudioSessionPortHeadphones]) {
        return JCPhoneManagerOutputHeadphones;
        
    } else if ([type isEqualToString:AVAudioSessionPortBluetoothA2DP] ||
               [type isEqualToString:AVAudioSessionPortBluetoothLE]) {
        return JCPhoneManagerOutputBluetooth;
        
    } else if ([type isEqualToString:AVAudioSessionPortBuiltInReceiver]) {
        return JCPhoneManagerOutputReceiver;
        
    } else if ([type isEqualToString:AVAudioSessionPortBuiltInSpeaker]) {
        return JCPhoneManagerOutputSpeaker;
        
    } else if ([type isEqualToString:AVAudioSessionPortHDMI]) {
        return JCPhoneManagerOutputHDMI;
        
    } else if ([type isEqualToString:AVAudioSessionPortAirPlay]) {
        return JCPhoneManagerOutputAirPlay;
    } else {
        return JCPhoneManagerOutputUnknown;
    }
}

@end

@implementation JCPhoneManager (Singleton)

+(JCPhoneManager *)sharedManager
{
    static JCPhoneManager *phoneManagerSingleton = nil;
    static dispatch_once_t phoneManagerLoaded;
    dispatch_once(&phoneManagerLoaded, ^{
        phoneManagerSingleton = [JCPhoneManager new];
    });
    return phoneManagerSingleton;
}

+ (id)copyWithZone:(NSZone *)zone
{
    return self;
}

+ (void)connectToLine:(Line *)line
{
    [[JCPhoneManager sharedManager] connectToLine:line completion:^(BOOL success, NSError *error) {
        if (error && error.code != JS_PHONE_WIFI_DISABLED && error.code != JS_PHONE_ALREADY_CONNECTING) {
            [UIApplication showError:error];
        }
        else if (error) {
            NSLog(@"%@", [error description]);
        }
    }];
}

+ (void)dialNumber:(NSString *)dialNumber type:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion
{
    [[JCPhoneManager sharedManager] dialNumber:dialNumber type:dialType completion:^(BOOL success, NSError *error) {
        if (error) {
            [UIApplication showError:error];
        }
        completion(success, error);
    }];
}

+ (void)mergeCalls:(CompletionHandler)completion
{
    [[JCPhoneManager sharedManager] mergeCalls:^(BOOL success, NSError *error) {
        if (error) {
            [UIApplication showError:error];
        }
        completion(success, error);
    }];
}

+ (void)splitCalls:(CompletionHandler)completion
{
    [[JCPhoneManager sharedManager] splitCalls:^(BOOL success, NSError *error) {
        if (error) {
            [UIApplication showError:error];
        }
        completion(success, error);
    }];
}

+ (void)swapCalls:(CompletionHandler)completion
{
    [[JCPhoneManager sharedManager] swapCalls:^(BOOL success, NSError *error) {
        if (error) {
            [UIApplication showError:error];
        }
        completion(success, error);
    }];
}

+ (void)muteCall:(BOOL)mute
{
    [[JCPhoneManager sharedManager] muteCall:mute];
}

+ (void)finishWarmTransfer:(CompletionHandler)completion
{
    [[JCPhoneManager sharedManager] finishWarmTransfer:^(BOOL success, NSError *error) {
        if (error) {
            [UIApplication showError:error];
        }
        completion(success, error);
    }];
}

+ (void)disconnect
{
    [[JCPhoneManager sharedManager] disconnect];
}

+ (void)startKeepAlive
{
    [[JCPhoneManager sharedManager] startKeepAlive];
}

+ (void)stopKeepAlive
{
    [[JCPhoneManager sharedManager] stopKeepAlive];
}

+(JCPhoneManagerNetworkType)networkType
{
    return [JCPhoneManager sharedManager].networkType;
}

+ (void)numberPadPressedWithInteger:(NSInteger)numberPad
{
    [[JCPhoneManager sharedManager] numberPadPressedWithInteger:numberPad];
}

+ (void)setLoudSpeakerEnabled:(BOOL)loudSpeakerEnabled
{
    [[JCPhoneManager sharedManager] setLoudSpeakerEnabled:loudSpeakerEnabled];
}

@end

@implementation UIViewController (PhoneManager)

- (void)dialNumber:(NSString *)phoneNumber sender:(id)sender
{
    [self dialNumber:phoneNumber sender:sender completion:NULL];
}

- (void)dialNumber:(NSString *)phoneNumber sender:(id)sender completion:(CompletionHandler)completion
{
    if([sender isKindOfClass:[UIButton class]]) {
        ((UIButton *)sender).enabled = FALSE;
    } else if ([sender isKindOfClass:[UITableView class]]) {
        ((UITableView *)sender).userInteractionEnabled = FALSE;
    }
        
    [JCPhoneManager dialNumber:phoneNumber
                          type:JCPhoneManagerSingleDial
                    completion:^(BOOL success, NSError *error) {
                        if (!success) {
                            [self showSimpleAlert:@"Warning" error:error];
                        }
                        if (completion) {
                            completion(success, error);
                        }
                        
                        if([sender isKindOfClass:[UIButton class]]) {
                            ((UIButton *)sender).enabled = TRUE;
                        } else if ([sender isKindOfClass:[UITableView class]]) {
                            ((UITableView *)sender).userInteractionEnabled = TRUE;
                        }
                    }];
}

@end
