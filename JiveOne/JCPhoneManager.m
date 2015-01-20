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

// Categories
#import "UIViewController+HUD.h"

NSString *const kJCPhoneManager911String = @"911";
NSString *const kJCPhoneManager611String = @"611";

NSString *const kJCPhoneManagerAddedCallNotification            = @"addedCall";
NSString *const kJCPhoneManagerAnswerCallNotification           = @"answerCall";
NSString *const kJCPhoneManagerRemoveCallNotification           = @"removedCall";
NSString *const kJCPhoneManagerAddedConferenceCallNotification  = @"addedConferenceCall";
NSString *const kJCPhoneManagerRemoveConferenceCallNotification = @"removeConferenceCall";

NSString *const kJCPhoneManagerUpdatedIndex      = @"index";
NSString *const kJCPhoneManagerPriorUpdateCount  = @"priorCount";
NSString *const kJCPhoneManagerUpdateCount       = @"updateCount";
NSString *const kJCPhoneManagerRemovedCells      = @"removedCells";
NSString *const kJCPhoneManagerAddedCells        = @"addedCells";
NSString *const kJCPhoneManagerLastCallState     = @"lastCallState";

NSString *const kJCPhoneManagerNewCall           = @"newCall";
NSString *const kJCPhoneManagerActiveCall        = @"activeCall";
NSString *const kJCPhoneManagerIncomingCall      = @"incomingCall";
NSString *const kJCPhoneManagerTransferedCall    = @"transferedCall";
NSString *const kJCPhoneManagerRemovedCall  = @"removedCall";

@interface JCPhoneManager ()<SipHandlerDelegate, JCCallCardDelegate>
{
    JCBluetoothManager *_bluetoothManager;
    SipHandler *_sipHandler;
	NSString *_warmTransferNumber;
    CTCallCenter *_externalCallCenter;
    
    BOOL _reconnectWhenCallFinishes;
    
    CallCompletionHandler _callCompletionHandler;
    
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
    [UIApplication showHudWithTitle:@"" message:@"Selecting Line..."];
    [LineConfiguration downloadLineConfigurationForLine:line completion:^(BOOL success, NSError *error) {
        [UIApplication hideHud];
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
    else if(self.calls.count == 1 && ((JCCallCard *)self.calls.lastObject).lineSession.isIncomming){
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
-(void)dialNumber:(NSString *)dialString type:(JCPhoneManagerDialType)dialType completion:(CallCompletionHandler)completion
{
    if ([self isEmergencyNumber:dialString] && [UIDevice currentDevice].canMakeCall) {
        [self dialEmergencyNumber:dialString type:dialType completion:completion];
        return;
    }
    
    [self connectAndDial:dialString type:dialType completion:completion];
}

-(void)connectAndDial:(NSString *)dialString type:(JCPhoneManagerDialType)dialType completion:(CallCompletionHandler)completion
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
                     completion(false, nil, nil);
                 }
             }];
}

-(BOOL)isEmergencyNumber:(NSString *)dialString
{
    return [dialString isEqualToString:kJCPhoneManager911String];
    
    // TODO: Localization, detecting the emergency number based on localization for the device and cellular positioning for the carrier device.
}

-(void)dialEmergencyNumber:(NSString *)emergencyNumber type:(JCPhoneManagerDialType)dialType completion:(CallCompletionHandler)completion
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
            completion(false, nil, nil);
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

