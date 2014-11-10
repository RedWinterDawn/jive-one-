//
//  JCAppDelegate.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAppDelegate.h"
#import <AFNetworkActivityLogger/AFNetworkActivityLogger.h>
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
#import "SipHandler.h"

#import "Voicemail+Custom.h"
#import "JCCallCardManager.h"
#import "JCCallerViewController.h"
#import "JCBadgeManager.h"

@interface JCAppDelegate () <JCCallerViewControllerDelegate, UAPushNotificationDelegate, UARegistrationDelegate>
{
    JCCallerViewController *_presentedCallerViewController;
    bool _didNotify;
}

@property (nonatomic) UIStoryboard* storyboard;
@property (strong, nonatomic) UIViewController *tabBarViewController;
@property (strong, nonatomic) JCLoginViewController *loginViewController;
@end


@implementation JCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    LOG_Info();
    NSLog(LOGGER_TARGET);
    
//    [[JCSocketDispatch sharedInstance] setStartedInBackground:NO];
    
    //Create a sharedCache for AFNetworking
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:2 * 1024 * 1024
                                                            diskCapacity:100 * 1024 * 1024
                                                                diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    
    //set UserDefaults
    NSString *defaultPrefsFile = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
    NSDictionary *defaultPreferences = [NSDictionary dictionaryWithContentsOfFile:defaultPrefsFile];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];
    
    //check if we are using a iphone or ipad
    [self tabBarViewController];
	[self loginViewController];

    
    /*
     * FLURRY
     */
    //note: iOS only allows one crash reporting tool per app; if using another, set to: NO
    [Flurry setCrashReportingEnabled:YES];
    
    // Replace YOUR_API_KEY with the api key in the downloaded package
    [Flurry startSession:@"JCMVPQDYJZNCZVCJQ59P"];
    
    /*
     * AFNETWORKING
     */
	[AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
#if DEBUG
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
    [[AFNetworkActivityLogger sharedLogger] startLogging];
#else
	[[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelOff];
#endif
    
    /*
     * MAGICALRECORD
     */
    [self setupDatabase];

    
    //Register for background fetches
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    //Start monitor for Reachability
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    // Populate AirshipConfig.plist with your app's info from https://go.urbanairship.com
    // or set runtime properties here.
    UAConfig *config = [UAConfig defaultConfig];
    
    // You can also programmatically override the plist values:
    // config.developmentAppKey = @"YourKey";
    // etc.
    
    // Call takeOff (which creates the UAirship singleton)
    [UAirship takeOff:config];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    JCCallCardManager *callCardManager = [JCCallCardManager sharedManager];
    [center addObserver:self selector:@selector(didChangeConnection:) name:AFNetworkingReachabilityDidChangeNotification  object:nil];
    [center addObserver:self selector:@selector(didReceiveIncomingCall:) name:kJCCallCardManagerAddedCallNotification object:callCardManager];
    [center addObserver:self selector:@selector(stopRingtone) name:kJCCallCardManagerAnswerCallNotification object:callCardManager];
    
    // Launches the Badge manager. Should be launched after Mangical record has initialized.
    [[JCBadgeManager sharedManager] initialize];
    
    // Authentication
    JCAuthenticationManager *authenticationManager = [JCAuthenticationManager sharedInstance];
    if (!authenticationManager.userAuthenticated || !authenticationManager.userLoadedMininumData) {
        [self changeRootViewController:JCRootLoginViewController];
    }
    else {
        [self startSocket:NO];
    }
    
    return YES;
}

- (void)didLogInSoCanRegisterForPushNotifications
{
    LOG_Info();

    //[UAPush shared].pushNotificationDelegate = self;
    // Request a custom set of notification types
    //[[UAPush shared] registerForRemoteNotifications];
    //[UAPush shared].notificationTypes = (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert);
}

- (void)didLogOutSoUnRegisterForPushNotifications
{
    LOG_Info();

    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
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
    [self stopSocket];
	
	[[SipHandler sharedHandler] startKeepAwake];
}

/**
 * Called as part of the transition from the background to the inactive state; here you can undo many of the changes 
 * made on entering the background.
 */
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    LOG_Info();

    [Flurry logEvent:@"Resumed Session"];
    
    //[[NotificationView sharedInstance] didChangeConnection:nil];
    if ([[JCAuthenticationManager sharedInstance] userAuthenticated] && [[JCAuthenticationManager sharedInstance] userLoadedMininumData]) {
        //[[JCAuthenticationManager sharedInstance] checkForTokenValidity];
//        [[JCRESTClient sharedClient] RetrieveEntitiesPresence:^(BOOL updated) {
//            //do nothing;
//        } failure:^(NSError *err) {
//            //do nothing;
//        }];
        LogMessage(@"socket", 4, @"Will Call requestSession");
        [self startSocket:NO];
    }
	
	[[SipHandler sharedHandler] stopKeepAwake];
}

