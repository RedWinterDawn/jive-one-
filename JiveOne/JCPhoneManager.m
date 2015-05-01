//
//  JCPhoneManager.m
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <objc/runtime.h>

@import AVFoundation;
@import CoreTelephony;

#define MAX_LINES 2
#define DEFAULT_PHONE_MANAGER_STORYBOARD_NAME @"PhoneManager"

#import "JCPhoneManager.h"
#import "JCPhoneManagerError.h"

// Managers
#import "JCSipManager.h"
#import "LineConfiguration+V4Client.h"
#import "JCAppSettings.h"

// Objects
#import "JCPhoneBook.h"
#import "JCCallCard.h"
#import "JCLineSession.h"
#import "JCConferenceCallCard.h"

// Managed Objects
#import "Line.h"
#import "MissedCall.h"
#import "OutgoingCall.h"
#import "IncomingCall.h"

// View Controllers
#import "JCCallerViewController.h"
#import "JCTransferConfirmationViewController.h"

NSString *const kJCPhoneManager911String = @"911";
NSString *const kJCPhoneManager611String = @"611";

NSString *const kJCPhoneManagerRegisteringNotification              = @"phoneManagerRegistering";
NSString *const kJCPhoneManagerRegisteredNotification               = @"phoneManagerRegistered";
NSString *const kJCPhoneManagerUnregisteredNotification             = @"phoneManagerUnregistered";
NSString *const kJCPhoneManagerRegistrationFailureNotification      = @"phoneManagerRegistrationFailed";

NSString *const kJCPhoneManagerShowCallsNotification                = @"phoneManagerShowCalls";
NSString *const kJCPhoneManagerHideCallsNotification                = @"phoneManagerHideCalls";

@interface JCPhoneManager ()<JCSipManagerDelegate, JCCallCardDelegate, JCPhoneAudioManagerDelegate>
{
    JCPhoneAudioManager *_audioManager;
    JCCallerViewController *_callViewController;
    JCTransferConfirmationViewController *_transferConfirmationViewController;
	NSString *_warmTransferNumber;
    CTCallCenter *_externalCallCenter;
}

@property (copy)void (^externalCallCompletionHandler)(BOOL connected);
@property (nonatomic) BOOL externalCallConnected;
@property (nonatomic) BOOL externalCallDisconnected;

@property (nonatomic, strong) JCSipManager *sipManager;
@property (nonatomic, strong) UIStoryboard *storyboard;
@property (nonatomic, strong) JCAppSettings *appSettings;
@property (nonatomic, strong) JCPhoneBook *phoneBook;
@property (nonatomic, strong) AFNetworkReachabilityManager *networkReachabilityManager;

@end

@implementation JCPhoneManager

-(id)init
{
    __autoreleasing NSError *error;
    JCSipManager *sipManager = [[JCSipManager alloc] initWithNumberOfLines:MAX_LINES delegate:self error:&error];
    
    return [self initWithSipManager:sipManager
                        appSettings:[JCAppSettings sharedSettings]
                          phoneBook:[JCPhoneBook sharedPhoneBook]
                reachabilityManager:[AFNetworkReachabilityManager sharedManager]];
}

