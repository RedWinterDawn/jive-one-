//
//  JCAppDelegate.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAppDelegate.h"
#import <AFNetworkActivityLogger/AFNetworkActivityLogger.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AFNetworkActivityIndicatorManager.h"
#import "JasmineSocket.h"
#import "PersonEntities.h"
#import "NotificationView.h"
#import "JCLoginViewController.h"
#import "Common.h"
#import "TRVSMonitor.h"
#import "JCVersion.h"
#import "LoggerClient.h"
#import "JCLinePickerViewController.h"

#import "Voicemail+Custom.h"
#import "JCCallCardManager.h"
#import "JCCallerViewController.h"
#import "JCBadgeManager.h"
#import "JCApplicationSwitcherDelegate.h"
#import "JCV5ApiClient.h"

#import "PBX.h"
#import "Line.h"
#import "User.h"

#import "Voicemail+Custom.h"
#import "Contact+Custom.h"

#import "UAirship.h"
#import "UAConfig.h"
#import "UAPush.h"
#import "UIViewController+HUD.h"

@interface JCAppDelegate () <JCCallerViewControllerDelegate, UAPushNotificationDelegate, UARegistrationDelegate, JCPickerViewControllerDelegate>
{
    JCCallerViewController *_presentedCallerViewController;
    JCAuthenticationManager *_authenticationManager;
    JCCallCardManager *_phoneManager;
    
    UINavigationController *_navigationController;
    UIViewController *_appSwitcherViewController;
}

@end

@implementation JCAppDelegate

/**
 * Loads all the singletons nessary when the application is loaded.
 */
-(void)initialializeApplication
{
    _appSwitcherViewController = self.window.rootViewController;
    
    [self configureNetworking];
    [self loadUserDefaults];
    
    // Load Core Data
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:kCoreDataDatabase];
    
    // Badging
    [[JCBadgeManager sharedManager] initialize];
    UAConfig *config = [UAConfig defaultConfig];
    [UAirship takeOff:config];
    
    // Authentication
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    _authenticationManager = [JCAuthenticationManager sharedInstance];
    [center addObserver:self selector:@selector(userDidLogout:) name:kJCAuthenticationManagerUserLoggedOutNotification object:_authenticationManager];
    [center addObserver:self selector:@selector(userDataReady:) name:kJCAuthenticationManagerUserLoadedMinimumDataNotification object:_authenticationManager];
    [center addObserver:self selector:@selector(lineChanged:) name:kJCAuthenticationManagerLineChangedNotification object:_authenticationManager];
    [_authenticationManager checkAuthenticationStatus];
}

/**
 *  We predominately use the AFNetworking Networking stack to handle data request between the App and Jive Servers for
 *  data requests. Here we configure caching, logging and monitoring indication for AFNetoworking.
 */
-(void)configureNetworking
{
    //Create a sharedCache for AFNetworking
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:2 * 1024 * 1024
                                                            diskCapacity:100 * 1024 * 1024
                                                                diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    
    /*
     * AFNETWORKING
     */
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
#if DEBUG
    //[[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
    [[AFNetworkActivityLogger sharedLogger] startLogging];
#else
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelOff];
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeConnection:) name:AFNetworkingReachabilityDidChangeNotification  object:nil];
    
    //Start monitor for Reachability
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

/**
 * Loads a default set of defaults into NSUserDefaults to be used on first load. If a default is not set by code, it is 
 * read from the default set. If the default then becomes set, it overrides the default.
 */
-(void)loadUserDefaults
{
    //set UserDefaults
    NSString *defaultPrefsFile = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
    NSDictionary *defaultPreferences = [NSDictionary dictionaryWithContentsOfFile:defaultPrefsFile];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];
}

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
    
    JCLinePickerViewController *linePickerViewController = (JCLinePickerViewController *)[_appSwitcherViewController.storyboard instantiateViewControllerWithIdentifier:@"LinePickerViewController"];
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
    if (!_authenticationManager.line.pbx.isV5)
        return UIBackgroundFetchResultNoData;
    
    NSLog(@"APPDELEGATE - performFetchWithCompletionHandler");
    __block UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultFailed;
    if ([JasmineSocket sharedInstance].socket.readyState != SR_OPEN)
    {
        @try {
            TRVSMonitor *monitor = [TRVSMonitor monitor];
            JCBadgeManager *badgeManger = [JCBadgeManager sharedManager];
            [badgeManger startBackgroundUpdates];
            
            Line *line = [JCAuthenticationManager sharedInstance].line;
            [Voicemail downloadVoicemailsForLine:line complete:^(BOOL suceeded, NSError *error) {
                [monitor signal];
            }];
            
            // No Socket for now.
            //            [[JCSocketDispatch sharedInstance] startPoolingFromSocketWithCompletion:^(BOOL success, NSError *error) {
            //                if (success) {
            //                    NSLog(@"Success Done with Block");
            //                    LogMessage(@"socket", 4, @"Success pooling from socket");
            //                }
            //                else {
            //                    NSLog(@"Error Done With Block %@", error);
            //                    LogMessage(@"socket", 4, @"Error pooling from socket");
            //
            //                }
            //                [monitor signal];
            //            }];
            
            [monitor waitWithTimeout:25];
            NSUInteger badgeUpdateEvents = [badgeManger endBackgroundUpdates];
            if (badgeUpdateEvents != 0) {
                fetchResult = UIBackgroundFetchResultNewData;
            }
            else {
                fetchResult = UIBackgroundFetchResultNoData;
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
        @finally {
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground ) {
                if ([JasmineSocket sharedInstance].socket.readyState == SR_OPEN) {
                    LogMessage(@"socket", 4, @"Will Call closeSocket");
                    
                    [JasmineSocket stopSocket];
                }
            }
            
        }
    }
    
    return fetchResult;
}

