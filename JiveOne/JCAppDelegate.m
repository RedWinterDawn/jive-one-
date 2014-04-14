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
#import "JCVersionTracker.h"
#import "JCOsgiClient.h"
#import "ClientEntities.h"
#import "NotificationView.h"
#import "JCStartLoginViewController.h"
#import "JCLoginViewController.h"
#import "Common.h"
#import <Parse/Parse.h>
#import "TRVSMonitor.h"
#import "JCMessagesViewController.h"



@implementation JCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if DEBUG
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelError];
    [[AFNetworkActivityLogger sharedLogger] startLogging];
#endif
    
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"MyJiveDatabase.sqlite"];
    
    //Register for PushNotifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                           UIRemoteNotificationTypeBadge |
                                                                           UIRemoteNotificationTypeSound)];
    //Register for background fetches
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.169 green:0.204 blue:0.267 alpha:1.0]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,nil]];
    
    //Start monitor for Reachability
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    //Setup Parse Framework
    [Parse setApplicationId:@"pF8x8MNin5QJY3EVyXvQF21PBasJxAmoxA5eo16B" clientKey:@"UQEeTqrFUkvglJUHwEiSItGaAttQvAUyExeZ0Iq9"];
    
    //Only needed for when app is launched from push notification and app was not running in background
    NSDictionary *pushNotif = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if(pushNotif){
        [self handleLocalNotifications:pushNotif];
    }
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeConnection:) name:AFNetworkingReachabilityDidChangeNotification  object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeConnection:) name:AFNetworkingReachabilityDidChangeNotification  object:nil];

    
    [self refreshTabBadges];
    
    if ([[JCAuthenticationManager sharedInstance] userAuthenticated]) {
        [self changeRootViewController:JCRootTabbarViewController];
        [[JCAuthenticationManager sharedInstance] checkForTokenValidity];
    }
    else {
        [self changeRootViewController:JCRootLoginViewController];
    }
    
    return YES;
}


							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [self stopSocket];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    //[[NotificationView sharedInstance] didChangeConnection:nil];
    [self refreshTabBadges];
    if ([[JCAuthenticationManager sharedInstance] userAuthenticated]) {
        [[JCAuthenticationManager sharedInstance] checkForTokenValidity];
        [self startSocket];
    }   
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [MagicalRecord cleanUp];
}

- (void)startSocket
{
    [[JCSocketDispatch sharedInstance] requestSession];
}

- (void)stopSocket
{
    [[JCSocketDispatch sharedInstance] closeSocket];
}

#pragma mark - PushNotifications
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
    
    NSString *newToken = [deviceToken description];
	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
	NSLog(@"APPDELEGATE - My token is: %@", newToken);
    [[NSUserDefaults standardUserDefaults] setObject:newToken forKey:@"deviceToken"];
    
    [self startSocket];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    [self startSocket];
	NSLog(@"APPDELEGATE - Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo//never gets called
{
     [PFPush handlePush:userInfo];
    NSLog(@"APPDELEGATE - didReceiveRemoteNotification:fetchCompletionHandler");
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"APPDELEGATE - didReceiveRemoteNotification");
    
    NSLog(@"Remote Notification Recieved");
    //setup local notification that user can click on to open app and call didReceiveLocalNotification
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody =  [userInfo objectForKey:@"message"];
    //set code in notification object so that proper view controller is opened
    [notification setUserInfo:userInfo];
    [application presentLocalNotificationNow:notification];
    completionHandler(UIBackgroundFetchResultNewData);
    
}

#pragma mark - Local notifications

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif
{
    if (app.applicationState == UIApplicationStateInactive )
    {
        NSLog(@"app not running");
        
    }
    else if(app.applicationState == UIApplicationStateActive )
    {
        NSLog(@"app running");
    }
    //get data from push notification
    NSDictionary *payload = notif.userInfo;
     [self handleLocalNotifications:payload];
}


-(void) handleLocalNotifications:(NSDictionary*)payload{
    NSLog(@"handleLocalNotificaiton");
    NSUInteger pushCode = [[payload objectForKey:@"pushCode"] intValue];
    if(!pushCode==0){
        switch (pushCode) {
            case 1://handle voicemail push
            {
                //TODO: switch to voicemail tab
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
                UITabBarController *tabVC = [storyboard instantiateViewControllerWithIdentifier:@"UITabBarController"];
                [tabVC setSelectedIndex:3];   
                break;
            }
            case 2://handle chat push
                //switch to chat tab
                
                
            default:
                break;
        }
    }
    
}



#pragma mark - Background Fetch
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{

    __block UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultFailed;
    __block BOOL requestFailed = NO;
    TRVSMonitor *monitor = [TRVSMonitor monitor];
//
//    NSInteger preCount = [Conversation MR_findAll].count;
//    
//    [[JCOsgiClient sharedClient] RetrieveVoicemailForEntity:nil success:^(id JSON) {
//        [monitor signal];
//    } failure:^(NSError *err) {
//        requestFailed = YES;
//        [monitor signal];
//    }];
//    
//    [monitor wait];
//    
//    
//    [[JCOsgiClient sharedClient] RetrieveConversations:^(id JSON) {
//        [monitor signal];
//    } failure:^(NSError *err) {
//        requestFailed = YES;
//        [monitor signal];
//    }];
    
    [self startSocket];
    
    [monitor waitWithTimeout:10];
    
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    if (!_badges) {
        fetchResult = UIBackgroundFetchResultNoData;
    }
    else {
        for (NSString *key in _badges)
        {
            NSNumber *number = [_badges objectForKey:key];
            NSInteger count = [number integerValue];
            if (count > 0) {
                fetchResult = UIBackgroundFetchResultNewData;
                break;
            }
        }
    }
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground ) {
        [self stopSocket];
    }
    completionHandler(fetchResult);
    
}
//- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
//{
//    NSLog(@"Remote Notification Recieved");
//    UILocalNotification *notification = [[UILocalNotification alloc] init];
//    notification.alertBody =  @"APP DELGATE performFetchWithCompletionHandler";
//    [application presentLocalNotificationNow:notification];
//    completionHandler(UIBackgroundFetchResultNewData);
//}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    NSLog(@"APPDELEGATE - handleEventsForBackgroundURLSession");
}

