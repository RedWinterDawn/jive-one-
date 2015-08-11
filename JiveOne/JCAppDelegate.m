//
//  JCAppDelegate.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAppDelegate.h"
#import <AFNetworkActivityLogger/AFNetworkActivityLogger.h>

#import "AFNetworkActivityIndicatorManager.h"
#import "JCLoginViewController.h"
#import "Common.h"
#import "TRVSMonitor.h"
#import "JCVersion.h"
#import "LoggerClient.h"
#import "JCLinePickerViewController.h"

#import "JCPhoneManager.h"
#import "JCPresenceManager.h"
#import "JCVoicemailManager.h"
#import "JCSMSMessageManager.h"
#import "LineConfiguration+V4Client.h"

#import "JCBadgeManager.h"
#import "JCApplicationSwitcherDelegate.h"
#import "JCV5ApiClient.h"
#import "JCSocket.h"
#import "JCSocketLogger.h"
#import "UIDevice+Additions.h"
#import <Appsee/Appsee.h>
#import "JCPhoneBook.h"

#import "PBX.h"
#import "Line.h"
#import "User.h"
#import "OutgoingCall.h"
#import "IncomingCall.h"
#import "MissedCall.h"

#import "InternalExtension+V5Client.h"
#import "Voicemail+V5Client.h"
#import "SMSMessage+V5Client.h"
#import "BlockedNumber+V5Client.h"
#import "JCUnknownNumber.h"
#import "JCMessageGroup.h"

#import  "JCAppSettings.h"

#import <Google/CloudMessaging.h>

#define SHARED_CACHE_CAPACITY 2 * 1024 * 1024
#define DISK_CACHE_CAPACITY 100 * 1024 * 1024

NSString *const kApplicationDidReceiveRemoteNotification = @"ApplicationDidReceiveRemoteNotification";
NSString *const kGCMSenderId = @"937754980938";

@interface JCAppDelegate () <JCPickerViewControllerDelegate, JCPhoneManagerDelegate>
{
    UINavigationController *_navigationController;
    UIViewController *_appSwitcherViewController;
    BOOL _connectedToGCM;
}

@end

@implementation JCAppDelegate

#pragma mark Login Workflow

/**
 * Presents the User Login form.
 *
 * Creates a navigation controller and places the login view controller as its root view controller. It is then switched
 * in as the root view controller, with the app switcher being stored in a local variable. The login view is presented 
 * with a flip a animation.
 */
-(void)presentLoginViewController:(BOOL)animated
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:[NSBundle mainBundle]];
    UIViewController *loginViewController = [storyboard instantiateInitialViewController];
        
    _navigationController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    [_navigationController setNavigationBarHidden:TRUE];
        
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"login-background"]];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    imageView.frame = _navigationController.view.bounds;
    [_navigationController.view addSubview:imageView];
    [_navigationController.view sendSubviewToBack:imageView];
        
    [UIView transitionWithView:self.window
                      duration:animated? 0.5 : 0
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        self.window.rootViewController = _navigationController;
                    }
                    completion:nil];
}


/**
 * Present the Line Configuration View Controller
 *
 * Pushes the line configuration view controller onto the navigation controller instancing it from the storyboard. 
 * Registers us as the delegate to respond the transitioning to the next step
 */
-(void)presentLineConfigurationViewController:(BOOL)animated
{
    if (!_navigationController) {
        return;
    }
    
    JCLinePickerViewController *linePickerViewController;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:[NSBundle mainBundle]];
    linePickerViewController = (JCLinePickerViewController *)[storyboard instantiateViewControllerWithIdentifier:@"LinePickerViewController"];
    linePickerViewController.delegate = self;
    [_navigationController pushViewController:linePickerViewController animated:animated];
}

/**
 * Removes the nagivation controller for the login and app configuration/tutorial, and replaces it as the root view 
 * controller with the app delegate.
 */
-(void)dismissLoginViewController:(BOOL)animated completed:(void (^)(BOOL finished))completed
{
    [UIView transitionWithView:self.window
                      duration:animated? 0.5 : 0
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        self.window.rootViewController = _appSwitcherViewController;
                    }
                    completion:^(BOOL finished) {
                        if (completed != NULL) {
                            completed(finished);
                        }
                        _navigationController = nil;
                    }];
}

