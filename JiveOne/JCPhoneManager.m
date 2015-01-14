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
        _sipHandler = [[SipHandler alloc] initWithNumberOfLines:MAX_LINES delegate:self];
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
    
    
    // If we are connected, we need to disconnect.
    if (self.isConnected) {
        [self disconnect];
    }
    
    @try {
        // Check if we have a line. If not, we fail. We cannot register if we did not receive a line
        if (!line) {
            [NSException raise:NSInvalidArgumentException format:@"Line is null"];
        }
        
        // If we are already connecting, exit out. We only allow one connection attempt at a time.
        if (_connecting) {
            [NSException raise:NSInternalInconsistencyException format:@"Already Connecting."];
        }
        self.connecting = TRUE;
        
        // Retrive the current network status. Check if the status is Cellular data, and disconnect if
        // we are configured to be wifi only, and prevent us from reconnecting.
        if ([AFNetworkReachabilityManager sharedManager].isReachableViaWWAN && [JCAppSettings sharedSettings].isWifiOnly) {
            _networkType = JCPhoneManagerNoNetwork;
            [NSException raise:NSInternalInconsistencyException format:@"Marked as Wifi only"];
        }
        
        // Store the network type we are connecting too.
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
            }
            else
            {
                [UIApplication showSimpleAlert:@"" message:@"Unable to connect to this line at this time. Please Try again." code:error.code];
                [self reportError:error];
                self.connecting = FALSE;
            }
        }];
    }
    @catch (NSException *exception) {
        [self reportErrorWithDescription:exception.reason];
        self.connecting = FALSE;
    }
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
    else if(self.calls.count == 1 && ((JCCallCard *)self.calls.lastObject).isIncoming){
        [_bluetoothManager enableBluetoothAudio];
    }
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

