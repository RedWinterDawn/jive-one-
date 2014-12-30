//
//  JCPhoneManager.m
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import AVFoundation;
@import CoreTelephony;

#import "JCPhoneManager.h"
#import "JCAppSettings.h"

// Managers
#import "JCBluetoothManager.h"
#import "SipHandler.h"
#import "JCV4ProvisioningClient.h"

// Objects
#import "JCLineSession.h"
#import "JCConferenceCallCard.h"

// Categories
#import "UIDevice+Custom.h"
#import "Contact.h"
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

@interface JCPhoneManager ()<SipHandlerDelegate, JCCallCardDelegate>
{
    CompletionHandler _completion;
    JCBluetoothManager *_bluetoothManager;
    AFNetworkReachabilityStatus _previousNetworkStatus;
    SipHandler *_sipHandler;
	NSString *_warmTransferNumber;
    CTCallCenter *_externalCallCenter;
    BOOL _connecting;
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
        
        // Register for app notifications
        _previousNetworkStatus = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(networkConnectivityChanged:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
        [center addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [center addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [center addObserver:self selector:@selector(audioSessionRouteChangeSelector:) name:AVAudioSessionRouteChangeNotification object:nil];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods -

/**
 *  Registers the phone manager to a particualar line.
 *
 *  If we are already connecting, we limit them so that they can not make multiple concurrent
 *  reconnect events at the same time.
 */
-(void)connectToLine:(Line *)line completion:(CompletionHandler)completion
{
//    check the user settings to see if they will let us call over cell and if we have wifi regester anyways
    if ([JCAppSettings sharedSettings].isWifiOnly && _previousNetworkStatus == AFNetworkReachabilityStatusReachableViaWWAN) {
        NSLog(@"Failed to regester please check your wifi, or enable calls over cell in settings page  : %d ", [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus);
    }
    else
    {
//        [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus
        if (_connecting) {
            return;
        }
    
        _connecting = TRUE;
        _completion = completion;
        
        // If we have a line configuration for the line, try to register it.
        //TODO: Check this stuff
            if (line.lineConfiguration){
                [self registerToLine:line];
                return;
            }
    
        // If we do not have a line configuration, we need to request it.
        [UIApplication showHudWithTitle:@"" message:@"Selecting Line..."];
        [JCV4ProvisioningClient requestProvisioningForLine:line completed:^(BOOL success, NSError *error) {
            [UIApplication hideHud];
            if (success) {
                [self registerToLine:line];
                return;
            }
        
            [UIApplication showSimpleAlert:@"" message:@"Unable to connect to this line at this time. Please Try again." code:error.code];
            if (completion) {
                completion(success, error);
            }
        }];
    }
    
}

-(void)reconnectToLine:(Line *)line completion:(CompletionHandler)completion
{
    if (_sipHandler && (_line == line)) {
        [_sipHandler connect:completion];
    } else {
        [self connectToLine:line completion:completion];
    }
}


#pragma mark NetworkConnectivity

-(void)networkConnectivityChanged:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    AFNetworkReachabilityStatus status = (AFNetworkReachabilityStatus)((NSNumber *)[userInfo valueForKey:AFNetworkingReachabilityNotificationStatusItem]).integerValue;
    NSLog(@"AFNetworking status change");
    
    if (_previousNetworkStatus == AFNetworkReachabilityStatusUnknown)
        _previousNetworkStatus = status;
    
    switch (status)
    {
        case AFNetworkReachabilityStatusNotReachable:
            break;
            
        case AFNetworkReachabilityStatusReachableViaWiFi: {
            
            // If we are not transitioning from cellular to wifi, reconnect
            if (_previousNetworkStatus != AFNetworkReachabilityStatusReachableViaWWAN && _previousNetworkStatus != AFNetworkReachabilityStatusReachableViaWiFi)
                [self reconnectToLine:_line completion:NULL];
            break;
        }
        default:
            [self reconnectToLine:_line completion:NULL];
            break;
    }
    _previousNetworkStatus = status;
}

-(void)disconnect
{
    [_sipHandler disconnect];
    _sipHandler = nil;
    self.connected = FALSE;
}

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
-(void)dialNumber:(NSString *)dialString type:(JCPhoneManagerDialType)dialType completion:(void (^)(BOOL, NSDictionary *))completion
{
    if ([self isEmergencyNumber:dialString] && [UIDevice currentDevice].canMakeCall) {
        [self dialEmergencyNumber:dialString type:dialType completion:completion];
        return;
    }
    
    [self connectAndDial:dialString type:dialType completion:completion];
}

-(void)finishWarmTransfer:(void (^)(BOOL success))completion
{
    if (!_sipHandler) {
        return;
    }
    
    if (_warmTransferNumber) {
		[_sipHandler warmTransferToNumber:_warmTransferNumber completion:^(BOOL success, NSError *error) {
            _warmTransferNumber = nil;
            completion(success);
            if (error) {
                NSLog(@"%@", [error description]);
            }
        }];
	}
}

-(void)mergeCalls:(void (^)(BOOL success))completion
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
	completion(inConference);
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

#pragma mark - Private -

-(void)registerToLine:(Line *)line
{
    // If we have a sip handler, disconnect the current registration.
    if (_sipHandler && _line != line) {
        [self disconnect];
    }
    
    _line = line;
    _sipHandler = [[SipHandler alloc] initWithLine:line delegate:self];
}

-(void)connectAndDial:(NSString *)dialString type:(JCPhoneManagerDialType)dialType completion:(void (^)(BOOL success, NSDictionary *callInfo))completion
{
    // If we are connected, we should be able to place a phone call.
    if (_connected) {
        [self dial:dialString type:dialType completion:completion];
        return;
    }
    
    [self reconnectToLine:_line
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

-(void)dial:(NSString *)dialNumber type:(JCPhoneManagerDialType)dialType completion:(void (^)(BOOL success, NSDictionary *callInfo))completion
{
    // If we are not logged in and do not have a sip handler, we must fail.
    if (!_sipHandler) {
        completion(false, nil);
    }
    
    if (dialType == JCPhoneManagerBlindTransfer) {
        [_sipHandler blindTransferToNumber:dialNumber completion:^(BOOL success, NSError *error) {
            if (success) {
                [self hangUpAll];
            }
            
            if (completion != NULL)
                completion(success, @{});
            
            if (error)
                NSLog(@"%@", [error description]);
        }];
        return;
    }
    
    JCLineSession *session = [_sipHandler makeCall:dialNumber videoCall:NO contactName:[self getContactNameByNumber:dialNumber]];
    if (session.isActive)
    {
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
                
                completion(true, @{
                                   kJCPhoneManagerTransferedCall: transferedCall,
                                   kJCPhoneManagerNewCall: callCard,
                                   kJCPhoneManagerUpdatedIndex: [NSNumber numberWithInteger:index],
                                   });
            }
            else
            {
                completion(true, @{
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
            completion(false, @{});
    }
}

#pragma mark Emergency Numbers

-(BOOL)isEmergencyNumber:(NSString *)dialString
{
    return [dialString isEqualToString:kJCPhoneManager911String];
    
    // TODO: Localization, detecting the emergency number based on localization for the device and cellular positioning for the carrier device.
}

-(void)dialEmergencyNumber:(NSString *)emergencyNumber type:(JCPhoneManagerDialType)dialType completion:(void (^)(BOOL, NSDictionary *))completion
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

-(JCCallCard *)findInactiveCallCard
{
    for (JCCallCard *callCard in self.calls) {
        if (callCard.lineSession.isHolding == TRUE) {
            return callCard;
        }
    }
    return nil;
}

-(NSString *)getContactNameByNumber:(NSString *)number
{
    Contact *contact = [Contact MR_findFirstByAttribute:@"extension" withValue:number];
    if (contact) {
        return contact.name;
    }
    
    return nil;
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
                                                                 kJCPhoneManagerIncomingCall: [NSNumber numberWithBool:callCard.isIncoming]
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
                                                                 kJCPhoneManagerUpdateCount:[NSNumber numberWithInteger:self.calls.count]
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

-(void)applicationDidEnterBackground:(NSNotification *)notification
{
    if (_sipHandler && self.calls.count == 0) {
        [_sipHandler startKeepAwake];
    }
}

-(void)applicationWillEnterForeground:(NSNotification *)notification
{
    if (_sipHandler) {
        [_sipHandler stopKeepAwake];
        if (self.calls.count == 0) {
            [_sipHandler disconnect];
            [_bluetoothManager enableBluetoothAudio];
            [_sipHandler connect:NULL];
        }
        else if(self.calls.count == 1 && ((JCCallCard *)self.calls.lastObject).isIncoming)
        {
            [_bluetoothManager enableBluetoothAudio];
        }
    }
}

#pragma mark VAAudioSession

-(void)audioSessionRouteChangeSelector:(NSNotification *)notification
{
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
    if ([callCard isKindOfClass:[JCConferenceCallCard class]])
    {
        JCConferenceCallCard *conferenceCall = (JCConferenceCallCard *)callCard;
        for (JCCallCard *card in conferenceCall.calls)
        {
            [_sipHandler setHoldCallState:hold forSessionId:card.lineSession.mSessionId];
        }
    }
    
    // If we are not in a conference call, all other call should be placed on hold while we are not on hold on a line.
    // When a line is placed on hold, then only it should be placed on hold. If it is returning from hold, all other
    // lines should be placed on hold that are not already on hold.
    else
    {
        if (!hold)
        {
            for (JCCallCard *card in self.calls)
            {
                if (card != callCard)
                {
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
    self.connecting = FALSE;
    self.connected = sipHandler.registered;
    if (_completion) {
        _completion(true, nil);
    }
}

-(void)sipHandlerDidFailToRegister:(SipHandler *)sipHandler error:(NSError *)error
{
    self.connecting = FALSE;
    self.connected = sipHandler.registered;
    if (_completion) {
        _completion(FALSE, error);
    }
    NSLog(@"%@", [error description]);
}

- (void)answerAutoCall:(JCLineSession *)session
{
	for (JCCallCard *callCard in self.calls) {
		if (callCard.lineSession.mSessionId == session.mSessionId)
		{
			[self answerCall:callCard];
		}
	}
}

-(void)addLineSession:(JCLineSession *)session
{
    JCCallCard *callCard = [[JCCallCard alloc] initWithLineSession:session];
    callCard.delegate = self;
    [self addCall:callCard];
}

-(void)removeLineSession:(JCLineSession *)session
{
    for (JCCallCard *callCard in self.calls) {
        if (callCard.lineSession.mSessionId == session.mSessionId)
        {
            [self removeCall:callCard];
            break;
        }
    }
}

@end

@implementation JCPhoneManager (Singleton)

+(JCPhoneManager *)sharedManager
{
    static JCPhoneManager *phoneManagerSingleton = nil;
    static dispatch_once_t phoneManagerLoaded;
    dispatch_once(&phoneManagerLoaded, ^{
        phoneManagerSingleton = [[JCPhoneManager alloc] init];
    });
    return phoneManagerSingleton;
}

+ (id)copyWithZone:(NSZone *)zone
{
    return self;
}

+ (void)connectToLine:(Line *)line completion:(CompletionHandler)completed
{
    NSLog(@"Check network");
    
    
    [[JCPhoneManager sharedManager] connectToLine:line completion:completed];
}

+ (void)reconnectToLine:(Line *)line completion:(CompletionHandler)completed
{
    [[JCPhoneManager sharedManager] reconnectToLine:line completion:completed];
}

+ (void)disconnect
{
    [[JCPhoneManager sharedManager] disconnect];
}

@end