- (UIBackgroundFetchResult)backgroundPerformFetchWithCompletionHandler
{
    LOG_Info();
    // If we are not a V5 PBX, we do not have a voicemail data to go fetch, and return with a no data callback.
    if (![UIApplication sharedApplication].authenticationManager.line.pbx.isV5)
        return UIBackgroundFetchResultNoData;
    
    NSLog(@"APPDELEGATE - performFetchWithCompletionHandler");
    __block UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultFailed;
    return fetchResult;
}

-(void)registerServicesToLine:(Line *)line
{
    [JCBadgeManager setSelectedLine:line.jrn];
    [JCBadgeManager setSelectedPBX:line.pbx.pbxId];
        
    // Get Contacts. Once we have contacts, we subscribe to their presence, fetch voicemails trying
    // to link contacts to thier voicemail if in the pbx. Only fetch voicmails, and open sockets for
    // v5 pbxs. If we are on v4, we disconnect, and do not fetch voicemails.
    [InternalExtension downloadInternalExtensionsForLine:line complete:^(BOOL success, NSError *error) {
        
        // Fetch Voicemails (feature flagged only for v5 clients). Since we try to link the
        // voicemails to thier contacts, we try to download/update the contacts list first, then
        // request voicemails.
        [Voicemail downloadVoicemailsForLine:line completion:NULL];
        
        // Connect to Jasmine
        [self subscribeToJasmineEventsForLine:line];
    }];

	// Download all SMS Messages is sms is enabled for the pbx.
    if ([line.pbx smsEnabled]) {
        NSSet *dids = line.pbx.dids;
        [SMSMessage downloadMessagesForDIDs:dids completion:NULL];
        [BlockedNumber downloadBlockedForDIDs:dids completion:NULL];
    }
    
    // Register the Phone.
    JCPhoneManager *phoneManager = [JCPhoneManager sharedManager];
    [phoneManager connectWithProvisioningProfile:line];
}

-(void)subscribeToJasmineEventsForLine:(Line *)line
{
    JCSocket *jasmineSocket = [JCSocket sharedSocket];
    
    // Check to see if we have a jasmine socket. If we do, unsubscribe, and resubscribe to events
    if(jasmineSocket.isReady) {
        [JCSocketManager unsubscribe:^(BOOL success, NSError *error) {
            if (!success) {
                [jasmineSocket connectWithCompletion:^(BOOL success, NSError *error) {
                    if (success) {
                        [self subscribeToLineEvents:line];
                    }
                }];
            } else {
                [self subscribeToLineEvents:line];
            }
        }];
    }
    
    // If we do not have a socket, connect.
    else {
        [jasmineSocket connectWithCompletion:^(BOOL success, NSError *error) {
            if (success) {
                [self subscribeToLineEvents:line];
            }
        }];
    }
}

-(void)subscribeToLineEvents:(Line *)line
{
    [JCPresenceManager generateSubscriptionForPbx:line.pbx];
    [JCVoicemailManager generateSubscriptionForLine:line];
//    [JCSMSMessageManager generateSubscriptionForPbx:line.pbx];
    
    [JCSocketManager subscribe];
}

#pragma mark - Notification Handlers -

#pragma mark AFNetworkReachability