-(void)dial:(NSString *)dialNumber type:(JCPhoneManagerDialType)dialType completion:(CallCompletionHandler)completion
{
    // If we are not logged in and do not have a sip handler, we must fail.
    if (!_sipHandler) {
        completion(false, nil, nil);
    }
    
    if (dialType == JCPhoneManagerBlindTransfer) {
        [_sipHandler blindTransferToNumber:dialNumber completion:^(BOOL success, NSError *error) {
            if (success) {
                [self hangUpAll];
            }
            
            if (completion != NULL)
                completion(success, nil, @{});
            
            if (error)
                NSLog(@"%@", [error description]);
        }];
        return;
    }
    
    NSString *callerId = dialNumber;
    Contact *contact = [Contact contactForExtension:dialNumber pbx:self.line.pbx];
    if (contact) {
        callerId = contact.extension;
    }
    
    JCLineSession *session = [_sipHandler makeCall:dialNumber videoCall:NO contactName:callerId];
    if (session.isActive)
    {
        session.contact = contact;
        JCCallCard *transferedCall = self.calls.lastObject;
        JCCallCard *callCard = [[JCCallCard alloc] initWithLineSession:session];
        callCard.delegate = self;
        callCard.hold = false;
        [self addCall:callCard];
        NSUInteger index = [self.calls indexOfObject:callCard];
        if (completion != NULL)
        {
            if (dialType == JCPhoneManagerWarmTransfer) {
                _warmTransferNumber = dialNumber;
                
                completion(true, nil, @{
                                   kJCPhoneManagerTransferedCall: transferedCall,
                                   kJCPhoneManagerNewCall: callCard,
                                   kJCPhoneManagerUpdatedIndex: [NSNumber numberWithInteger:index],
                                   });
            }
            else
            {
                completion(true, nil, @{
                                   kJCPhoneManagerNewCall: callCard,
                                   kJCPhoneManagerUpdatedIndex: [NSNumber numberWithInteger:index],
                                   });
            }
        }
    }
    else
    {
        NSLog(@"Error Making Call");
        if (completion != NULL)
            completion(false, nil, @{});
    }
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

#pragma mark - Phone Actions -

-(void)finishWarmTransfer:(CompletionHandler)completion
{
    if (!_sipHandler) {
        if (completion) {
            completion(NO, nil);
        }
        return;
    }
    
    if (_warmTransferNumber) {
        [_sipHandler warmTransferToNumber:_warmTransferNumber completion:^(BOOL success, NSError *error) {
            _warmTransferNumber = nil;
            if (completion) {
                completion(success, error);
            }
        }];
    }
}

-(void)mergeCalls:(CompletionHandler)completion
{
    if (!_sipHandler) {
        return;
    }
    
    bool inConference = [_sipHandler setConference:true];
    if (inConference)
    {
        NSArray *calls = self.calls;
        [self addConferenceCallWithCallArray:calls];
    }
    completion(inConference, nil);
}

-(void)splitCalls
{
    if (!_sipHandler) {
        return;
    }
    
    // Since we are only supporting two line sessions at a time, if we have a conference call, it should be the only
    // object in the array;
    JCCallCard *callCard = [self.calls objectAtIndex:0];
    if ([callCard isKindOfClass:[JCConferenceCallCard class]])
    {
        JCConferenceCallCard *conferenceCallCard = (JCConferenceCallCard *)callCard;
        [self removeConferenceCall:conferenceCallCard];
        [_sipHandler setConference:false];
    }
}

-(void)swapCalls
{
    if (!_sipHandler) {
        return;
    }
    
    JCCallCard *inactiveCall = [self findInactiveCallCard];
    inactiveCall.hold = false;
}

-(void)muteCall:(BOOL)mute
{
    if (!_sipHandler) {
        return;
    }
    
    [_sipHandler muteCall:mute];
}

-(void)setLoudSpeakerEnabled:(BOOL)loudSpeakerEnabled
{
    if (!_sipHandler) {
        return;
    }
    [_sipHandler setLoudSpeakerEnabled:loudSpeakerEnabled];
}

-(void)numberPadPressedWithInteger:(NSInteger)numberPadNumber
{
    if(!_sipHandler) {
        return;
    }
    
    char dtmf = numberPadNumber;
    switch (numberPadNumber) {
        case kTAGStar:
        {
            dtmf = 10;
            break;
        }
        case kTAGSharp:
        {
            dtmf = 11;
            break;
        }
    }
    
    [_sipHandler pressNumpadButton:dtmf];
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
        if (callCard.lineSession.mSessionId == lineSession.mSessionId){
            return callCard;
        }
    }
    return nil;
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

-(void)reportErrorWithDescription:(NSString *)description
{
    [self reportError:[NSError errorWithDomain:@"PhoneManager" code:0 userInfo:nil]];
}

#pragma mark Call Card Management

-(void)addCall:(JCCallCard *)callCard
{
    if ([self.calls containsObject:callCard])
        return;
    
    NSUInteger priorCount = self.calls.count;
    [self.calls addObject:callCard];
    
    // Sort the array and fetch the resulting new index of the call card.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"started" ascending:NO];
    [self.calls sortUsingDescriptors:@[sortDescriptor]];
    
    NSUInteger newIndex = [self.calls indexOfObject:callCard];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCPhoneManagerAddedCallNotification
                                                        object:self
                                                      userInfo:@{
                                                                 kJCPhoneManagerUpdatedIndex:[NSNumber numberWithInteger:newIndex],
                                                                 kJCPhoneManagerPriorUpdateCount:[NSNumber numberWithInteger:priorCount],
                                                                 kJCPhoneManagerUpdateCount: [NSNumber numberWithInteger:self.calls.count],
                                                                 kJCPhoneManagerIncomingCall: [NSNumber numberWithBool:callCard.isIncoming],
                                                                 kJCPhoneManagerNewCall: callCard
                                                                 }];
}

-(void)removeCall:(JCCallCard *)callCard
{
    if (![self.calls containsObject:callCard])
        return;
    
    NSUInteger index = [self.calls indexOfObject:callCard];
    NSUInteger priorCount = self.calls.count;
    [self.calls removeObject:callCard];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCPhoneManagerRemoveCallNotification
                                                        object:self
                                                      userInfo:@{
                                                                 kJCPhoneManagerUpdatedIndex:[NSNumber numberWithInteger:index],
                                                                 kJCPhoneManagerPriorUpdateCount:[NSNumber numberWithInteger:priorCount],
                                                                 kJCPhoneManagerUpdateCount:[NSNumber numberWithInteger:self.calls.count],
                                                                 kJCPhoneManagerRemovedCall: callCard
                                                                 }];
    
    // If when removing the call we are backgrounded, we tell the sip handler to operate in background mode.
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if ((state == UIApplicationStateBackground || state == UIApplicationStateInactive) && self.calls.count == 0) {
        [_sipHandler startKeepAwake];
    }
}

