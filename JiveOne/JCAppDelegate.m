//
//  JCAppDelegate.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAppDelegate.h"
#import <AFNetworkActivityLogger/AFNetworkActivityLogger.h>
#import "JCSocketDispatch.h"
#import "JCOsgiClient.h"
#import "PersonEntities.h"
#import "NotificationView.h"
#import "JCLoginViewController.h"
#import "Common.h"
#import "TRVSMonitor.h"
#import "JCMessagesViewController.h"
#import "TestFlight.h"
#import "JCContainerViewController.h"
#import "JCVersion.h"
#import "JCLog.h"


@interface JCAppDelegate ()

@property (nonatomic) UIStoryboard* storyboard;
@property (strong, nonatomic) UIViewController *tabBarViewController;
@property (strong, nonatomic) JCLoginViewController *loginViewController;
@end


@implementation JCAppDelegate
int didNotify;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Create a sharedCache for AFNetworking
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:2 * 1024 * 1024
                                                            diskCapacity:100 * 1024 * 1024
                                                                diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    
    //set UserDefaults
    NSString *defaultPrefsFile = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
    NSDictionary *defaultPreferences = [NSDictionary dictionaryWithContentsOfFile:defaultPrefsFile];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];
    
    //note: iOS only allows one crash reporting tool per app; if using another, set to: NO
    [Flurry setCrashReportingEnabled:YES];
    
    // Replace YOUR_API_KEY with the api key in the downloaded package
    [Flurry startSession:@"JCMVPQDYJZNCZVCJQ59P"];
    
    //check if we are using a iphone or ipad
    self.deviceIsIPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? NO : YES;
    
    // start of your application:didFinishLaunchingWithOptions // ...
    [TestFlight takeOff:@"a48098ef-e65e-40b9-8609-e995adc426ac"];
    
    // JCLog configuration
#ifdef CONFIGURATION_JiveClient_Release
    JCLogLevelSetConfiguration(JCLogLevelOff);
#else
    JCLogLevelSetConfiguration(JCLogLevelDebug);
#endif
    
    JCLogInfo(@"launchOptions:%@",launchOptions);
    
#if DEBUG
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelError];
    [[AFNetworkActivityLogger sharedLogger] startLogging];
#endif
    
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"MyJiveDatabase.sqlite"];
    
    //Register for background fetches
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithWhite:0.950 alpha:1.000]];
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor blackColor], NSForegroundColorAttributeName,nil]];
    
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
    //[UAPush shared].pushNotificationDelegate = self;
    // Request a custom set of notification types
    [[UAPush shared] registerForRemoteNotifications];
    [UAPush shared].notificationTypes = (UIRemoteNotificationTypeBadge |
                                         UIRemoteNotificationTypeSound |
                                         UIRemoteNotificationTypeAlert);
    
    
    
    //Setup Parse Framework
    //[Parse setApplicationId:@"pF8x8MNin5QJY3EVyXvQF21PBasJxAmoxA5eo16B" clientKey:@"UQEeTqrFUkvglJUHwEiSItGaAttQvAUyExeZ0Iq9"];
    
    //Only needed for when app is launched from push notification and app was not running in background
    //NSDictionary *pushNotif = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    //if(pushNotif){
    //[self handleLocalNotifications:pushNotif];
    //}
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeConnection:) name:AFNetworkingReachabilityDidChangeNotification  object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeConnection:) name:AFNetworkingReachabilityDidChangeNotification  object:nil];
    
    
    [self refreshTabBadges:NO];    
    if ([[JCAuthenticationManager sharedInstance] userAuthenticated] && [[JCAuthenticationManager sharedInstance] userLoadedMininumData]) {
//        [self changeRootViewController:JCRootTabbarViewController];
//        UIViewController *rootVC = [storyboard instantiateViewControllerWithIdentifier:@"UITabBarController"];
        [self.window setRootViewController:self.tabBarViewController];
//        [self.window setRootViewController:rootVC];
        [[JCAuthenticationManager sharedInstance] checkForTokenValidity];
        [[JCOsgiClient sharedClient] RetrieveEntitiesPresence:^(BOOL updated) {
            //do nothing;
        } failure:^(NSError *err) {
            //do nothing;
        }];
    }
    else {
//        [self changeRootViewController:JCRootLoginViewController];
//        UIViewController *rootVC = [storyboard instantiateViewControllerWithIdentifier:@"JCLoginViewController"];
        [self.window setRootViewController:self.loginViewController];
    }
    
    return YES;
}