-(instancetype)initWithSipManager:(JCSipManager *)sipManager
                      appSettings:(JCAppSettings *)appSettings
                        phoneBook:(JCPhoneBook *)phoneBook
              reachabilityManager:(AFNetworkReachabilityManager *)reachabilityManager
{
    self = [super init];
    if (self) {
        _storyboardName = DEFAULT_PHONE_MANAGER_STORYBOARD_NAME;
        _sipManager = sipManager;
        _appSettings = appSettings;
        _phoneBook = phoneBook;
        _networkReachabilityManager = reachabilityManager;
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Connection -

- (void)connectToLine:(Line *)line
{
    [self connectToLine:line completion:NULL];
}

/**
 *  Registers the phone manager to a particualar line.
 *
 *  If we are already connecting, we limit them so that they can not make multiple concurrent
 *  reconnect events at the same time.
 */
-(void)connectToLine:(Line *)line completion:(CompletionHandler)completion
{
    
    self.completion = ^(BOOL success, NSError *error) {
        if (error){
            
            // If we get a registration timeout, we have ecountered a fatal error and need to
            // restart the application. We exit the app by raising an exception, whic will be
            // by our analytics.
            if(error.code == JC_SIP_REGISTRATION_TIMEOUT) {
                [JCAlertView alertWithError:error
                                  dismissed:^(NSInteger buttonIndex) {
                                      [NSException raise:@"RegistrationTimoutException" format:@"The registration attempt timed out."];
                                  }
                          cancelButtonTitle:@"Restart Application"
                          otherButtonTitles:nil];
            }
            
            else if (error.code == JC_SIP_REGISTRATION_FAILURE) {
                [JCAlertView alertWithTitle:@"Registration Failure" error:error];
            }
            
            // If we get a no network error, show an alert.
            else if (error.code == JC_PHONE_WIFI_DISABLED) {
                [JCAlertView alertWithError:error];
            }
            
            // any other alert, we show an error description, except for alreay registering.
            else if (error.code != JC_SIP_ALREADY_REGISTERING) {
                [UIApplication showError:error];
            }
            else {
                NSLog(@"%@", [error description]);
            }
        }
        
        if (completion) {
            completion(success, error);
        }
    };
    
    // Retrive the current network status. Check if the status is Cellular data, and do not connect
    // if we are configured to be wifi only.
    if (self.networkReachabilityManager.isReachableViaWWAN && self.appSettings.isWifiOnly) {
        _networkType = JCPhoneManagerNoNetwork;
        [self notifyCompletionBlock:false error:[JCPhoneManagerError errorWithCode:JC_PHONE_WIFI_DISABLED]];
        [self disconnect];
        return;
    }
    
    // Check to see if we are on an actual network when we try to connect, if we are getting no
    // network, we are not on a network and cannot register, so we notify with error.
    _networkType = (JCPhoneManagerNetworkType)self.networkReachabilityManager.networkReachabilityStatus;
    if (_networkType == JCPhoneManagerNoNetwork) {
        if (!self.sipManager.isActive) {
            [self notifyCompletionBlock:false error:[JCPhoneManagerError errorWithCode:JC_PHONE_MANAGER_NO_NETWORK]];
            [self disconnect];
            return;
        }
    }
    
    // If we have a line configuration for the line, try to register it.
    if (line.lineConfiguration){
        [self registerWithLine:line];
        return;
    }
   
    // If we made it here, we do not have a line configuration, we need to request it. If the
    // request was successfull, we try to register.
    [UIApplication showStatus:@"Selecting Line..."];
    [LineConfiguration downloadLineConfigurationForLine:line completion:^(BOOL success, NSError *error) {
        if (success) {
            [self registerWithLine:line];
        } else {
            [self reportError:[JCPhoneManagerError errorWithCode:JC_PHONE_LINE_CONFIGURATION_REQUEST_ERROR underlyingError:error]];
        }
    }];
}

-(void)registerWithLine:(Line *)line
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCPhoneManagerRegisteringNotification object:self];
    [UIApplication showStatus:@"Registering..."];
    [self.sipManager registerToProvisioning:line];
}

-(void)disconnect
{
    NSLog(@"Phone Disconnect Requested");
    [self.sipManager unregister];
    self.calls = nil;
}

-(void)startKeepAlive
{
    NSLog(@"Starting Keep Alive");
    if (!self.isActiveCall) {
        [self.sipManager startKeepAwake];
    }
}

-(void)stopKeepAlive
{
    NSLog(@"Stopping Keep Alive");
    [self.sipManager stopKeepAwake];
}

#pragma mark SipHandlerDelegate

-(void)sipHandlerDidRegister:(JCSipManager *)sipHandler
{
    NSLog(@"Phone Manager Registration Successfull");
    [UIApplication hideStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCPhoneManagerRegisteredNotification object:self];
    [self notifyCompletionBlock:YES error:nil];
}

-(void)sipHandlerDidUnregister:(JCSipManager *)sipHandler
{
    NSLog(@"Phone Manager Unregistered");
    [UIApplication hideStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCPhoneManagerUnregisteredNotification object:self];
}