-(void)networkConnectivityChanged:(NSNotification *)notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(networkConnectivityChanged:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    AFNetworkReachabilityStatus status = (AFNetworkReachabilityStatus)((NSNumber *)[notification.userInfo valueForKey:AFNetworkingReachabilityNotificationStatusItem]).integerValue;
    AFNetworkReachabilityManager *networkManager = [AFNetworkReachabilityManager sharedManager];
    Line *line = [UIApplication sharedApplication].authenticationManager.line;
    if (!line) {
        return;
    }
    
    // Check to see if we have a previous network state that was different from our current network
    // state. If they are the same, we have no reason to change the state change, so we exit out.
    JCPhoneManagerNetworkType currentNetworkType = [[JCPhoneManager sharedManager] networkType];
    if (currentNetworkType == status) {
        return;
    }
    
    // If we have become unreachable, we note it, but we do not disconnect, in case its a temporary
    // outage, and we are able to reconnect. Its possible we may loose network connectivity, but we
    // may recover, or transition to anouther state, so we choose not to act on the change, but
    // rather the recovery when we reconnect.
    if (status == AFNetworkReachabilityStatusNotReachable) {
        NSLog(@"No Network Connection");
        [[JCPhoneManager sharedManager] connectWithProvisioningProfile:line];
    }
    
    // Transition from Cellular data to wifi.
    else if (currentNetworkType ==  JCPhoneManagerCellularNetwork && status == AFNetworkReachabilityStatusReachableViaWiFi) {
        NSLog(@"Transitioning to Wifi from Cellular Data Connection");
        [[JCPhoneManager sharedManager] connectWithProvisioningProfile:line];
    }
    
    // Transition from wifi to cellular data.
    else if (currentNetworkType == JCPhoneManagerWifiNetwork && status == AFNetworkReachabilityStatusReachableViaWWAN) {
        NSLog(@"Transitioning to Cellular Data from Wifi Connection");
        [[JCPhoneManager sharedManager] connectWithProvisioningProfile:line];
    }
    
    // Transition from no connection to having a connection.
    else if(currentNetworkType == JCPhoneManagerNoNetwork && status != AFNetworkReachabilityStatusNotReachable) {
        NSLog(@"Transitioning from no network connectivity to connected.");
        [[JCPhoneManager sharedManager] connectWithProvisioningProfile:line];
    }
    
    // Transition from unknown network to other wifi or cellular data
    else if (currentNetworkType == JCPhoneManagerUnknownNetwork &&
             (status == AFNetworkReachabilityStatusReachableViaWiFi || status == AFNetworkReachabilityStatusReachableViaWWAN)) {
        NSLog(@"Transitioning from unknown network to wifi or wwan");
        [[JCPhoneManager sharedManager] connectWithProvisioningProfile:line];
    }
    
    // Handle socket to reconnect. Since we reuse the socket, we do not need to subscribe, but just
    // activate the socket to reopen it. We only want to try to connect if we do not have a device token.
//    NSString *deviceToken = [JCAuthenticationManager sharedInstance].deviceToken;
//    if (deviceToken && networkManager.isReachable && ![JCSocket sharedSocket].isReady) {            //@Rob what are we suppose to do if we dont have connection or the socket is not ready. Do we ever check again and try to connect.
//        [JCSocket connectWithDeviceToken:deviceToken completion:NULL];
//    }
    
}

#pragma mark JCAuthenticationManager

/**
 * Notification of user authentications and loading of minimum required data has occured.
 */
-(void)userDataReady:(NSNotification *)notification
{
    // If navigation controller is not null, the login page is still present, and needs to either be
    // dismissed or should transition to requesting that they select a line.
    JCAuthenticationManager *authenticationManager = notification.object;
    Line *line = authenticationManager.line;
    if (!line) {
        [JCAlertView alertWithTitle:NSLocalizedString(@"Warning", nil)
                            message:NSLocalizedString(@"Unable to select line. Please call Customer Care. You may not have a device associated with this account.", nil)];
        return;
    }
    
    if (!_navigationController){
        [self registerServicesToLine:line];
        return;
    }
    
    // If the user has multiple line configurations, we prompt them to select which line they
    // would like to connect with. When selected, the authentication manager will notify that
    // they have changed their selected line.
    NSInteger lines = [Line MR_countOfEntities];
    if (lines > 1 && !line.active) {
        [self presentLineConfigurationViewController:YES];
        return;
    }
        
    [self dismissLoginViewController:YES completed:^(BOOL finished) {
        [self registerServicesToLine:line];
    }];
}

/**
 * Notification when the line has changes.
 *
 * When it changes we need to make the phone manager reconnect with new credentials.
 */
-(void)lineChanged:(NSNotification *)notification
{
    JCAuthenticationManager *authenticationManager = notification.object;
    [self registerServicesToLine:authenticationManager.line];
}

-(void)userRequiresAuthentication:(NSNotification *)notification
{
    [JCBadgeManager reset];                             // Resets the Badge Manager.
    [self presentLoginViewController:YES];              // Present the login view.
}