/**
 * Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was 
 * previously in the background, optionally refresh the user interface.
 */
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    LOG_Info();
    
//    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
//    if (currentInstallation.badge != 0) {
//        currentInstallation.badge = 0;
//        [currentInstallation saveEventually];
//    }
    _didNotify = false;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alertUserToUpdate:) name:@"AppIsOutdated" object:nil];
    [[JCVersion sharedClient] getVersion];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kApplicationDidBecomeActive" object:nil];
    
}

-(void)alertUserToUpdate:(NSNotification *)notification
{
    LOG_Info();
    
    if ([[notification name] isEqualToString:@"AppIsOutdated"] && (!_didNotify))
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update Required"
                                                        message:@"Please download the latest version of JiveApp Beta."
                                                       delegate:self
                                              cancelButtonTitle:@"Maybe later"
                                              otherButtonTitles:@"Download", nil];
        [alert show];
    }
    _didNotify = true;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    LOG_Info();
    
    if (buttonIndex > 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-services://?action=download-manifest&url=https://jiveios.local/JiveOne.plist"]];
    }
}
- (void)applicationWillTerminate:(UIApplication *)application
{
    LOG_Info();
    
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [MagicalRecord cleanUp];
    _didNotify = false;
}

- (void)startSocket:(BOOL)inBackground
{
    LOG_Info();
    LogMessage(@"socket", 4, @"Calling requestSession From AppDelegate");
	if ([[JCAuthenticationManager sharedInstance] userAuthenticated] && [[JCAuthenticationManager sharedInstance] userLoadedMininumData]) {
		if ([JasmineSocket sharedInstance].socket.readyState != SR_OPEN) {
			[[JasmineSocket sharedInstance] restartSocket];
		}
	}
}

- (void)stopSocket
{
    LogMessage(@"socket", 4, @"Calling stopSocket From AppDelegate");

    LOG_Info();
    
    [[JasmineSocket sharedInstance] closeSocketWithReason:@"Entering background"];
}

#pragma mark - Magical Record Setup
- (void)setupDatabase
{
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:kCoreDataDatabase];
}