- (void)applicationWillResignActive:(UIApplication *)application
{
    JCLogInfo_();
    [Flurry logEvent:@"Left Application"];
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    JCLogInfo_();
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [self stopSocket];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    JCLogInfo_();
    [Flurry logEvent:@"Resumed Session"];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    //[[NotificationView sharedInstance] didChangeConnection:nil];
    [self refreshTabBadges:NO];
    if ([[JCAuthenticationManager sharedInstance] userAuthenticated] && [[JCAuthenticationManager sharedInstance] userLoadedMininumData]) {
        [[JCAuthenticationManager sharedInstance] checkForTokenValidity];
        [[JCOsgiClient sharedClient] RetrieveEntitiesPresence:^(BOOL updated) {
            //do nothing;
        } failure:^(NSError *err) {
            //do nothing;
        }];
        [self startSocket:NO];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    JCLogInfo_();
//    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
//    if (currentInstallation.badge != 0) {
//        currentInstallation.badge = 0;
//        [currentInstallation saveEventually];
//    }
    didNotify = 0;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alertUserToUpdate:) name:@"AppIsOutdated" object:nil];
    [[JCVersion sharedClient] getVersion];

    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

-(void)alertUserToUpdate:(NSNotification *)notification
{
    JCLogInfo_();
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
    JCLogInfo_();
    if (buttonIndex > 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-services://?action=download-manifest&url=https://jiveios.local/JiveOneEnterprise.plist"]];
    }
}
- (void)applicationWillTerminate:(UIApplication *)application
{
    JCLogInfo_();
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [MagicalRecord cleanUp];
    didNotify = 0;
}

- (void)startSocket:(BOOL)inBackground
{
    JCLogInfo_();
    //if ([[JCSocketDispatch sharedInstance] socketState] == SR_CLOSED || [[JCSocketDispatch sharedInstance] socketState] == SR_CLOSING) {
    [[JCSocketDispatch sharedInstance] requestSession:inBackground];
    //}
}

- (void)stopSocket
{
    JCLogInfo_();
    [[JCSocketDispatch sharedInstance] closeSocket];
}

#pragma mark - PushNotifications


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    JCLogInfo_();
//    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
//    [currentInstallation setDeviceTokenFromData:deviceToken];
//    [currentInstallation saveInBackground];
    
    NSString *newToken = [deviceToken description];
	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
	NSLog(@"APPDELEGATE - My token is: %@", newToken);
    [[NSUserDefaults standardUserDefaults] setObject:newToken forKey:UDdeviceToken];
    
    [self startSocket:NO];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    JCLogInfo_();
    [self startSocket:NO];
	NSLog(@"APPDELEGATE - Failed to get token, error: %@", error);
}

//- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo//never gets called
//{
//    JCLogInfo_();
////    [PFPush handlePush:userInfo];
//    NSLog(@"APPDELEGATE - didReceiveRemoteNotification:fetchCompletionHandler");
//}


- (NSInteger)currentBadgeCount
{
    JCLogInfo_();
    NSDictionary * badgeDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"badges"];
    NSMutableDictionary *_badges = nil;
    if (badgeDictionary) {
        _badges = [NSMutableDictionary dictionaryWithDictionary:badgeDictionary];
    }
    
    return _badges.count;
//    NSInteger count = 0;
//    if (_badges) {
//        
//        [_badges enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//            NSNumber *number = [_badges objectForKey:key];
//            count = count + [number integerValue];
//        }];
//        for (NSString *key in _badges)
//        {
//            
//        }
//    }
    
//    return count;
}


// foreground
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    JCLogInfo_();
    completionHandler([self BackgroundPerformFetchWithCompletionHandler]);
}


- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    JCLogInfo_();
    completionHandler([self BackgroundPerformFetchWithCompletionHandler]);
}

#pragma mark - Background Fetch
- (void)receivedForegroundNotification:(NSDictionary *)notification fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    JCLogInfo_();
    completionHandler([self BackgroundPerformFetchWithCompletionHandler]);
}

- (void)receivedBackgroundNotification:(NSDictionary *)notification fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    JCLogInfo_();
    completionHandler([self BackgroundPerformFetchWithCompletionHandler]);
}