-(void)userWillLogout:(NSNotification *)notification
{
    // Disconnect the socket and purge socket session.
    [JCSocket unsubscribeToSocketEvents:^(BOOL success, NSError *error) {
        [JCSocket reset];
    }];
    
    JCPhoneManager *phoneManager = [JCPhoneManager sharedManager];
    if(phoneManager.isRegistered) {
        [phoneManager disconnect];
    }
    
    [JCApiClient cancelAllOperations];
}

/**
 * Notification of user inititated logout.
 */
-(void)userDidLogout:(NSNotification *)notification
{
    [self userRequiresAuthentication:notification];
}

-(void)presenceChanged:(NSNotification *)notification
{
    [self subscribeToJasmineEventsForLine:[UIApplication sharedApplication].authenticationManager.line];
}

#pragma mark - Delegate Handlers -

-(void)pickerViewControllerShouldDismiss:(JCPickerViewController *)controller
{
    [self dismissLoginViewController:YES completed:NULL];
}

-(void)phoneManager:(JCPhoneManager *)manager reportCallOfType:(JCPhoneManagerCallType)type lineSession:(JCPhoneSipSession *)lineSession provisioningProfile:(id<JCPhoneProvisioningDataSource>)provisioningProfile
{
    if (!lineSession || !provisioningProfile || ![provisioningProfile isKindOfClass:[Line class]]) {
        return;
    }
    
    switch (type) {
        case JCPhoneManagerIncomingCall:
            [IncomingCall addIncommingCallWithLineSession:lineSession line:(Line *)provisioningProfile];
            break;
            
        case JCPhoneManagerMissedCall:
            [MissedCall addMissedCallWithLineSession:lineSession line:(Line *)provisioningProfile];
            break;
            
        case JCPhoneManagerOutgoingCall:
            [OutgoingCall addOutgoingCallWithLineSession:lineSession line:(Line *)provisioningProfile];
            break;
    }
}

-(id<JCPhoneNumberDataSource>)phoneManager:(JCPhoneManager *)manager phoneNumberForNumber:(NSString *)number name:(NSString *)name provisioning:(id<JCPhoneProvisioningDataSource>)provisioning {
    
    Line *line = (Line *)provisioning;
    JCPhoneBook *phoneBook = [JCPhoneBook sharedPhoneBook];
    id<JCPhoneNumberDataSource> phoneNumber = [phoneBook phoneNumberForNumber:number name:name forPbx:line.pbx excludingLine:line];
    if (!phoneNumber) {
        phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    }
    return phoneNumber;
}

-(void)phoneManager:(JCPhoneManager *)phoneManger phoneNumbersForKeyword:(NSString *)keyword provisioning:(id<JCPhoneNumberDataSource>)provisioning completion:(void (^)(NSArray *))completion {
    
    Line *line = (Line *)provisioning;
    JCPhoneBook *phoneBook = [JCPhoneBook sharedPhoneBook];
    [phoneBook phoneNumbersWithKeyword:keyword
                               forUser:line.pbx.user
                               forLine:line
                           sortedByKey:NSStringFromSelector(@selector(name))
                             ascending:YES
                            completion:completion];
    
}

-(id<JCPhoneNumberDataSource>)phoneManager:(JCPhoneManager *)phoneManager lastCalledNumberForProvisioning:(id<JCPhoneProvisioningDataSource>)provisioning {
    Line *line = (Line *)provisioning;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"line = %@", line];
    return [OutgoingCall MR_findFirstWithPredicate:predicate sortedBy:@"date" ascending:false inContext:line.managedObjectContext];
}

-(void)phoneManager:(JCPhoneManager *)phoneManager provisioning:(id<JCPhoneProvisioningDataSource>)provisioning didReceiveUpdatedVoicemailCount:(NSUInteger)count
{
    [JCBadgeManager setVoicemails:count];
}

#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Appsee start:@"a57e92aea6e541529dc5227171341113"];
    
//    [Parse setApplicationId:@"bQTDjU0QtxWVpNQp2yJp7d9ycntVZdCXF5QrVH8q"
//                  clientKey:@"ec135dl8Xfu4VAUXz0ub6vt3QqYnQEur2VcMH1Yf"];
    //GCM Push notifications
