//
//  JCAppDelegate.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAppDelegate.h"
#import <AFNetworkActivityLogger/AFNetworkActivityLogger.h>

#import <Parse/Parse.h>
#import "AFNetworkActivityIndicatorManager.h"
#import "JCLoginViewController.h"
#import "Common.h"
#import "TRVSMonitor.h"
#import "JCVersion.h"
#import "LoggerClient.h"
#import "JCLinePickerViewController.h"
#import <Crashlytics/Crashlytics.h>

#import "JCPhoneManager.h"
#import "JCPresenceManager.h"
#import "JCVoicemailManager.h"
#import "JCSMSMessageManager.h"

#import "JCBadgeManager.h"
#import "JCApplicationSwitcherDelegate.h"
#import "JCV5ApiClient.h"
#import "JCSocket.h"
#import "JCSocketLogger.h"
#import "UIDevice+Additions.h"


#import "PBX.h"
#import "Line.h"
#import "User.h"

#import "Contact+V5Client.h"
#import "Voicemail+V5Client.h"
#import "SMSMessage+V5Client.h"
#import "JCUnknownNumber.h"

#import  "JCAppSettings.h"

#define SHARED_CACHE_CAPACITY 2 * 1024 * 1024
#define DISK_CACHE_CAPACITY 100 * 1024 * 1024

@interface JCAppDelegate () <JCPickerViewControllerDelegate>
{
    UINavigationController *_navigationController;
    UIViewController *_appSwitcherViewController;
}

@end

@implementation JCAppDelegate

NSString *const kPAPInstallationChannelsKey = @"channels";
NSString *const kApplicationDidReceiveRemoteNotification = @"ApplicationDidReciveRemoteNotification";

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
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
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
    else
    {
        UIViewController *loginViewController = [_appSwitcherViewController.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
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
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:[NSBundle mainBundle]];
        linePickerViewController = (JCLinePickerViewController *)[storyboard instantiateViewControllerWithIdentifier:@"LinePickerViewController"];
    }
    else {
        linePickerViewController = (JCLinePickerViewController *)[_appSwitcherViewController.storyboard instantiateViewControllerWithIdentifier:@"LinePickerViewController"];
    }
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
    if (![JCAuthenticationManager sharedInstance].line.pbx.isV5)
        return UIBackgroundFetchResultNoData;
    
    NSLog(@"APPDELEGATE - performFetchWithCompletionHandler");
    __block UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultFailed;
//    if ([JasmineSocket sharedInstance].socket.readyState != SR_OPEN)
//    {
//        @try {
//            TRVSMonitor *monitor = [TRVSMonitor monitor];
//            JCBadgeManager *badgeManger = [JCBadgeManager sharedManager];
//            [badgeManger startBackgroundUpdates];
//            
//            Line *line = [JCAuthenticationManager sharedInstance].line;
//            [Voicemail downloadVoicemailsForLine:line complete:^(BOOL suceeded, NSError *error) {
//                [monitor signal];
//            }];
//            
//            // No Socket for now.
//            //            [[JCSocketDispatch sharedInstance] startPoolingFromSocketWithCompletion:^(BOOL success, NSError *error) {
//            //                if (success) {
//            //                    NSLog(@"Success Done with Block");
//            //                    LogMessage(@"socket", 4, @"Success pooling from socket");
//            //                }
//            //                else {
//            //                    NSLog(@"Error Done With Block %@", error);
//            //                    LogMessage(@"socket", 4, @"Error pooling from socket");
//            //
//            //                }
//            //                [monitor signal];
//            //            }];
//            
//            [monitor waitWithTimeout:25];
//            NSUInteger badgeUpdateEvents = [badgeManger endBackgroundUpdates];
//            if (badgeUpdateEvents != 0) {
//                fetchResult = UIBackgroundFetchResultNewData;
//            }
//            else {
//                fetchResult = UIBackgroundFetchResultNoData;
//            }
//        }
//        @catch (NSException *exception) {
//            NSLog(@"%@", exception);
//        }
//        @finally {
//            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground ) {
//                if ([JasmineSocket sharedInstance].socket.readyState == SR_OPEN) {
//                    LogMessage(@"socket", 4, @"Will Call closeSocket");
//                    
//                    [JasmineSocket stopSocket];
//                }
//            }
//            
//        }
//    }
    
    return fetchResult;
}