-(void)dial:(NSString *)dialNumber type:(JCPhoneManagerDialType)dialType completion:(CallCompletionHandler)completion
{
    if (dialType == JCPhoneManagerBlindTransfer) {
        [_sipHandler blindTransferToNumber:dialNumber completion:^(BOOL success, NSError *error) {
            if (success) {
                __autoreleasing NSError *hangupError;
                [_sipHandler hangUpAllSessions:&hangupError];
            }
            
            if (completion != NULL)
                completion(success, nil, @{});
            
            if (error)
                NSLog(@"%@", [error description]);
        }];
        return;
    } else if (dialType == JCPhoneManagerWarmTransfer) {
        _warmTransferNumber = dialNumber;
    }
    
    _callCompletionHandler = completion;
    __autoreleasing NSError *error;
    BOOL success = [_sipHandler makeCall:dialNumber videoCall:NO error:&error];
    if (completion) {
        if (!success) {
            completion(false, error, nil);
            _callCompletionHandler = nil;
        }
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

-(void)finishWarmTransfer:(CompletionHandler)completion
{
    if (_warmTransferNumber) {
        [_sipHandler warmTransferToNumber:_warmTransferNumber completion:^(BOOL success, NSError *error) {
            _warmTransferNumber = nil;
            if (completion) {
                completion(success, error);
            }
        }];
    }
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

-(void)sipHandler:(SipHandler *)sipHandler didAddLineSession:(JCLineSession *)session
{
    // If we are backgrounded, push out a local notification
    if ([UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground) {
        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        if (localNotif){
            localNotif.alertBody =[NSString  stringWithFormat:@"Call from <%@>%@", session.callTitle, session.callDetail];
            localNotif.soundName = UILocalNotificationDefaultSoundName;
            localNotif.applicationIconBadgeNumber = 1;
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
        }
    }
    
    JCCallCard *callCard = [[JCCallCard alloc] initWithLineSession:session];
    callCard.delegate = self;
    
    
    if ([self.calls containsObject:callCard])
        return;
    
    NSUInteger priorCount = self.calls.count;
    [self.calls addObject:callCard];
    
    // Sort the array and fetch the resulting new index of the call card.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:NSStringFromSelector(@selector(started)) ascending:NO];
    [self.calls sortUsingDescriptors:@[sortDescriptor]];
    
    NSDictionary *userInfo = @{
                               kJCPhoneManagerUpdatedIndex:[NSNumber numberWithInteger:[self.calls indexOfObject:callCard]],
                               kJCPhoneManagerPriorUpdateCount:[NSNumber numberWithInteger:priorCount],
                               kJCPhoneManagerUpdateCount: [NSNumber numberWithInteger:self.calls.count],
                               kJCPhoneManagerIncomingCall: [NSNumber numberWithBool:session.isIncomming]
                               };
    
    [self postNotificationNamed:kJCPhoneManagerAddedCallNotification userInfo:userInfo];
    
    NSInteger index = [self.calls indexOfObject:callCard];
    if (_callCompletionHandler) {
        //        if (_warmTransferNumber) {
        //            _callCompletionHandler(true, nil, @{kJCPhoneManagerTransferedCall: transferedCall,
        //                                                kJCPhoneManagerNewCall: callCard,
        //                                                kJCPhoneManagerUpdatedIndex: [NSNumber numberWithInteger:index]});
        //
        //        } else {
        _callCompletionHandler(true, nil, @{kJCPhoneManagerNewCall: callCard,
                                            kJCPhoneManagerUpdatedIndex: [NSNumber numberWithInteger:index]});
    }
}

-(void)sipHandler:(SipHandler *)sipHandler didAnswerLineSession:(JCLineSession *)lineSession
{
    JCCallCard *callCard = [self callCardForLineSession:lineSession];
    callCard.started = [NSDate date];
    NSDictionary *userInfo = @{kJCPhoneManagerUpdatedIndex:[NSNumber numberWithInteger:[self.calls indexOfObject:callCard]],
                               kJCPhoneManagerIncomingCall: [NSNumber numberWithBool:callCard.lineSession.isIncomming],
                               kJCPhoneManagerLastCallState:[NSNumber numberWithInt:callCard.lineSession.sessionState]};
    
    [self postNotificationNamed:kJCPhoneManagerAnswerCallNotification userInfo:userInfo];
}

-(void)sipHandler:(SipHandler *)sipHandler willRemoveLineSession:(JCLineSession *)session
{
    JCCallCard *callCard = [self callCardForLineSession:session];
    if (!callCard) {
        return;
    }
    
    NSMutableArray *calls = self.calls;
    if (![calls containsObject:callCard])
        return;
    
    NSUInteger index = [self.calls indexOfObject:callCard];
    NSUInteger priorCount = self.calls.count;
    [calls removeObject:callCard];
    self.calls = calls;
    
    NSDictionary *userInfo = @{kJCPhoneManagerUpdatedIndex:[NSNumber numberWithInteger:index],
                               kJCPhoneManagerPriorUpdateCount:[NSNumber numberWithInteger:priorCount],
                               kJCPhoneManagerUpdateCount:[NSNumber numberWithInteger:calls.count],
                               kJCPhoneManagerRemovedCall: callCard
                               };
    
    [self postNotificationNamed:kJCPhoneManagerRemoveCallNotification userInfo:userInfo];
    
    if (_reconnectWhenCallFinishes && calls.count == 0) {
        _reconnectWhenCallFinishes = false;
        [self connectToLine:self.line completion:self.completion];
    }
    
    // If when removing the call we are backgrounded, we tell the sip handler to operate in background mode.
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if ((state == UIApplicationStateBackground || state == UIApplicationStateInactive) && calls.count == 0) {
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
    
    // Notify of the change.
    [self postNotificationNamed:kJCPhoneManagerAddedConferenceCallNotification];
}

-(void)sipHandler:(SipHandler *)sipHandler didEndConferenceCallForLineSessions:(NSSet *)lineSessions
{
    // Blow away the call cards, we are going to make new ones
    _calls = [NSMutableArray arrayWithCapacity:lineSessions.count];
    
    // Create a call card for each line session.
    for (JCLineSession *lineSession in lineSessions) {
        JCCallCard *callCard = [[JCCallCard alloc] initWithLineSession:lineSession];
        callCard.delegate = self;
        [_calls addObject:callCard];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:NSStringFromSelector(@selector(started)) ascending:NO];
    [_calls sortUsingDescriptors:@[sortDescriptor]];
    
    [self postNotificationNamed:kJCPhoneManagerRemoveConferenceCallNotification];
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
    self.outputType = [self outputTypeFromString:port.portType];
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
            [UIApplication showSimpleAlert:@"Warning" error:error];
        }
        else if (error) {
            NSLog(@"%@", [error description]);
        }
    }];
}

+ (void)dialNumber:(NSString *)dialNumber type:(JCPhoneManagerDialType)dialType completion:(CallCompletionHandler)completion
{
    [[JCPhoneManager sharedManager] dialNumber:dialNumber type:dialType completion:^(BOOL success, NSError *error, NSDictionary *userInfo) {
        if (error) {
            NSLog(@"%@", [error description]);
        }
        completion(success, error, userInfo);
    }];
}

+ (void)mergeCalls:(CompletionHandler)completion
{
    [[JCPhoneManager sharedManager] mergeCalls:^(BOOL success, NSError *error) {
        if (error) {
            NSLog(@"%@", [error description]);
        }
        completion(success, error);
    }];
}

+ (void)splitCalls:(CompletionHandler)completion
{
    [[JCPhoneManager sharedManager] splitCalls:^(BOOL success, NSError *error) {
        if (error) {
            NSLog(@"%@", [error description]);
        }
        completion(success, error);
    }];
}

+ (void)swapCalls:(CompletionHandler)completion
{
    [[JCPhoneManager sharedManager] swapCalls:^(BOOL success, NSError *error) {
        if (error) {
            NSLog(@"%@", [error description]);
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
            NSLog(@"%@", [error description]);
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