-(void)sipHandler:(JCSipManager *)sipHandler didFailToRegisterWithError:(NSError *)error
{
    NSLog(@"Phone Manager Registration failure: %@", error.description);
    if(error.code != JC_SIP_ALREADY_REGISTERING) {
        [UIApplication hideStatus];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCPhoneManagerRegistrationFailureNotification object:self];
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
-(void)dialPhoneNumber:(id<JCPhoneNumberDataSource>)number usingLine:(Line *)line type:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion
{
    NSString *dialString = number.dialableNumber;
    if ([self isEmergencyNumber:dialString] && [UIDevice currentDevice].canMakeCall) {
        [self dialEmergencyNumber:number usingLine:line type:dialType completion:completion];
        return;
    }
    
    [self connectAndDial:number usingLine:line type:dialType completion:completion];
}

-(void)connectAndDial:(id<JCPhoneNumberDataSource>)number usingLine:(Line *)line type:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion
{
    if (self.sipManager.provisioning != line && line != nil) {
        [self disconnect];
    }
    
    if (_sipManager.registered) {
        [self dial:number type:dialType completion:completion];
        return;
    }
    
    [self connectToLine:line
             completion:^(BOOL success, NSError *error) {
                 if (success){
                     [self dial:number type:dialType completion:completion];
                     return;
                 }
                 
                 if (completion) {
                     completion(false, error);
                 }
             }];
}

-(BOOL)isEmergencyNumber:(NSString *)dialString
{
    return [dialString isEqualToString:kJCPhoneManager911String];
}

-(void)dialEmergencyNumber:(id<JCPhoneNumberDataSource>)number usingLine:(Line *)line type:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion
{
    NSString *emergencyNumber = number.dialableNumber;
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
            [weakSelf connectAndDial:number usingLine:line type:dialType completion:completion];
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

-(void)dial:(id<JCPhoneNumberDataSource>)number type:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion
{
    if (dialType == JCPhoneManagerBlindTransfer) {
        [self blindTransferToNumber:number completion:completion];
    } else if (dialType == JCPhoneManagerWarmTransfer) {
        [self warmTransferToNumber:number completion:completion];
    } else {
        [self simpleDialNumber:number completion:completion];
    }
}

-(void)blindTransferToNumber:(id<JCPhoneNumberDataSource>)number completion:(CompletionHandler)completion
{
    [UIApplication showStatus:@"Transfering..."];
    __autoreleasing NSError *error;
    BOOL success = [self.sipManager startBlindTransferToNumber:number error:&error];
    if (completion) {
        if (!success) {
            [UIApplication hideStatus];
            completion(NO, [JCPhoneManagerError errorWithCode:JC_PHONE_BLIND_TRANSFER_FAILED reason:@"Unable to perform transfer at this time. Please Try Again." underlyingError:error]);
        } else {
            completion(YES, nil);
        }
    }
}

-(void)warmTransferToNumber:(id<JCPhoneNumberDataSource>)number completion:(CompletionHandler)completion
{
    _warmTransferNumber = number.dialableNumber;
    __autoreleasing NSError *error;
    BOOL success = [self.sipManager startWarmTransferToNumber:number error:&error];
    if (completion) {
        completion(success, error);
    }
}

-(void)simpleDialNumber:(id<JCPhoneNumberDataSource>)number completion:(CompletionHandler)completion
{
    __autoreleasing NSError *error;
    BOOL success = [self.sipManager makeCall:number videoCall:NO error:&error];
    if (completion) {
        completion(success, error);
    }
}

-(void)finishWarmTransfer:(CompletionHandler)completion
{
    __autoreleasing NSError *error;
    BOOL success = [self.sipManager finishWarmTransfer:&error];
    if (completion) {
        completion(success, error);
    }
}

#pragma mark - Phone Actions -

-(void)answerCall:(JCCallCard *)callCard completion:(CompletionHandler)completion
{
    __autoreleasing NSError *error;
    BOOL success = [self.sipManager answerSession:callCard.lineSession error:&error];
    if (completion) {
        completion(success, error);
    }
}

-(void)hangUpCall:(JCCallCard *)callCard completion:(CompletionHandler)completion;
{
    __autoreleasing NSError *error;
    BOOL success;
    
    if ([callCard isKindOfClass:[JCConferenceCallCard class]]) {
        success = [self.sipManager endConference:&error];
        if(success){
            success = [self.sipManager hangUpAllSessions:&error];
        }
    }
    else {
        success = [self.sipManager hangUpSession:callCard.lineSession error:&error];
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
        success = [self.sipManager holdLines:&error];
    }
    else {
        success = [self.sipManager holdLineSession:callCard.lineSession error:&error];
    }
    
    if (success) {
        callCard.holdStarted = [NSDate date];
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
        success = [self.sipManager unholdLines:&error];
    } else {
        // If we are not in a conference call, all other call should be placed on hold while we are
        // not on hold on a line. When a line is placed on hold, then only it should be placed on
        // hold. If it is returning from hold, all other lines should be placed on hold that are not
        // already on hold.
        for (JCCallCard *card in _calls){
            if (card != callCard){
                [self.sipManager holdLineSession:card.lineSession error:&error];
            }
        }
        success = [self.sipManager unholdLineSession:callCard.lineSession error:&error];
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
    BOOL success = [self.sipManager createConference:&error];
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
    BOOL success = [self.sipManager endConference:&error];
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
    [self.sipManager muteCall:mute];
}

-(void)setLoudSpeakerEnabled:(BOOL)loudSpeakerEnabled
{
    [self.sipManager setLoudSpeakerEnabled:loudSpeakerEnabled];
}

-(void)numberPadPressedWithInteger:(NSInteger)numberPadNumber
{
    [self.sipManager pressNumpadButton:numberPadNumber];
}

-(JCCallerViewController *)createCallerViewController
{
    static NSString *callerViewControllerIdentifier = @"CallerViewController";
    JCCallerViewController *callerViewController = [self.storyboard instantiateViewControllerWithIdentifier:callerViewControllerIdentifier];
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        callerViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        callerViewController.callCardCollectionViewOriginYConstraint.constant = 10;
        [callerViewController.view setNeedsUpdateConstraints];
        [callerViewController.view updateConstraintsIfNeeded];
    }
    return callerViewController;
}

-(void)presentCallViewController
{
    if (_transferConfirmationViewController) {
        [self dismissCallViewControllerAnimated:NO];
    }
    
    _callViewController = [self createCallerViewController];
    _callViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    // If we are an iPad, we are showing it modally, centered on the screen, with 10 px border. We
    // adjust the top margin, and set it to auto size and update constaints before we present it.
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        _callViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    // Present it modal. on the iPhone it will be full screen and on the iPad, it will be centered.
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:_callViewController animated:YES completion:NULL];
}

-(void)dismissCallViewControllerAnimated:(BOOL)animated
{
    [_callViewController dismissViewControllerAnimated:animated completion:^{
        _callViewController = nil;
    }];
}

-(void)presentTransferSuccessWithSession:(JCLineSession *)lineSession receivingSession:(JCLineSession *)receivingSession
{
    _transferConfirmationViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TransferConfirmationViewController"];
    _transferConfirmationViewController.transferLineSession = lineSession;
    _transferConfirmationViewController.receivingLineSession = receivingSession;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:_transferConfirmationViewController animated:YES completion:NULL];
    [self performSelector:@selector(dismissTransferConfirmationViewController) withObject:nil afterDelay:3];
}