//    UIUserNotificationType allNotificationTypes = (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
//    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
//    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
//    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    //Register for background fetches
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    _appSwitcherViewController = self.window.rootViewController;
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    //Create a sharedCache for AFNetworking
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:SHARED_CACHE_CAPACITY diskCapacity:DISK_CACHE_CAPACITY diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];

    
    // We predominately use the AFNetworking Networking stack to handle data request between the
    // App and Jive Servers for data requests. Here we configure caching, logging and monitoring
    // indication for AFNetoworking.
    
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
#if DEBUG
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
    [[AFNetworkActivityLogger sharedLogger] startLogging];
#else
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelOff];
#endif
    
    // Start monitor for Reachability. We use the reachability manager to notify to network changes
    // and to take appropriate actions with our network changes.
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [center addObserver:self selector:@selector(networkConnectivityChanged:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
    [manager startMonitoring];
    
    // Loads a default set of defaults into NSUserDefaults to be used on first load. If a default is
    // not set by code, it is read from the default set. If the default then becomes set, it
    // overrides the default.
    
    NSString *defaultPrefsFile = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
    NSDictionary *defaultPreferences = [NSDictionary dictionaryWithContentsOfFile:defaultPrefsFile];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];
    
    // Load Core Data. Currently we are not concerned aobut persisting data long term, so if there
    // is any core data conflict, we would rather delete the whole .sqlite file and rebuild it, than
    // to merge.
    [MagicalRecord setShouldDeleteStoreOnModelMismatch:YES];
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:kCoreDataDatabase];
    
    // Badging
    [JCBadgeManager updateBadgesFromContext:[NSManagedObjectContext MR_defaultContext]];
    
    JCAppSettings *appSettings = [JCAppSettings sharedSettings];
    [center addObserver:self selector:@selector(presenceChanged:) name:kJCAppSettingsPresenceChangedNotification object:appSettings];
    
    JCPhoneManager *phoneManager = [JCPhoneManager sharedManager];
    [phoneManager.settings loadDefaultsFromFile:@"UserDefaults.plist"];
    phoneManager.delegate = self;

    // Authentication
    JCAuthenticationManager *authenticationManager = application.authenticationManager;
    [center addObserver:self selector:@selector(userRequiresAuthentication:) name:kJCAuthenticationManagerUserRequiresAuthenticationNotification object:authenticationManager];
    [center addObserver:self selector:@selector(userWillLogout:) name:kJCAuthenticationManagerUserWillLogOutNotification object:authenticationManager];
    [center addObserver:self selector:@selector(userDidLogout:) name:kJCAuthenticationManagerUserLoggedOutNotification object:authenticationManager];
    [center addObserver:self selector:@selector(userDataReady:) name:kJCAuthenticationManagerUserLoadedMinimumDataNotification object:authenticationManager];
    [center addObserver:self selector:@selector(lineChanged:) name:kJCAuthenticationManagerLineChangedNotification object:authenticationManager];
    [authenticationManager checkAuthenticationStatus];
    
    [self handlePush:launchOptions];
    
    return YES;
}

/**
 * Sent when the application is about to move from active to inactive state. This can occur for certain types of 
 * temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it
 * begins the transition to the background state. Use this method to pause ongoing tasks, disable timers, and throttle 
 * down OpenGL ES frame rates. Games should use this method to pause the game.
 */
- (void)applicationWillResignActive:(UIApplication *)application
{
    LOG_Info();
}

/**
 * Use this method to release shared resources, save user data, invalidate timers, and store enough application state 
 * information to restore your application to its current state in case it is terminated later. If your application 
 * supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
 */
-(void)applicationDidEnterBackground:(UIApplication *)application
{
    LOG_Info();
    [JCSocket restart];                 // in case the socket stopped, we restart it.
    [[JCPhoneManager sharedManager] startKeepAlive];
}

/**
 * Called as part of the transition from the background to the inactive state; here you can undo many of the changes 
 * made on entering the background.
 */
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    LOG_Info();
    [JCSocket restart]; // In case the socket stopped, we restart it.
    [[JCPhoneManager sharedManager] stopKeepAlive];
}

/**
 * Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was 
 * previously in the background, optionally refresh the user interface.
 */