- (UIBackgroundFetchResult)BackgroundPerformFetchWithCompletionHandler
{
    JCLogInfo_();
    NSLog(@"APPDELEGATE - performFetchWithCompletionHandler");
    __block UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultFailed;
    if ([[JCSocketDispatch sharedInstance] socketState] != SR_OPEN) {
        //[[JCAuthenticationManager sharedInstance] checkForTokenValidity];
        __block UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultFailed;
        
//        @try {
//            
//            TRVSMonitor *monitor = [TRVSMonitor monitor];
//            NSInteger previousCount = [self currentBadgeCount];
//            
//            [[JCSocketDispatch sharedInstance] startPoolingFromSocketWithCompletion:^(BOOL success, NSError *error) {
//                if (success) {
//                    NSLog(@"Success Done with Block");
//                }
//                else {
//                    NSLog(@"Error Done With Block %@", error);
//                }
//                [monitor signal];
//            }];
//            
//            [monitor waitWithTimeout:25];
//            
//            NSInteger afterCount = [self currentBadgeCount];
//            
//            if (afterCount == 0 || (afterCount == previousCount)) {
//                fetchResult = UIBackgroundFetchResultNoData;
//            }
//            else if (afterCount > previousCount) {
//                fetchResult = UIBackgroundFetchResultNewData;
//                [self refreshTabBadges:YES];
//            }
//        }
//        @catch (NSException *exception) {
//            NSLog(@"%@", exception);
//        }
//        @finally {
//            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground ) {
//                if ([[JCSocketDispatch sharedInstance] socketState] == SR_OPEN) {
//                    [self stopSocket];
//                }
//
//            }
//            
//        }
        
        
    }
    
    return fetchResult;
}


#pragma mark - Tabbar Badges

- (void)incrementBadgeCountForConversation:(NSString *)conversationId entryId:(NSString *)entryId
{
    
    //JCLogInfo_();
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    if (!_badges) {
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
    
//    if (![number boolValue]) {
//        number = [NSNumber numberWithBool:NO];
//        [_badges setObject:number forKey:conversationId];
//    }
//    NSInteger count = [number integerValue];
//    count++;
//    
//    number = [NSNumber numberWithInteger:count];
//    [_badges setObject:number forKey:conversationId];
    
    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTabBadges:NO];
}

- (void)incrementBadgeCountForVoicemail:(NSString *)voicemailId
{
    JCLogInfo_();
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    if (!_badges) {
        _badges = [[NSMutableDictionary alloc] init];
    }
    
    // new conversation
    NSNumber *read = [NSNumber numberWithBool:NO];
    [_badges setObject:read forKey:voicemailId];
    
//    NSNumber *number = [_badges objectForKey:voicemailId];
//    if (![number boolValue]) {
//        number = [NSNumber numberWithBool:NO];
//        [_badges setObject:number forKey:voicemailId];
//    }
    
    
    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTabBadges:NO];
}

//- (void) decrementBadgeCountForConversation:(NSString *)conversationId
//{
//    JCLogInfo_();
//    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
//    if (!_badges) {
//        _badges = [[NSMutableDictionary alloc] init];
//    }
//    
//    NSNumber *number = [_badges objectForKey:conversationId];
//    NSInteger count = [number integerValue];
//    if (count > 0) {
//        count--;
//    }
//    
//    
//    number = [NSNumber numberWithInteger:count];
//    [_badges setObject:number forKey:conversationId];
//    
//    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//    [self refreshTabBadges:NO];
//}
//
//- (void) decrementBadgeCountForVoicemail
//{
//    JCLogInfo_();
//    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
//    if (!_badges) {
//        _badges = [[NSMutableDictionary alloc] init];
//    }
//    
//    NSNumber *number = [_badges objectForKey:@"voicemail"];
//    NSInteger count = [number integerValue];
//    if (count > 0) {
//        count--;
//    }
//    
//    number = [NSNumber numberWithInteger:count];
//    [_badges setObject:number forKey:@"voicemail"];
//    
//    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//    [self refreshTabBadges:NO];
//}

