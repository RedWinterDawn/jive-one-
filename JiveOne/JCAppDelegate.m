//
//  JCAppDelegate.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAppDelegate.h"
#import <AFNetworkActivityLogger/AFNetworkActivityLogger.h>
#import "JasmineSocket.h"
#import "JCRESTClient.h"
#import "JCVoicemailClient.h"
#import "PersonEntities.h"
#import "NotificationView.h"
#import "JCLoginViewController.h"
#import "Common.h"
#import "TRVSMonitor.h"
#import "TestFlight.h"
#import "JCVersion.h"
#import "LoggerClient.h"

@interface JCAppDelegate ()

@property (nonatomic) UIStoryboard* storyboard;
@property (strong, nonatomic) UIViewController *tabBarViewController;
@property (strong, nonatomic) JCLoginViewController *loginViewController;
@end


@implementation JCAppDelegate
int didNotify;

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
    self.deviceIsIPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? NO : YES;
    
    /*
     * FLURRY
     */
    //note: iOS only allows one crash reporting tool per app; if using another, set to: NO
    [Flurry setCrashReportingEnabled:YES];
    
    // Replace YOUR_API_KEY with the api key in the downloaded package
    [Flurry startSession:@"JCMVPQDYJZNCZVCJQ59P"];
    
    /*
     * TESTFLIGHT
     */
    // start of your application:didFinishLaunchingWithOptions // ...
    [TestFlight takeOff:@"a48098ef-e65e-40b9-8609-e995adc426ac"];
    
    /*
     * AFNETWORKING
     */
#if DEBUG
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelError];
    [[AFNetworkActivityLogger sharedLogger] startLogging];
#endif
    
    /*
     * MAGICALRECORD
     */
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"MyJiveDatabase.sqlite"];
    
    //Register for background fetches
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    if ([[UINavigationBar class]respondsToSelector:@selector(appearance)]) {
        [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                               UITextAttributeTextColor : [UIColor blackColor],
                                                               UITextAttributeFont : [UIFont fontWithName:@"HelveticaNeue-Light" size:24.0f]
                                                               }];
    }
    
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
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeConnection:) name:AFNetworkingReachabilityDidChangeNotification  object:nil];
    
    
    [self refreshTabBadges:NO];    
    if ([[JCAuthenticationManager sharedInstance] userAuthenticated] && [[JCAuthenticationManager sharedInstance] userLoadedMininumData]) {
        [self.window setRootViewController:self.tabBarViewController];
        //[[JCAuthenticationManager sharedInstance] checkForTokenValidity];
    }
    else {
        //TODO:********
        [self.window setRootViewController:self.loginViewController];
    }
    
    return YES;
}

- (void)didLogInSoCanRegisterForPushNotifications
{
    LOG_Info();

    //[UAPush shared].pushNotificationDelegate = self;
    // Request a custom set of notification types
    [[UAPush shared] registerForRemoteNotifications];
    [UAPush shared].notificationTypes = (UIRemoteNotificationTypeBadge |
                                         UIRemoteNotificationTypeSound |
                                         UIRemoteNotificationTypeAlert);
}

- (void)didLogOutSoUnRegisterForPushNotifications
{
    LOG_Info();

    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
}



- (void)applicationWillResignActive:(UIApplication *)application
{
    LOG_Info();
    
    [Flurry logEvent:@"Left Application"];
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    LOG_Info();

    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    LogMessage(@"socket", 4, @"Will Call CloseSocket");

    [self stopSocket];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    LOG_Info();

    [Flurry logEvent:@"Resumed Session"];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
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
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    LOG_Info();
    
//    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
//    if (currentInstallation.badge != 0) {
//        currentInstallation.badge = 0;
//        [currentInstallation saveEventually];
//    }
    didNotify = 0;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alertUserToUpdate:) name:@"AppIsOutdated" object:nil];
    [[JCVersion sharedClient] getVersion];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kApplicationDidBecomeActive" object:nil];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

-(void)alertUserToUpdate:(NSNotification *)notification
{
    LOG_Info();
    
    if ([[notification name] isEqualToString:@"AppIsOutdated"] && (didNotify < 1))
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update Required"
                                                        message:@"Please download the latest version of JiveApp Beta."
                                                       delegate:self
                                              cancelButtonTitle:@"Maybe later"
                                              otherButtonTitles:@"Download", nil];
        [alert show];
    }
    didNotify = 1;
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
    didNotify = 0;
}