- (void)dismissTransferConfirmationViewController
{
    [self dismissTransferConfirmationViewControllerAnimated:YES];
}

- (void)dismissTransferConfirmationViewControllerAnimated:(BOOL)animated
{
    [_transferConfirmationViewController dismissViewControllerAnimated:animated completion:^{
        _transferConfirmationViewController = nil;
    }];
}

#pragma mark SipHandlerDelegate

-(void)sipHandler:(JCSipManager *)sipHandler receivedIntercomLineSession:(JCLineSession *)session
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
            if(self.outputType == JCPhoneAudioManagerOutputReceiver) {
                shouldTurnOnSpeaker = TRUE;
            }
            sipHandler.loudSpeakerEnabled = shouldTurnOnSpeaker;
            BOOL mute = [JCAppSettings sharedSettings].isIntercomMicrophoneMuteEnabled;
            [sipHandler muteCall:mute];
            
            if (_callViewController) {
                _callViewController.muteBtn.selected = sipHandler.isMuted;
            }
        }
    }];
}

-(void)sipHandler:(JCSipManager *)sipManager didAddLineSession:(JCLineSession *)lineSession
{
    if (!lineSession.isIncoming) {
        [OutgoingCall addOutgoingCallWithLineSession:lineSession line:(Line *)sipManager.provisioning];
    }
    
    // If we are backgrounded, push out a local notification
    if ([UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground) {
        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        if (localNotif){
            localNotif.alertBody =[NSString  stringWithFormat:@"Call from %@ :%@", lineSession.number.titleText, lineSession.number.detailText];
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
    
    if(!_callViewController) {
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
            if (lineSession.isIncoming) {
                [self presentCallViewController];
            } else {
                _callViewController = [self createCallerViewController];
                [self postNotificationNamed:kJCPhoneManagerShowCallsNotification];
            }
        } else {
            [self presentCallViewController];
        }
    } else {
        [_callViewController reload];
    }
}

-(void)sipHandler:(JCSipManager *)sipManager didAnswerLineSession:(JCLineSession *)lineSession
{
    [IncomingCall addIncommingCallWithLineSession:lineSession line:(Line *)sipManager.provisioning];
    
    JCCallCard *callCard = [self callCardForLineSession:lineSession];
    callCard.started = [NSDate date];
    
    if (_callViewController) {
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
            [_callViewController dismissViewControllerAnimated:YES completion:^{
                _callViewController = [self createCallerViewController];
                [self postNotificationNamed:kJCPhoneManagerShowCallsNotification];
            }];
        } else {
            [_callViewController reload];
        }
    }
}

-(void)sipHandler:(JCSipManager *)sipHandler willRemoveLineSession:(JCLineSession *)session
{
    // if it was an incoming call, and we missed it, we record it.
    if (session.isIncoming) {
        [MissedCall addMissedCallWithLineSession:session line:(Line *)sipHandler.provisioning];
    }
    
    // Check to see if the line session happens to be a conference call. if it is, we need to end
    // the conference call. This will end the conference call, and it will be removed because it
    // will have been marked as inactive.
    if (session.isConference) {
        __autoreleasing NSError *error;
        [self.sipManager endConference:&error];
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
            if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
                if (session.isIncoming) {
                    [self dismissCallViewControllerAnimated:YES];
                } else {
                    [self postNotificationNamed:kJCPhoneManagerHideCallsNotification];
                    _callViewController = nil;
                }
            } else  {
                [self dismissCallViewControllerAnimated:YES];
            }
        } else {
            [_callViewController reload];
        }
    }
    
    // If when removing the call we are backgrounded, we tell the sip handler to operate in background mode.
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if ((state == UIApplicationStateBackground || state == UIApplicationStateInactive) && count == 0) {
        [self.sipManager startKeepAwake];
    }
}