#pragma mark - Tabbar Badges

- (void)incrementBadgeCountForConversation:(NSString *)conversationId
{
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    if (!_badges) {
        _badges = [[NSMutableDictionary alloc] init];
    }
    
    NSNumber *number = [_badges objectForKey:conversationId];
    NSInteger count = [number integerValue];
    count++;
    
    number = [NSNumber numberWithInteger:count];
    [_badges setObject:number forKey:conversationId];
    
    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTabBadges];
}

- (void)incrementBadgeCountForVoicemail
{
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    if (!_badges) {
        _badges = [[NSMutableDictionary alloc] init];
    }
    
    NSNumber *number = [_badges objectForKey:@"voicemail"];
    NSInteger count = [number integerValue];
    count++;
    
    number = [NSNumber numberWithInteger:count];
    [_badges setObject:number forKey:@"voicemail"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTabBadges];
}

- (void) decrementBadgeCountForConversation:(NSString *)conversationId
{
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    if (!_badges) {
        _badges = [[NSMutableDictionary alloc] init];
    }
    
    NSNumber *number = [_badges objectForKey:conversationId];
    NSInteger count = [number integerValue];
    if (count > 0) {
        count--;
    }
    
    
    number = [NSNumber numberWithInteger:count];
    [_badges setObject:number forKey:conversationId];
    
    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTabBadges];
}

- (void) decrementBadgeCountForVoicemail
{
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    if (!_badges) {
        _badges = [[NSMutableDictionary alloc] init];
    }
    
    NSNumber *number = [_badges objectForKey:@"voicemail"];
    NSInteger count = [number integerValue];
    if (count > 0) {
        count--;
    }
    
    number = [NSNumber numberWithInteger:count];
    [_badges setObject:number forKey:@"voicemail"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTabBadges];
}

- (void)clearBadgeCountForConversation:(NSString *)conversationId
{
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    if (!_badges) {
        _badges = [[NSMutableDictionary alloc] init];
    }
    
    [_badges removeObjectForKey:conversationId];
    
    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTabBadges];
}

- (void)clearBadgeCountForVoicemail
{
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    if (!_badges) {
        _badges = [[NSMutableDictionary alloc] init];
    }
    
    NSNumber *number = [_badges objectForKey:@"voicemail"];
    NSInteger count = [number integerValue];
    count = 0;
    
    number = [NSNumber numberWithInteger:count];
    [_badges setObject:number forKey:@"voicemail"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTabBadges];
}

- (void)refreshTabBadges
{
    UITabBarController *tabController = (UITabBarController *)self.window.rootViewController;
    if ([tabController isKindOfClass:[UITabBarController class]]) {
        
        NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
        if (_badges) {
            
            // load voice mail badge numbers
            NSNumber *voicemailCount = [_badges objectForKey:@"voicemail"];
            NSInteger count = voicemailCount.integerValue;
            [tabController.viewControllers[1] tabBarItem].badgeValue = count == 0 ? nil : [voicemailCount stringValue];
            
            // load conversation counts
            count = 0;
            for (NSString* key in _badges) {
                NSRange range = [key rangeOfString:@"conversations"];
                if (range.location != NSNotFound) {
                    count++;
                }
            }
            
            NSNumber *converationCount = [NSNumber numberWithInt:count];
            [tabController.viewControllers[2] tabBarItem].badgeValue = count == 0 ? nil : [converationCount stringValue];
            
        }
    }
}

#pragma mark - Reachability
- (void)didChangeConnection:(NSNotification *)notification
{
    AFNetworkReachabilityStatus status = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
    switch (status) {
        case AFNetworkReachabilityStatusNotReachable: {
            NSLog(@"No Internet Connection");
            break;
        }
        case AFNetworkReachabilityStatusReachableViaWiFi:
            NSLog(@"WIFI");
            //send any chat messages in the queue
            [JCMessagesViewController sendOfflineMessagesQueue];
            break;
        case AFNetworkReachabilityStatusReachableViaWWAN:
            NSLog(@"3G");
            //send any chat messages in the queue
            [JCMessagesViewController sendOfflineMessagesQueue];
            break;
        default:
            NSLog(@"Unkown network status");
            break;
            
            [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    }
}

#pragma mark - Change Root ViewController
- (void)changeRootViewController:(JCRootViewControllerType)type
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    if (type == JCRootTabbarViewController) {
        
        UITabBarController *tabVC = [storyboard instantiateViewControllerWithIdentifier:@"UITabBarController"];
        
        [self.window setRootViewController:tabVC];
        
        //[[NotificationView sharedInstance] showPanelInView:tabVC.view];
        //[[NotificationView sharedInstance] didChangeConnection:nil];
    }
    else if (type == JCRootLoginViewController)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        JCLoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"JCLoginViewController"];
        [self.window setRootViewController:loginVC];
    }
    
}


@end