-(void)addConferenceCallWithCallArray:(NSArray *)callCards
{
    if (!callCards || callCards.count < 2)
        return;
    
    NSUInteger priorCount = self.calls.count;
    NSMutableArray *removeCells = [NSMutableArray array];
    NSMutableArray *calls = [NSMutableArray arrayWithArray:self.calls];
    
    for (JCCallCard *callCard in callCards)
    {
        if ([self.calls containsObject:callCard]) {
            [removeCells addObject:[NSNumber numberWithInteger:[self.calls indexOfObject:callCard]]];
            [calls removeObject:callCard];
        }
    }
    
    self.calls = calls;
    JCCallCard *conferenceCall = [[JCConferenceCallCard alloc] initWithCalls:callCards];
    [self setCallHold:false forCall:conferenceCall];
    conferenceCall.delegate = self;
    [self.calls addObject:conferenceCall];
    NSNumber *index = [NSNumber numberWithInteger:[self.calls indexOfObject:conferenceCall]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCPhoneManagerAddedConferenceCallNotification
                                                        object:self
                                                      userInfo:@{
                                                                 kJCPhoneManagerUpdatedIndex : index,
                                                                 kJCPhoneManagerPriorUpdateCount : [NSNumber numberWithInteger:priorCount],
                                                                 kJCPhoneManagerUpdateCount : [NSNumber numberWithInteger:self.calls.count],
                                                                 kJCPhoneManagerRemovedCells : removeCells
                                                                 }];
}

-(void)removeConferenceCall:(JCConferenceCallCard *)conferenceCallCard
{
    if (![self.calls containsObject:conferenceCallCard]) {
        return;
    }
    
    NSArray *callCards = conferenceCallCard.calls;
    NSUInteger priorCount = self.calls.count;
    NSInteger removeIndex = [self.calls indexOfObject:conferenceCallCard];
    [self.calls removeObject:conferenceCallCard];
    
    NSMutableArray *addCalls = [NSMutableArray array];
    NSMutableArray *calls = [NSMutableArray arrayWithArray:_calls];
    
    for (JCCallCard *callCard in callCards) {
        [calls addObject:callCard];
        [addCalls addObject:[NSNumber numberWithInteger:[calls indexOfObject:callCard]]];
    }
    self.calls = calls;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCPhoneManagerRemoveConferenceCallNotification
                                                        object:self
                                                      userInfo:@{
                                                                 kJCPhoneManagerUpdatedIndex : [NSNumber numberWithInteger:removeIndex],
                                                                 kJCPhoneManagerPriorUpdateCount : [NSNumber numberWithInteger:priorCount],
                                                                 kJCPhoneManagerUpdateCount : [NSNumber numberWithInteger:self.calls.count],
                                                                 kJCPhoneManagerAddedCells : addCalls
                                                                 }];
}

-(void)hangUpAll
{
    for (JCCallCard *call in self.calls) {
        if (call.lineSession.isActive) {
            [self hangUpCall:call];
        }
    }
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

#pragma mark - Delegate Handlers -

#pragma mark JCCallCardDelegate

/**
 * Answer the call by notifying the sip handler to answer the passed call.
 */
-(void)answerCall:(JCCallCard *)callCard
{
    if (!_sipHandler) {
        return;
    }
    
    [_sipHandler answerSession:callCard.lineSession completion:^(BOOL success, NSError *error) {
        if (success)
        {
            callCard.started = [NSDate date];
            callCard.hold = false;
            
            NSDictionary *userInfo = @{kJCPhoneManagerUpdatedIndex:[NSNumber numberWithInteger:[self.calls indexOfObject:callCard]],
                                       kJCPhoneManagerIncomingCall: [NSNumber numberWithBool:callCard.isIncoming],
                                       kJCPhoneManagerLastCallState:[NSNumber numberWithInt:callCard.callState]};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kJCPhoneManagerAnswerCallNotification object:self userInfo:userInfo];
        }
        else
        {
            NSLog(@"%@", [error description]);
        }
    }];
}