-(void)registerServicesToLine:(Line *)line deviceToken:(NSString *)deviceToken
{
    [JCBadgeManager setSelectedLine:line.jrn];
    [JCBadgeManager setSelectedPBX:line.pbx.pbxId];
        
    // Get Contacts. Once we have contacts, we subscribe to their presence, fetch voicemails trying
    // to link contacts to thier voicemail if in the pbx. Only fetch voicmails, and open sockets for
    // v5 pbxs. If we are on v4, we disconnect, and do not fetch voicemails.
    [Contact downloadContactsForLine:line complete:^(BOOL success, NSError *error) {
        
        // Fetch Voicemails (feature flagged only for v5 clients). Since we try to link the
        // voicemails to thier contacts, we try to download/update the contacts list first, then
        // request voicemails.
        [Voicemail downloadVoicemailsForLine:line completion:NULL];
        
        // If the socket is open already, clear and register for jasmine events for our current line
        if ([JCSocket sharedSocket].isReady) {
            [self resubscribeToLineEvents:line];
        }
    }];

	// Download all SMS Messages is sms is enabled for the pbx.
    if ([line.pbx smsEnabled]) {
        [SMSMessage downloadMessagesForDIDs:line.pbx.dids completion:NULL];
    }
    
    // Register the Phone.
    JCPhoneManager *phoneManager = [JCPhoneManager sharedManager];
    [phoneManager connectToLine:line];
}

-(void)resubscribeToLineEvents:(Line *)line
{
    JCAuthenticationManager *authenticationManager = [JCAuthenticationManager sharedInstance];
    NSString *deviceToken = authenticationManager.deviceToken;
    if (!deviceToken) {
        return;
    }
    
    [JCSocket unsubscribeToSocketEvents:^(BOOL success, NSError *error) {
        if (!success) {
            [JCSocket connectWithDeviceToken:deviceToken completion:^(BOOL success, NSError *error) {
                if (success) {
                    [self subscribeToLineEvents:line];
                }
            }];
        } else {
            [self subscribeToLineEvents:line];
        }
    }];
}

-(void)subscribeToLineEvents:(Line *)line
{
    [JCPresenceManager subscribeToPbx:line.pbx];
	[JCVoicemailManager subscribeToLine:line];
    [JCSMSMessageManager subscribeToPbx:line.pbx];
}

#pragma mark - Notification Handlers -

#pragma mark JCSocket

-(void)socketConnectedSelector:(NSNotification *)notification
{
    [self resubscribeToLineEvents:[JCAuthenticationManager sharedInstance].line];
}

-(void)socketFailedConnectionSelector:(NSNotification *)notification
{
    [self resubscribeToLineEvents:[JCAuthenticationManager sharedInstance].line];
}

#pragma mark AFNetworkReachability

-(void)networkConnectivityChanged:(NSNotification *)notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(networkConnectivityChanged:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    AFNetworkReachabilityStatus status = (AFNetworkReachabilityStatus)((NSNumber *)[notification.userInfo valueForKey:AFNetworkingReachabilityNotificationStatusItem]).integerValue;
    AFNetworkReachabilityManager *networkManager = [AFNetworkReachabilityManager sharedManager];
    Line *line = [JCAuthenticationManager sharedInstance].line;
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
        [[JCPhoneManager sharedManager] connectToLine:line];
    }
    
    // Transition from Cellular data to wifi.
    else if (currentNetworkType ==  JCPhoneManagerCellularNetwork && status == AFNetworkReachabilityStatusReachableViaWiFi) {
        NSLog(@"Transitioning to Wifi from Cellular Data Connection");
        [[JCPhoneManager sharedManager] connectToLine:line];
    }
    
    // Transition from wifi to cellular data.
    else if (currentNetworkType == JCPhoneManagerWifiNetwork && status == AFNetworkReachabilityStatusReachableViaWWAN) {
        NSLog(@"Transitioning to Cellular Data from Wifi Connection");
        [[JCPhoneManager sharedManager] connectToLine:line];
    }
    
    // Transition from no connection to having a connection.
    else if(currentNetworkType == JCPhoneManagerNoNetwork && status != AFNetworkReachabilityStatusNotReachable) {
        NSLog(@"Transitioning from no network connectivity to connected.");
        [[JCPhoneManager sharedManager] connectToLine:line];
    }
    
    // Handle socket to reconnect. Since we reuse the socket, we do not need to subscribe, but just
    // activate the socket to reopen it. We only want to try to connect if we do not have a device token.
    NSString *deviceToken = [JCAuthenticationManager sharedInstance].deviceToken;
    if (deviceToken && networkManager.isReachable && ![JCSocket sharedSocket].isReady) {
        [JCSocket connectWithDeviceToken:deviceToken completion:NULL];
    }
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
        [JCAlertView alertWithTitle:@"Warning" message:@"Unable to select line. Please call Customer Care. You may not have a device associated with this account."];
        return;
    }
    
    NSString *deviceToken = authenticationManager.deviceToken;
    if (!_navigationController){
        [self registerServicesToLine:line deviceToken:deviceToken];
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
        [self registerServicesToLine:line deviceToken:deviceToken];
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
    [self registerServicesToLine:authenticationManager.line deviceToken:authenticationManager.deviceToken];
}