- (void)applicationDidBecomeActive:(UIApplication *)application
{
        // Connect to the GCM server to receive non-APNS notifications
        [[GCMService sharedInstance] connectWithHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Could not connect to GCM: %@", error.localizedDescription);
            } else {
                _connectedToGCM = true;
                NSLog(@"Connected to GCM");
                // ...
            }
        }];
    LOG_Info();
}

/**
 * Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
 */
- (void)applicationWillTerminate:(UIApplication *)application
{
    LOG_Info();
    [MagicalRecord cleanUp];
}

#pragma mark Notifications Handling

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    
}

/**
 * Called when we receive a device APN token. 
 *
 * If we are running in the simulator, the Badge Manager who is registering for the notifications, 
 * will call the didFailToRegisterForRemoteNotifications, which in turn will call this method 
 * passing a nil value for the deviceTokenData
 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceTokenData
{
    if (!deviceTokenData) {
        deviceTokenData = [[UIDevice currentDevice].installationIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    // Register the Device Token to the GCM service.
    GGLInstanceID *instance = [GGLInstanceID sharedInstance];
    [instance startWithConfig:[GGLInstanceIDConfig defaultConfig]];
    NSDictionary *options = @{kGGLInstanceIDRegisterAPNSOption: deviceTokenData,
                              kGGLInstanceIDAPNSServerTypeSandboxOption: @"YES"};
    
    [instance tokenWithAuthorizedEntity:kGCMSenderId
                                  scope:kGGLInstanceIDScopeGCM
                                options:options
                                handler:^(NSString *token, NSError *error) {
                                    [JCSocket setDeviceToken:token];
                                }];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    [self application:application didRegisterForRemoteNotificationsWithDeviceToken:nil];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [[GCMService sharedInstance] appDidReceiveMessage:userInfo];
    
//    NSString *fromNumber = [userInfo objectForKey:@"fromNumber"];
//    NSString *didId = [userInfo objectForKey:@"didId"];
//    NSString *uid = [userInfo objectForKey:@"uid"];
//    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
//    DID *did = [DID MR_findFirstByAttribute:NSStringFromSelector(@selector(didId)) withValue:didId inContext:context];
//    if (did) {
//        
//        JCSMSConversationGroup *conversationGroup = [[JCSMSConversationGroup alloc] initWithName:nil number:fromNumber];
//        [SMSMessage downloadMessagesForDID:did toConversationGroup:conversationGroup completion:^(BOOL success, NSError *error) {
//            if (success) {
//                if ([UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground) {
//                    SMSMessage *message = [SMSMessage MR_findFirstByAttribute:NSStringFromSelector(@selector(eventId)) withValue:uid inContext:context];
//                    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
//                    if (localNotif){
//                        localNotif.alertBody =[NSString  stringWithFormat:NSLocalizedString(@"New Message from %@ \n%@", nil), fromNumber.numericStringValue, message.text ];
//                        localNotif.soundName = UILocalNotificationDefaultSoundName;
//                        localNotif.applicationIconBadgeNumber = 1;
//                        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
//                    }
//                } else {
//                    // TODO: Sound an meesage received event.
//                }
//            }
//        }];
//    }
    
    completionHandler([self backgroundPerformFetchWithCompletionHandler]);
}

-(void)handlePush:(NSDictionary *)launchOptions {
    NSDictionary *remoteNotificationPayload = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if(remoteNotificationPayload){
        [[NSNotificationCenter defaultCenter] postNotificationName:kApplicationDidReceiveRemoteNotification object:nil userInfo:remoteNotificationPayload];
        [SMSMessage createSmsMessageWithMessageData:launchOptions];
    NSString *fromEntity = [remoteNotificationPayload objectForKey:@"fromNumber"];
    NSString *messageBody = [remoteNotificationPayload objectForKey:@"alert"];
        NSLog(@"New Message from %@ , \n %@", fromEntity, messageBody);
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    completionHandler([self backgroundPerformFetchWithCompletionHandler]);
}

- (void)receivedForegroundNotification:(NSDictionary *)notification fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    completionHandler([self backgroundPerformFetchWithCompletionHandler]);
}

- (void)receivedBackgroundNotification:(NSDictionary *)notification fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    completionHandler([self backgroundPerformFetchWithCompletionHandler]);
}

@end