-(void)registerServicesToLine:(Line *)line
{
//    // Register the Phone.
//    UIViewController *rootViewController = self.window.rootViewController;
//    [JCCallCardManager connectToLine:line
//                             started:^{
//                                 [rootViewController showHudWithTitle:@"" detail:@"Selecting Line..."];
//                             }
//                           completed:^(BOOL success, NSError *error) {
//                               [rootViewController hideHud];
//                               if (!success) {
//                                   [rootViewController showSimpleAlert:@"" message:@"Unable to connect to this line at this time. Please Try again." code:error.code];
//                               }
//                            }];
    // Get Contacts
    [Contact downloadContactsForLine:line complete:NULL];
    
    // Get Voicemails
    [Voicemail downloadVoicemailsForLine:line complete:NULL];
}

#pragma mark - Notification Handlers -

#pragma mark JCAuthenticationManager

/**
 * Notification of user authentications and loading of minimum required data has occured.
 */
-(void)userDataReady:(NSNotification *)notification
{
    // If we have not already, initialize the phone manager singleton, store a reference to it and register for notifications.
    if (!_phoneManager) {
        _phoneManager = [JCCallCardManager sharedManager];
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(didReceiveIncomingCall:) name:kJCCallCardManagerAddedCallNotification object:_phoneManager];
        [center addObserver:self selector:@selector(stopRingtone) name:kJCCallCardManagerAnswerCallNotification object:_phoneManager];
    }
    
    // If the user has multiple line configurations, we prompt them to select which line they would like to connect with. When
    // selected, the authentication manager will notify that they have changed their selected line.
    NSInteger lines = [Line MR_countOfEntities];
    if (lines > 1) {
        [self presentLineConfigurationViewController:YES];
        return;
    }
    
    [self dismissLoginViewController:YES completed:^(BOOL finished) {
        JCAuthenticationManager *authenticationManager = notification.object;
        [self registerServicesToLine:authenticationManager.line];
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

/**
 * Notification of user inititated logout.
 */
-(void)userDidLogout:(NSNotification *)notification
{
    LOG_Info();
    
    [Flurry logEvent:@"Log out"];
    
    [JasmineSocket stopSocket];                         // Kill any socket connections.
    [[JCV5ApiClient sharedClient] stopAllOperations];   // Kill any netowrk operations.
    [JCApplicationSwitcherDelegate reset];              // Resets the App Switcher to be
    [JCBadgeManager reset];                             // Resets the Badge Manager.
    [JCCallCardManager disconnect];                     // Dissconnect the
    [self presentLoginViewController:YES];              // Present the login view.
    
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
}



#pragma mark JCCallCardManager

/**
 * Responds to a notification dispatched by the JCCallCardManager when a incoming call occurs. Presents an instance of
 * the CallerViewController modaly with ourselves set up as the delegate responder to the view controller.
 */
-(void)didReceiveIncomingCall:(NSNotification *)notification
{
    [self startVibration];
    
    NSDictionary *userInfo = notification.userInfo;
    BOOL incoming = [[userInfo objectForKey:kJCCallCardManagerIncomingCall] boolValue];
    int priorCount = [[userInfo objectForKey:kJCCallCardManagerPriorUpdateCount] intValue];
    if (!incoming || priorCount > 0)
        return;
    
    [self startRingtone];
    
    _presentedCallerViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"CallerViewController"];
    _presentedCallerViewController.delegate = self;
    _presentedCallerViewController.callOptionsHidden = true;
    _presentedCallerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self.window.rootViewController presentViewController:_presentedCallerViewController animated:YES completion:NULL];
}

/**
 * Delegate rsponder to remove the the presented modal view controller when an incomming callerver view controller is
 * dismissed. Used only if the caller was presented from the app delegate.
 */
-(void)shouldDismissCallerViewController:(JCCallerViewController *)viewController
{
    [self.window.rootViewController dismissViewControllerAnimated:FALSE completion:^{
        _presentedCallerViewController = nil;
        [self stopRingtone];
        [self stopVibration];
    }];
}