-(void)hangUpCall:(JCCallCard *)callCard
{
    if (!_sipHandler) {
        return;
    }
    
    if ([callCard isKindOfClass:[JCConferenceCallCard class]]) {
        JCConferenceCallCard *conferenceCall = (JCConferenceCallCard *)callCard;
        for (JCCallCard *call in conferenceCall.calls) {
            [self hangUpCall:call];
        }
        // remove conference card
        [self removeCall:callCard];
    }
    else
    {
        [_sipHandler hangUpSession:callCard.lineSession completion:^(BOOL success, NSError *error) {
            [self removeCall:callCard];
        }];
    }
}

-(void)setCallHold:(bool)hold forCall:(JCCallCard *)callCard
{
    if (!_sipHandler) {
        return;
    }
    
    // If we are in a conference call, all the child cards show recieve the hold call state.
    if ([callCard isKindOfClass:[JCConferenceCallCard class]]) {
        JCConferenceCallCard *conferenceCall = (JCConferenceCallCard *)callCard;
        for (JCCallCard *card in conferenceCall.calls) {
            [_sipHandler setHoldCallState:hold forSessionId:card.lineSession.mSessionId];
        }
    }
    
    // If we are not in a conference call, all other call should be placed on hold while we are not on hold on a line.
    // When a line is placed on hold, then only it should be placed on hold. If it is returning from hold, all other
    // lines should be placed on hold that are not already on hold.
    else{
        if (!hold){
            for (JCCallCard *card in self.calls){
                if (card != callCard){
                    [_sipHandler setHoldCallState:TRUE forSessionId:card.lineSession.mSessionId];
                }
            }
        }
        [_sipHandler setHoldCallState:hold forSessionId:callCard.lineSession.mSessionId];
    }
}

#pragma mark SipHanglerDelegate

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
    NSString *message = [NSString stringWithFormat:@"Phone did fail to connect with error: %@", [error description]];
    [UIApplication showSimpleAlert:@"Error" message:message];
    [self reportError:error];
}

-(void)sipHandler:(SipHandler *)sipHandler receivedIntercomLineSession:(JCLineSession *)session
{
    if(![JCAppSettings sharedSettings].isIntercomEnabled) {
        return;
    }
    
    JCCallCard *callCard = [self callCardForLineSession:session];
    if (!callCard) {
        return;
    }
    
    [self answerCall:callCard];
    
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
    session.contact = [Contact contactForExtension:session.callDetail pbx:self.line.pbx];
    callCard.delegate = self;
    [self addCall:callCard];
}

-(void)sipHandler:(SipHandler *)sipHandler willRemoveLineSession:(JCLineSession *)session
{
    JCCallCard *callCard = [self callCardForLineSession:session];
    if (!callCard) {
        return;
    }
    
    [self removeCall:callCard];
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
    [[JCPhoneManager sharedManager] connectToLine:line completion:NULL];
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

+ (BOOL)isActiveCall {
    return ([JCPhoneManager sharedManager].calls.count > 0);
}

+ (void)setReconnectAfterCallsFinishes {
    [JCPhoneManager sharedManager].reconnectAfterCallFinishes = TRUE;
}

+ (void)dialNumber:(NSString *)dialNumber type:(JCPhoneManagerDialType)dialType completion:(CallCompletionHandler)completion
{
    [[JCPhoneManager sharedManager] dialNumber:dialNumber type:dialType completion:completion];
}

+ (void)mergeCalls:(CompletionHandler)completion
{
    [[JCPhoneManager sharedManager] mergeCalls:completion];
}

+ (void)splitCalls
{
    [[JCPhoneManager sharedManager] splitCalls];
}

+ (void)swapCalls
{
    [[JCPhoneManager sharedManager] swapCalls];
}

+ (void)muteCall:(BOOL)mute
{
    [[JCPhoneManager sharedManager] muteCall:mute];
}

+ (void)finishWarmTransfer:(CompletionHandler)completion
{
    [[JCPhoneManager sharedManager] finishWarmTransfer:completion];
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