- (void)clearBadgeCountForConversation:(NSString *)conversationId
{
    JCLogInfo_();
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
    JCLogInfo_();
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
    JCLogInfo_();
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
            
            [tabController.viewControllers[2] tabBarItem].badgeValue = conversationCount == 0 ? nil : [NSString stringWithFormat:@"%i", conversationCount];
            [tabController.viewControllers[1] tabBarItem].badgeValue = voicemailCount == 0 ? nil : [NSString stringWithFormat:@"%i", voicemailCount];
            
            
//            // load voice mail badge numbers
//            //NSNumber *voicemailCount = [_badges objectForKey:@"voicemail"];
//            //NSInteger count = voicemailCount.integerValue;
//            //[tabController.viewControllers[1] tabBarItem].badgeValue = count == 0 ? nil : [voicemailCount stringValue];
//            
//            // load conversation counts
//            int voicemailCount = 0;
//            int conversationCount = 0;
//            for (NSString* key in _badges) {
//                
//                //some house keeping.
//                //NSRange rangeVoicemail = [key rangeOfString:@"voicemails"];
//                //if (rangeVoicemail.location == NSNotFound) {
//                    if (_badges[key]) {
//                        NSNumber *currentCount = _badges[key];
//                        if (currentCount.boolValue == YES) {
//                            [_badges removeObjectForKey:key];
//                            continue;
//                        }
//                    }
//                //}
//                
//                NSRange rangeConversation = [key rangeOfString:@"conversations"];
//                NSRange rangeRooms = [key rangeOfString:@"permanentrooms"];
//                if (rangeConversation.location != NSNotFound || rangeRooms.location != NSNotFound) {
//                    conversationCount++;
//                }
//                
//                NSRange rangeVoicemail = [key rangeOfString:@"voicemails"];
//                if (rangeVoicemail.location != NSNotFound ) {
//                    voicemailCount++;
//                }
//                
//            }
//            
//            [tabController.viewControllers[2] tabBarItem].badgeValue = conversationCount == 0 ? nil : [NSString stringWithFormat:@"%i", conversationCount];
//            [tabController.viewControllers[1] tabBarItem].badgeValue = voicemailCount == 0 ? nil : [NSString stringWithFormat:@"%i", voicemailCount];
//            
//            // update Application Badge
//            NSInteger appBadge = conversationCount + voicemailCount;//.integerValue + voicemailCount.integerValue;
//            [UIApplication sharedApplication].applicationIconBadgeNumber = appBadge;
            
//            if (fromRemoteNotification) {
                if (conversationCount != 0 || voicemailCount != 0) {
                    [self setNotification:voicemailCount conversation:conversationCount];
                }
//            }
        }
    }
}