- (void)startSocket:(BOOL)inBackground
{
    LOG_Info();
    LogMessage(@"socket", 4, @"Calling requestSession From AppDelegate");

//    if ([JCSocketDispatch sharedInstance].webSocket.readyState != SR_OPEN) {
//        [[JCSocketDispatch sharedInstance] requestSession];
//    }
}

- (void)stopSocket
{
    LogMessage(@"socket", 4, @"Calling stopSocket From AppDelegate");

    LOG_Info();
    
    [[JasmineSocket sharedInstance] closeSocketWithReason:@"Entering background"];
}

#pragma mark - PushNotifications


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    LOG_Info();
    
//    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
//    [currentInstallation setDeviceTokenFromData:deviceToken];
//    [currentInstallation saveInBackground];
    
    NSString *newToken = [deviceToken description];
	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
	NSLog(@"APPDELEGATE - My token is: %@", newToken);
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


- (NSInteger)currentBadgeCount
{
    LOG_Info();
    
    NSDictionary * badgeDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"badges"];
    NSMutableDictionary *_badges = nil;
    if (badgeDictionary) {
        _badges = [NSMutableDictionary dictionaryWithDictionary:badgeDictionary];
        int count = 0;
        for (NSString *key in _badges.allKeys)
        {
            NSRange rangeConversation = [key rangeOfString:@"conversations"];
            NSRange rangeRooms = [key rangeOfString:@"permanentrooms"];
            if (rangeConversation.location != NSNotFound || rangeRooms.location != NSNotFound) {
            NSMutableDictionary *conversations = [_badges[key] mutableCopy];
                if (conversations) {
                    count += conversations.count;
                }
            }
            else {
                count++;
            }
        }
        
        return count;
    }
    else
    {
        return 0;
    }
}


// foreground
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    LOG_Info();
//    [[JCSocketDispatch sharedInstance] setStartedInBackground:NO];

    completionHandler([self BackgroundPerformFetchWithCompletionHandler]);
}


- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    LOG_Info();
//    [[JCSocketDispatch sharedInstance] setStartedInBackground:NO];

    completionHandler([self BackgroundPerformFetchWithCompletionHandler]);
}

#pragma mark - Background Fetch
- (void)receivedForegroundNotification:(NSDictionary *)notification fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    LOG_Info();
//    [[JCSocketDispatch sharedInstance] setStartedInBackground:NO];

    completionHandler([self BackgroundPerformFetchWithCompletionHandler]);
}

- (void)receivedBackgroundNotification:(NSDictionary *)notification fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    LOG_Info();
//    [[JCSocketDispatch sharedInstance] setStartedInBackground:YES];

    completionHandler([self BackgroundPerformFetchWithCompletionHandler]);
}