- (void)cleanAndResetDatabase
{
    [MagicalRecord cleanUp];
    
    NSString *dbStore = [MagicalRecord defaultStoreName];
    
    NSURL *storeURL = [NSPersistentStore MR_urlForStoreName:dbStore];
    NSURL *walURL = [[storeURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"sqlite-wal"];
    NSURL *shmURL = [[storeURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"sqlite-shm"];
    
    NSError *error = nil;
    BOOL result = YES;
    
    for (NSURL *url in @[storeURL, walURL, shmURL]) {
        @try {
            if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
                result = [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    }
    
    if (result) {
        [self setupDatabase];
    } else {
        NSLog(@"An error has occurred while deleting %@ error %@", dbStore, error);
    }
}

#pragma mark - Push Notifications Handling

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    LOG_Info();
    
//    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
//    [currentInstallation setDeviceTokenFromData:deviceToken];
//    [currentInstallation saveInBackground];
    
    NSString *newToken = [deviceToken description];
	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
//	NSLog(@"APPDELEGATE - My token is: %@", newToken);
    [[NSUserDefaults standardUserDefaults] setObject:newToken forKey:UDdeviceToken];
    LogMessage(@"socket", 4, @"Will Call requestSession");
    [self startSocket:NO];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    LOG_Info();
    LogMessage(@"socket", 4, @"Will Call requestSession");

    [self startSocket:NO];
	NSLog(@"APPDELEGATE - Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    LOG_Info();
    // [[JCSocketDispatch sharedInstance] setStartedInBackground:NO];
    completionHandler([self BackgroundPerformFetchWithCompletionHandler]);
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    LOG_Info();
    // [[JCSocketDispatch sharedInstance] setStartedInBackground:NO];
    completionHandler([self BackgroundPerformFetchWithCompletionHandler]);
}

- (void)receivedForegroundNotification:(NSDictionary *)notification fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    LOG_Info();
    // [[JCSocketDispatch sharedInstance] setStartedInBackground:NO];
    completionHandler([self BackgroundPerformFetchWithCompletionHandler]);
}

- (void)receivedBackgroundNotification:(NSDictionary *)notification fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    LOG_Info();
    // [[JCSocketDispatch sharedInstance] setStartedInBackground:YES];
    completionHandler([self BackgroundPerformFetchWithCompletionHandler]);
}


- (UIBackgroundFetchResult)BackgroundPerformFetchWithCompletionHandler
{
    LOG_Info();
//    [[JCSocketDispatch sharedInstance] setStartedInBackground:YES];
    
    // If we are not a V5 PBX, we do not have a voicemail data to go fetch, and return with a no data callback.
    PBX *pbx = [PBX fetchFirstPBX];
    if (!pbx.v5)
        return UIBackgroundFetchResultNoData;
    
    NSLog(@"APPDELEGATE - performFetchWithCompletionHandler");
    __block UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultFailed;
    if ([JasmineSocket sharedInstance].socket.readyState != SR_OPEN)
    {
        @try {
            TRVSMonitor *monitor = [TRVSMonitor monitor];
            JCBadgeManager *badgeManger = [JCBadgeManager sharedManager];
            [badgeManger startBackgroundUpdates];

            // Fetch Voicemails in the background.
            [Voicemail fetchVoicemailsInBackground:^(BOOL success, NSError *error) {
                if (success) {
                    NSLog(@"Success Done with Block");
                    LogMessage(@"socket", 4, @"Successful Rest Call In Background");
                }
                else {
                    NSLog(@"Error Done With Block %@", error);
                    LogMessage(@"socket", 4, @"Failed Rest Call In Background");
                }
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

                    [self stopSocket];
                }
            }
            
        }
    }
    
    return fetchResult;
}

-(BOOL)seenTutorial
{
    LOG_Info();
    
    return _seenTutorial = [[NSUserDefaults standardUserDefaults] boolForKey:@"seenAppTutorial"];
}

- (UIStoryboard *)storyboard
{
    LOG_Info();
    if (!_storyboard) {
//        _storyboard = self.deviceIsIPhone ? [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] : [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
        _storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    }
    return _storyboard;
}

- (UIWindow *)window
{
    LOG_Info();
    if (!_window) {
        _window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    }
    return _window;
}

- (JCLoginViewController*)loginViewController
{
    LOG_Info();
    if (!_loginViewController) {
        _loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"JCLoginViewController"];
    }
    return _loginViewController;
}

- (UIViewController*)tabBarViewController
{
    LOG_Info();
    if (!_tabBarViewController) {
		_tabBarViewController = self.window.rootViewController;
    }
    return _tabBarViewController;
}

#pragma mark - Change Root ViewController

- (void)logout
{
    LOG_Info();
    [self.tabBarViewController performSegueWithIdentifier:@"logoutSegue" sender:self.tabBarViewController];
}

- (void)changeRootViewController:(JCRootViewControllerType)type
{
    LOG_Info();
	
	if (type == JCRootLoginViewController && [self.window.rootViewController isKindOfClass:[JCLoginViewController class]]) {
		return;
	}
    
    if (type == JCRootTabbarViewController) {
        [self startSocket:NO];
    }
 
	[UIView transitionWithView:self.window
					  duration:0.5
					   options:type == JCRootTabbarViewController ? UIViewAnimationOptionTransitionFlipFromRight : UIViewAnimationOptionTransitionFlipFromLeft
					animations:^{ self.window.rootViewController = (type == JCRootTabbarViewController ? self.tabBarViewController : self.loginViewController); }
					completion:nil];
	
    [self.window makeKeyAndVisible];
}

//#pragma mark - Reachability
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

#pragma mark - Incoming Calls -

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
    
    _presentedCallerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CallerViewController"];
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