/**
 * Notification of user inititated logout.
 */
-(void)userDidLogout:(NSNotification *)notification
{
    [JCSocket unsubscribeToSocketEvents:NULL];          // Disconnect the socket and purge socket session.
    [[JCPhoneManager sharedManager] disconnect];                        // Disconnect the phone manager
    [JCApiClient cancelAllOperations];                     // Kill any pending client network operations.
    [JCBadgeManager reset];                             // Resets the Badge Manager.
    [self presentLoginViewController:YES];              // Present the login view.
}

#pragma mark - Delegate Handlers -

-(void)pickerViewControllerShouldDismiss:(JCPickerViewController *)controller
{
    [self dismissLoginViewController:YES completed:NULL];
}

#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    [Crashlytics startWithAPIKey:@"dd3685563712dc20cfb83957dedcfbe78fbb2be4"];
    
    
    [Parse setApplicationId:@"bQTDjU0QtxWVpNQp2yJp7d9ycntVZdCXF5QrVH8q"
                  clientKey:@"ec135dl8Xfu4VAUXz0ub6vt3QqYnQEur2VcMH1Yf"];
    
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

	// Jasmine
    JCSocket *socket = [JCSocket sharedSocket];
    [center addObserver:self selector:@selector(socketConnectedSelector:) name:kJCSocketConnectedNotification object:socket];
    [center addObserver:self selector:@selector(socketFailedConnectionSelector:) name:kJCSocketConnectFailedNotification object:socket];
    
    
    // Authentication
    
    JCAuthenticationManager *authenticationManager = [JCAuthenticationManager sharedInstance];
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

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceTokenData
{
    if (deviceTokenData)
    {
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        [currentInstallation setDeviceTokenFromData:deviceTokenData];
        [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                NSLog(@"Saved Current installation");
            } else {
                NSLog(@"error in currentInstilation %@", error);
            }
        }];
        
        [PFPush subscribeToChannelInBackground:@"" block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"Jive_One successfully subscribed to push notifications on the broadcast channel.");
            } else {
                NSLog(@"Jive_One failed to subscribe to push notifications on the broadcast channel.");
            }
        }];
    } else {
        deviceTokenData = [[UIDevice currentDevice].installationIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    JCAuthenticationManager *authenticationManager = [JCAuthenticationManager sharedInstance];
    NSString *oldDeviceToken = authenticationManager.deviceToken;
    NSString *deviceToken = [[deviceTokenData.description stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (![oldDeviceToken isEqualToString:deviceToken]) {
        authenticationManager.deviceToken = deviceToken;
    }
    
    [JCSocket connectWithDeviceToken:deviceToken completion:^(BOOL success, NSError *error) {
        if (success) {
            [self subscribeToLineEvents:authenticationManager.line];
        }
    }];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    if (error) {
        NSLog(@"%@", error);
    }
    
    [self application:application didRegisterForRemoteNotificationsWithDeviceToken:nil];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    
//    [PFPush handlePush:userInfo];
//    TODO:  This is where we need to get the whole message to show the user we have a new message for them.
    
    
    NSLog(@"User info : %@", userInfo);
    NSString *fromNumber = [userInfo objectForKey:@"fromNumber"];
    NSString *didId = [userInfo objectForKey:@"didId"];
    NSString *uid = [userInfo objectForKey:@"uid"];
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    DID *did = [DID MR_findFirstByAttribute:NSStringFromSelector(@selector(didId)) withValue:didId inContext:context];
    if (did) {
        
        JCUnknownNumber *unknownNumber = [JCUnknownNumber unknownNumberWithNumber:fromNumber];
        [SMSMessage downloadMessagesForDID:did toPerson:unknownNumber completion:^(BOOL success, NSError *error) {
            if (success) {
                if ([UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground) {
                    SMSMessage *message = [SMSMessage MR_findFirstByAttribute:NSStringFromSelector(@selector(eventId)) withValue:uid inContext:context];
                    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
                    if (localNotif){
                        localNotif.alertBody =[NSString  stringWithFormat:@"New Message from %@ \n%@", fromNumber.numericStringValue, message.text ];
                        localNotif.soundName = UILocalNotificationDefaultSoundName;
                        localNotif.applicationIconBadgeNumber = 1;
                        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
                    }
                } else {
                    // TODO: Sound an meesage received event.
                }
            }
        }];
    }
    
    
    
    
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