-(void)sipHandler:(JCSipManager *)sipHandler didCreateConferenceCallWithLineSessions:(NSSet *)lineSessions
{
    // Add the conference call Card
    JCConferenceCallCard *conferenceCallCard = [[JCConferenceCallCard alloc] initWithLineSessions:lineSessions];
    conferenceCallCard.delegate = self;
    conferenceCallCard.started = [NSDate date];
    
    // Blow away the previous call cards on the call array, replacing with the conference call card.
    _calls = [NSMutableArray arrayWithObject:conferenceCallCard];
    
    if (_callViewController) {
        [_callViewController startConferenceCall];
    }
}

-(void)sipHandler:(JCSipManager *)sipHandler didEndConferenceCallForLineSessions:(NSSet *)lineSessions
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

-(void)sipHandler:(JCSipManager *)sipHandler didUpdateStatusForLineSessions:(NSSet *)lineSessions
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

-(void)sipHandler:(JCSipManager *)sipHandler didTransferCalls:(NSSet *)lineSessions
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
    
    [self dismissCallViewControllerAnimated:NO];
    if (transferLine.number && receivingLine.number) {
        [self presentTransferSuccessWithSession:transferLine receivingSession:receivingLine];
    }
}

-(void)sipHandler:(JCSipManager *)sipHandler didFailTransferWithError:(NSError *)error
{
    [_callViewController showError:error];
    [_callViewController reload];
}