#pragma mark AFNetworkReachabilityManager

- (void)didChangeConnection:(NSNotification *)notification
{
    LOG_Info();
    
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    AFNetworkReachabilityStatus status = manager.networkReachabilityStatus;
    switch (status)
    {
        case AFNetworkReachabilityStatusNotReachable: {
            NSLog(@"No Internet Connection");
            
            break;
        }
        case AFNetworkReachabilityStatusReachableViaWiFi: {
            NSLog(@"WIFI");
            
            // TRY TO RECONNECT
            
            //            //send any chat messages in the queue
            //            [JCMessagesViewController sendOfflineMessagesQueue:[JCRESTClient sharedClient]];
            //            //try to initialize socket connections
            //            LogMessage(@"socket", 4, @"Will Call requestSession");
            //
            //            [self startSocket:!appIsActive];
            break;
        }
        case AFNetworkReachabilityStatusReachableViaWWAN: {
            NSLog(@"3G");
            //            //send any chat messages in the queue
            //            [JCMessagesViewController sendOfflineMessagesQueue:[JCRESTClient sharedClient]];
            //            //try to initialize socket connections
            //            LogMessage(@"socket", 4, @"Will Call requestSession");
            //
            //            [self startSocket:!appIsActive];
            break;
        }
        default:
            NSLog(@"Unkown network status");
            break;
    }
}

#pragma mark - Delegate Handlers -

-(void)pickerViewControllerShouldDismiss:(JCPickerViewController *)controller
{
    [self dismissLoginViewController:YES completed:NULL];
}

#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    LOG_Info();
    NSLog(LOGGER_TARGET);
    
    /*
     * FLURRY
     */
    //note: iOS only allows one crash reporting tool per app; if using another, set to: NO
    [Flurry setCrashReportingEnabled:YES];
    
    // Replace YOUR_API_KEY with the api key in the downloaded package
    [Flurry startSession:@"JCMVPQDYJZNCZVCJQ59P"];
    
    //Register for background fetches
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    [self initialializeApplication];
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
    
    [Flurry logEvent:@"Left Application"];
}

/**
 * Use this method to release shared resources, save user data, invalidate timers, and store enough application state 
 * information to restore your application to its current state in case it is terminated later. If your application 
 * supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
 */
-(void)applicationDidEnterBackground:(UIApplication *)application
{
    LOG_Info();
    LogMessage(@"socket", 4, @"Will Call CloseSocket");
    [JasmineSocket stopSocket];
}

/**
 * Called as part of the transition from the background to the inactive state; here you can undo many of the changes 
 * made on entering the background.
 */
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    LOG_Info();

    [Flurry logEvent:@"Resumed Session"];
    [JasmineSocket startSocket];
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

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    LOG_Info();
    
    NSString *newToken = [deviceToken description];
	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [[NSUserDefaults standardUserDefaults] setObject:newToken forKey:UDdeviceToken];
    LogMessage(@"socket", 4, @"Will Call requestSession");
    [JasmineSocket startSocket];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    LOG_Info();
    LogMessage(@"socket", 4, @"Will Call requestSession");
    [JasmineSocket startSocket];
	NSLog(@"APPDELEGATE - Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    completionHandler([self backgroundPerformFetchWithCompletionHandler]);
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

#pragma mark - Ringing

static bool incommingCall;

-(void)startVibration
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    bool vibrate = [userDefaults boolForKey:@"vibrateOnRing"];
    if (vibrate)
    {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, endVibration, NULL);
    }
}


-(void)stopVibration
{
    incommingCall = false;
}

void endVibration (SystemSoundID ssID, void *clientData)
{
    if (!incommingCall)
        return;
    
    double delayInSeconds = 1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!incommingCall)
            return;
        AudioServicesPlaySystemSound(ssID);
    });
}

-(void)startRingtone
{
    incommingCall = true;
    @try {
        SystemSoundID soundId = [self playRingtone];
        AudioServicesAddSystemSoundCompletion(soundId, NULL, NULL, endRingtone, NULL);
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.description);
    }
}

void endRingtone (SystemSoundID ssID, void *clientData)
{
    if (!incommingCall)
        return;
    
    double delayInSeconds = 1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!incommingCall)
            return;
        AudioServicesPlaySystemSound(ssID);
    });
}

-(SystemSoundID)playRingtone
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSURL *url = [NSURL fileURLWithPath:@"/System/Library/Audio/UISounds/vc~ringing.caf"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)url, &soundID);
    AudioServicesPlaySystemSound(soundID);
    
    bool vibrate = [userDefaults boolForKey:@"vibrateOnRing"];
    if (vibrate)
        AudioServicesPlaySystemSound(4095);
    return soundID;
}


-(void)stopRingtone
{
    incommingCall = false;
}

@end