- (UIBackgroundFetchResult)BackgroundPerformFetchWithCompletionHandler
{
    LOG_Info();
//    [[JCSocketDispatch sharedInstance] setStartedInBackground:YES];

    NSLog(@"APPDELEGATE - performFetchWithCompletionHandler");
    __block UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultFailed;
    if ([JasmineSocket sharedInstance].socket.readyState != PSWebSocketReadyStateOpen) {
        //[[JCAuthenticationManager sharedInstance] checkForTokenValidity];
        __block UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultFailed;
        
        @try {
            
            TRVSMonitor *monitor = [TRVSMonitor monitor];
            NSInteger previousCount = [self currentBadgeCount];

            
// V5 only provides voicemail through REST. So re make a REST Call
            
            [[JCVoicemailClient sharedClient] getVoicemails:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
                if (suceeded) {
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
            
            NSInteger afterCount = [self currentBadgeCount];
            
            if (afterCount == 0 || (afterCount == previousCount)) {
                fetchResult = UIBackgroundFetchResultNoData;
            }
            else if (afterCount > previousCount) {
                fetchResult = UIBackgroundFetchResultNewData;
                [self refreshTabBadges:YES];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
        @finally {
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground ) {
                if ([JasmineSocket sharedInstance].socket.readyState == PSWebSocketReadyStateOpen) {
                    LogMessage(@"socket", 4, @"Will Call closeSocket");

                    [self stopSocket];
                }

            }
            
        }
    }
    
    return fetchResult;
}


#pragma mark - Tabbar Badges

- (void)incrementBadgeCountForConversation:(NSString *)conversationId entryId:(NSString *)entryId
{
    LOG_Info();
    
    //
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    if (!_badges) {
    LOG_Info();
        _badges = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableDictionary *conversationDictionary = [[_badges objectForKey:conversationId] mutableCopy];
    if (!conversationDictionary) {
        conversationDictionary = [[NSMutableDictionary alloc] init];
    }
    
    // new conversation
    NSNumber *read = [NSNumber numberWithBool:NO];
    [conversationDictionary setObject:read forKey:entryId];
    
    [_badges setValue:conversationDictionary forKey:conversationId];
    
    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTabBadges:NO];
}

- (void)incrementBadgeCountForVoicemail:(NSString *)jrn
{
    LOG_Info();
    
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    if (!_badges) {
        _badges = [[NSMutableDictionary alloc] init];
    }
    
    // new voicemail
    NSNumber *read = [NSNumber numberWithBool:NO];
    [_badges setObject:read forKey:jrn];
    
    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTabBadges:NO];
}

- (void) decrementBadgeCountForVoicemail:(NSString *)voicemailId;
{
    LOG_Info();
    
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    if (!_badges) {
        _badges = [[NSMutableDictionary alloc] init];
    }
    
    if (_badges) {
        NSNumber *read = _badges[voicemailId];
        if (read) {
            [_badges removeObjectForKey:voicemailId];
            
            [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self refreshTabBadges:NO];
        }
    }
    
    
}

- (void)clearBadgeCountForConversation:(NSString *)conversationId
{
    LOG_Info();
    
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    if (!_badges) {
        _badges = [[NSMutableDictionary alloc] init];
    }
    
    [_badges removeObjectForKey:conversationId];
    
    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTabBadges:NO];
}

- (void)clearBadgeCountForVoicemail
{
    LOG_Info();
    
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    if (!_badges) {
        _badges = [[NSMutableDictionary alloc] init];
    }
    
    NSNumber *number = [_badges objectForKey:@"voicemail"];
    
    NSLog(@"%@", number);
    
    number = [NSNumber numberWithInteger:0];
    [_badges setObject:number forKey:@"voicemail"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTabBadges:NO];
}

- (void)refreshTabBadges:(BOOL)fromRemoteNotification
{
    LOG_Info();
    
    UITabBarController *tabController = (UITabBarController *)self.window.rootViewController;
    if ([tabController isKindOfClass:[UITabBarController class]]) {
        
        NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
        if (_badges) {
            
            int voicemailCount = 0;
            int conversationCount = 0;
            
            for (NSString *key in _badges) {
                
                NSRange rangeConversation = [key rangeOfString:@"conversations"];
                NSRange rangeRooms = [key rangeOfString:@"permanentrooms"];
                if (rangeConversation.location != NSNotFound || rangeRooms.location != NSNotFound) {
                    conversationCount++;
                }
                
                NSRange rangeVoicemail = [key rangeOfString:@"voicemails"];
                if (rangeVoicemail.location != NSNotFound ) {
                    voicemailCount++;
                }
            }
            
//            [tabController.viewControllers[2] tabBarItem].badgeValue = conversationCount == 0 ? nil : [NSString stringWithFormat:@"%i", conversationCount];//TODO: reenable for chat
            [tabController.viewControllers[0] tabBarItem].badgeValue = voicemailCount == 0 ? nil : [NSString stringWithFormat:@"%i", voicemailCount];
            
            int appCount = conversationCount + voicemailCount;
            [UIApplication sharedApplication].applicationIconBadgeNumber = appCount;
            
            if (fromRemoteNotification) {
                if (conversationCount != 0 || voicemailCount != 0) {
                    [self setNotification:voicemailCount conversation:conversationCount];
                }
            }
        }
    }
}

#pragma mark - Local Notifications
- (void)setNotification:(NSInteger)voicemailCount conversation:(NSInteger)conversationCount {
    LOG_Info();
    
    //if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)  {
        
        NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    
    
        [_badges enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSRange rangeConversation = [key rangeOfString:@"conversations"];
            NSRange rangeRooms = [key rangeOfString:@"permanentrooms"];
            if (rangeConversation.location != NSNotFound || rangeRooms.location != NSNotFound) {
                NSMutableDictionary *convCopy = nil;
                if ([_badges[key] isKindOfClass:[NSDictionary class]]) {
                    NSMutableDictionary *conversations = [_badges[key] mutableCopy];
                    if (conversations) {
                        convCopy = [[conversations copy] mutableCopy];
                        for (NSString *entry in conversations) {
                            NSNumber *shown = conversations[entry];
                            if (![shown boolValue]) {
                                
                                ConversationEntry *lastEntry = [ConversationEntry MR_findFirstByAttribute:@"entryId" withValue:entry];
                                PersonEntities *person = [PersonEntities MR_findFirstByAttribute:@"entityId" withValue:lastEntry.entityId];
                                NSString *alertMessage = [NSString stringWithFormat:@"%@: \"%@\"", person.firstName, lastEntry.message[@"raw"]];
                                
                                [self showLocalNotificationWithType:@"conversation" alertMessage:alertMessage];
                                [convCopy setObject:[NSNumber numberWithBool:YES] forKey:entry];
                                
                                
                            }
                        }
                        [_badges setObject:convCopy forKey:key];
                    }
                }
                
            }
            
            NSRange rangeVoicemail = [key rangeOfString:@"jrn"];
            if (rangeVoicemail.location != NSNotFound ) {
                NSNumber *notified = _badges[key];
                if (![notified boolValue]) {
                    notified = [NSNumber numberWithBool:YES];
                    Voicemail *lastEntry = [Voicemail MR_findFirstByAttribute:@"jrn" withValue:key];
                    if (lastEntry) {
                        NSString *alertMessage = lastEntry.callerId ? [NSString stringWithFormat:@"New voicemail from %@", lastEntry.callerIdNumber]  : @"Unknown";
                        [self showLocalNotificationWithType:@"voicemail" alertMessage:alertMessage];
                    }
                }
                _badges[key] = notified;
                //[[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
                //[[NSUserDefaults standardUserDefaults] synchronize];
            }

        }];
    
        [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
        [[NSUserDefaults standardUserDefaults] synchronize];

}

- (void) showLocalNotificationWithType:(NSString *)alertType alertMessage:(NSString *)alertMessage
{
    LOG_Info();
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = alertMessage;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    //NSInteger currentAppBadge = [UIApplication sharedApplication].applicationIconBadgeNumber;
    //currentAppBadge++;
    //localNotification.applicationIconBadgeNumber = currentAppBadge;
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

//#pragma mark - Reachability
//- (void)didChangeConnection:(NSNotification *)notification
//{
//    LOG_Info();
//    
//    AFNetworkReachabilityStatus status = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
//    BOOL appIsActive = [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
//    switch (status) {
//        case AFNetworkReachabilityStatusNotReachable: {
//            NSLog(@"No Internet Connection");
//            break;
//        }
//        case AFNetworkReachabilityStatusReachableViaWiFi:
//            NSLog(@"WIFI");
//            //send any chat messages in the queue
//            [JCMessagesViewController sendOfflineMessagesQueue:[JCRESTClient sharedClient]];
//            //try to initialize socket connections
//            LogMessage(@"socket", 4, @"Will Call requestSession");
//
//            [self startSocket:!appIsActive];
//            break;
//        case AFNetworkReachabilityStatusReachableViaWWAN:
//            NSLog(@"3G");
//            //send any chat messages in the queue
//            [JCMessagesViewController sendOfflineMessagesQueue:[JCRESTClient sharedClient]];
//            //try to initialize socket connections
//            LogMessage(@"socket", 4, @"Will Call requestSession");
//
//            [self startSocket:!appIsActive];
//            break;
//        default:
//            NSLog(@"Unkown network status");
//            break;
//            
//            [[AFNetworkReachabilityManager sharedManager] startMonitoring];
//    }
//}

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

- (UIWindow*)window
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
        _tabBarViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UITabBarController"];
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
    //[[JCSocketDispatch sharedInstance] setStartedInBackground:NO];

    if (type == JCRootTabbarViewController) {
        
        //[self.loginViewController goToApplication];
        self.tabBarViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self.window setRootViewController:self.tabBarViewController];
        
    }
    else if (type == JCRootLoginViewController)
    {
        [self logout];
//        [self.window setRootViewController:self.loginViewController];
    }
    
    [self.window makeKeyAndVisible];
}



@end