-(id<JCPhoneNumberDataSource>)phoneNumberForNumber:(NSString *)number name:(NSString *)name
{
    Line *line = (Line *)self.sipManager.provisioning;
    id<JCPhoneNumberDataSource> phoneNumber = [self.phoneBook phoneNumberForNumber:number name:name forPbx:line.pbx excludingLine:line];
    if (!phoneNumber) {
        phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    }
    return phoneNumber;
}

#pragma mark - Getters -

-(UIStoryboard *)storyboard
{
    if (!_storyboard) {
        _storyboard = [UIStoryboard storyboardWithName:_storyboardName bundle:[NSBundle mainBundle]];
    }
    return _storyboard;
}

-(NSMutableArray *)calls
{
	if (!_calls)
		_calls = [NSMutableArray array];
	return _calls;
}

-(Line *)line
{
    return (Line *)self.sipManager.provisioning;
}

-(BOOL)isInitialized
{
    return self.sipManager.isInitialized;
}

-(BOOL)isRegistered
{
    return self.sipManager.isRegistered;
}

-(BOOL)isActiveCall
{
    return (self.calls.count > 0);
}

-(BOOL)isConferenceCall
{
    return self.sipManager.isConferenceCall;
}

-(BOOL)isMuted
{
    return self.sipManager.isMuted;
}

-(JCPhoneAudioManagerInputType)inputType
{
    return self.sipManager.audioManager.inputType;
}

-(JCPhoneAudioManagerOutputType)outputType
{
    return self.sipManager.audioManager.outputType;
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

-(void)phoneAudioManager:(JCPhoneAudioManager *)manager didChangeAudioRouteInputType:(JCPhoneAudioManagerInputType)inputType
{
    
}

-(void)phoneAudioManager:(JCPhoneAudioManager *)manager didChangeAudioRouteOutputType:(JCPhoneAudioManagerOutputType)outputType
{
    if (_callViewController) {
        _callViewController.speakerBtn.selected = (outputType == JCPhoneAudioManagerOutputSpeaker);
    }
}

@end

@implementation UIViewController (PhoneManager)

- (void)setPhoneManager:(JCPhoneManager *)phoneManager {
    objc_setAssociatedObject(self, @selector(phoneManager), phoneManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(JCPhoneManager *)phoneManager
{
    JCPhoneManager *phoneManager = objc_getAssociatedObject(self, @selector(phoneManager));
    if (!phoneManager)
    {
        phoneManager = [JCPhoneManager sharedManager];
        objc_setAssociatedObject(self, @selector(phoneManager), phoneManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return phoneManager;
}

- (void)dialPhoneNumber:(id<JCPhoneNumberDataSource>)number usingLine:(Line *)line sender:(id)sender
{
    [self dialPhoneNumber:number usingLine:line sender:sender completion:NULL];
}

- (void)dialPhoneNumber:(id<JCPhoneNumberDataSource>)number usingLine:(Line *)line sender:(id)sender completion:(CompletionHandler)completion
{
    if([sender isKindOfClass:[UIButton class]]) {
        ((UIButton *)sender).enabled = FALSE;
    } else if ([sender isKindOfClass:[UITableView class]]) {
        ((UITableView *)sender).userInteractionEnabled = FALSE;
    }
    
    [self.phoneManager dialPhoneNumber:number
                        usingLine:line
                             type:JCPhoneManagerSingleDial
                       completion:^(BOOL success, NSError *error) {
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