#pragma mark - Local Notifications
- (void)setNotification:(NSInteger)voicemailCount conversation:(NSInteger)conversationCount {
    JCLogInfo_();
    //if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)  {
        
        NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    
    
        [_badges enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSRange rangeConversation = [key rangeOfString:@"conversations"];
            NSRange rangeRooms = [key rangeOfString:@"permanentrooms"];
            if (rangeConversation.location != NSNotFound || rangeRooms.location != NSNotFound) {
                NSMutableDictionary *convCopy = nil;
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
            
            NSRange rangeVoicemail = [key rangeOfString:@"voicemails"];
            if (rangeVoicemail.location != NSNotFound ) {
                NSNumber *notified = _badges[key];
                if (![notified boolValue]) {
                    notified = [NSNumber numberWithBool:YES];
                    Voicemail *lastEntry = [Voicemail MR_findFirstByAttribute:@"voicemailId" withValue:key];
                    if (lastEntry) {
                        NSString *alertMessage = lastEntry.callerNumber ? [NSString stringWithFormat:@"New voicemail from %@", lastEntry.callerNumber]  : @"Unknown";
                        [self showLocalNotificationWithType:@"voicemail" alertMessage:alertMessage];
                    }
                }
                _badges[key] = notified;
                //[[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
                //[[NSUserDefaults standardUserDefaults] synchronize];
            }

        }];
    
//        for (NSString *key in _badges) {
//                    }
    
        [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    //}
//        NSString *alertMessage = @"You have ";
//        
//        if (voicemailCount != 0 && conversationCount != 0) {
//            alertMessage  = [alertMessage stringByAppendingString:[NSString stringWithFormat:@"%d new voicemail(s) and %d new conversation(s).", (int)voicemailCount, (int)conversationCount]];
//            
//            for (NSString* key in _badges) {
//                //some house keeping.
//                if (_badges[key]) {
//                    NSNumber *currentCount = _badges[key];
//                    currentCount = [NSNumber numberWithBool:YES];
//                }
//            }
//        }
//        else if (voicemailCount != 0) {
//            alertMessage  = [alertMessage stringByAppendingString:[NSString stringWithFormat:@"%d new voicemail(s).", (int)voicemailCount]];
//            
//            for (NSString* key in _badges) {
//                NSRange rangeVoicemail = [key rangeOfString:@"voicemails"];
//                if (rangeVoicemail.location != NSNotFound) {
//                    if (_badges[key]) {
//                        NSNumber *currentCount = _badges[key];
//                        if (currentCount.boolValue == YES) {
//                            [_badges removeObjectForKey:key];
//                            continue;
//                        }
//                    }
//                }
//            }
//            
//        }
//        else if (conversationCount != 0) {
//            
//            if (conversationCount == 1) {
//                // grab the last entry for the conversation and set in the snippet lable
//                Conversation *lastModifiedConversation = [Conversation MR_findFirstOrderedByAttribute:@"lastModified" ascending:NO];
//                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"conversationId ==[c] %@", lastModifiedConversation.conversationId];
//                ConversationEntry *lastEntry = [ConversationEntry MR_findFirstWithPredicate:predicate sortedBy:@"lastModified" ascending:NO];
//                PersonEntities *person = [PersonEntities MR_findFirstByAttribute:@"entityId" withValue:lastEntry.entityId];
//                alertMessage = [NSString stringWithFormat:@"%@: \"%@\"", person.firstName, lastEntry.message[@"raw"]];
//            }
//            else {
//                alertMessage  = [alertMessage stringByAppendingString:[NSString stringWithFormat:@"%d new conversation(s).", (int)conversationCount]];
//            }
//            
//            for (NSString* key in _badges) {
//                NSRange rangeConversation = [key rangeOfString:@"conversations"];
//                NSRange rangeRooms = [key rangeOfString:@"permanentrooms"];
//                if (rangeConversation.location != NSNotFound || rangeRooms.location != NSNotFound) {
//                    if (_badges[key]) {
//                        NSNumber *currentCount = _badges[key];
//                        if (currentCount.boolValue == YES) {
//                            [_badges removeObjectForKey:key];
//                            continue;
//                        }
//                    }
//                }
//            }
//
//        }
        
        
        
        
        
       
    //}
}

- (void) showLocalNotificationWithType:(NSString *)alertType alertMessage:(NSString *)alertMessage
{
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = alertMessage;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    //NSInteger currentAppBadge = [UIApplication sharedApplication].applicationIconBadgeNumber;
    //currentAppBadge++;
    //localNotification.applicationIconBadgeNumber = currentAppBadge;
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

#pragma mark - Reachability
- (void)didChangeConnection:(NSNotification *)notification
{
    JCLogInfo_();
    AFNetworkReachabilityStatus status = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
    BOOL appIsActive = [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
    switch (status) {
        case AFNetworkReachabilityStatusNotReachable: {
            NSLog(@"No Internet Connection");
            break;
        }
        case AFNetworkReachabilityStatusReachableViaWiFi:
            NSLog(@"WIFI");
            //send any chat messages in the queue
            [JCMessagesViewController sendOfflineMessagesQueue:[JCOsgiClient sharedClient]];
            //try to initialize socket connections
            
            [self startSocket:!appIsActive];
            break;
        case AFNetworkReachabilityStatusReachableViaWWAN:
            NSLog(@"3G");
            //send any chat messages in the queue
            [JCMessagesViewController sendOfflineMessagesQueue:[JCOsgiClient sharedClient]];
            //try to initialize socket connections
            [self startSocket:!appIsActive];
            break;
        default:
            NSLog(@"Unkown network status");
            break;
            
            [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    }
}

-(BOOL)seenTutorial
{
    JCLogInfo_();
    return _seenTutorial = [[NSUserDefaults standardUserDefaults] boolForKey:@"seenAppTutorial"];
}

- (UIStoryboard *)storyboard
{
    if (!_storyboard) {
        _storyboard = self.deviceIsIPhone ? [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] : [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    }
    return _storyboard;
}

- (UIWindow*)window
{
    if (!_window) {
        _window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    }
    return _window;
}

- (JCLoginViewController*)loginViewController
{
    if (!_loginViewController) {
        _loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"JCLoginViewController"];
    }
    return _loginViewController;
}

- (UIViewController*)tabBarViewController
{
    if (!_tabBarViewController) {
        _tabBarViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UITabBarController"];
    }
    return _tabBarViewController;
}

#pragma mark - Change Root ViewController
- (void)logout
{
    [self.tabBarViewController performSegueWithIdentifier:@"logoutSegue" sender:self.tabBarViewController];
}
- (void)changeRootViewController:(JCRootViewControllerType)type
{
    if (type == JCRootTabbarViewController) {
        
        [self.loginViewController goToApplication];
//        [self.window setRootViewController:self.tabBarViewController];
        
    }
    else if (type == JCRootLoginViewController)
    {
        [self logout];
//        [self.window setRootViewController:self.loginViewController];
    }
    
    [self.window makeKeyAndVisible];
}



@end
