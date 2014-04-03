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
#import "Common.h"



@implementation JCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if DEBUG
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelError];
    [[AFNetworkActivityLogger sharedLogger] startLogging];
#endif
    
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"MyJiveDatabase.sqlite"];
    [self startSocket];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(socketDidConnect:) name:@"com.jiveone.socketConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(socketDidFailToConnect:) name:@"com.jiveone.socketNotConnected" object:nil];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveConversation:) name:kNewConversation object:nil];
    
    //Register for PushNotifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                           UIRemoteNotificationTypeBadge |
                                                                           UIRemoteNotificationTypeSound)];
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.169 green:0.204 blue:0.267 alpha:1.0]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,nil]];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];

    // add notification view to parent navigation controller
    
    
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeConnection:) name:AFNetworkingReachabilityDidChangeNotification  object:nil];
    
    [self changeRootViewController:JCRootLoginViewController];
    
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
    
    NSLog(@"applicationDidEnterBackground");
    NSLog(@"%u", [JCSocketDispatch sharedInstance].webSocket.readyState);
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[NotificationView sharedInstance] didChangeConnection:nil];
    
    NSString *token = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
    
    if (![Common stringIsNilOrEmpty:token]) {
        [self startSocket];
    }   
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [MagicalRecord cleanUp];
}

#pragma mark - Socket Notifications
- (void)socketDidConnect:(NSNotification *)notification
{
    NSLog(@"APPDELEGATE - Socket is Connected");
}

- (void)socketDidFailToConnect:(NSNotification *)notification
{
    
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
    NSString *newToken = [deviceToken description];
	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
	NSLog(@"APPDELEGATE - My token is: %@", newToken);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"APPDELEGATE - Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"APPDELEGATE - didReceiveRemoteNotification:fetchCompletionHandler");
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"APPDELEGATE - didReceiveRemoteNotification");
    
    NSLog(@"Remote Notification Recieved");
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody =  @"Looks like i got a notification - fetch thingy";
    [application presentLocalNotificationNow:notification];
    completionHandler(UIBackgroundFetchResultNewData);
}

#pragma mark - Background Fetch
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"Remote Notification Recieved");
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody =  @"Looks like i got a notification - fetch thingy";
    [application presentLocalNotificationNow:notification];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    NSLog(@"APPDELEGATE - handleEventsForBackgroundURLSession");
}

#pragma mark - Conversation
- (void)didReceiveConversation:(NSNotification *)notification
{
    
    UITabBarController *tabController = (UITabBarController *)self.window.rootViewController;
    [tabController.viewControllers[1] tabBarItem].badgeValue = @"30";
    
//    [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:[NSString stringWithFormat:@"%d",[UIApplication sharedApplication].applicationIconBadgeNumber]];
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
            break;
        case AFNetworkReachabilityStatusReachableViaWWAN:
            NSLog(@"3G");
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
        
        [[NotificationView sharedInstance] showPanelInView:tabVC.view];
        [[NotificationView sharedInstance] didChangeConnection:nil];
    }
    else if (type == JCRootLoginViewController)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        JCStartLoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"JCStartLoginViewController"];
        [self.window setRootViewController:loginVC];
    }
    
}


@end
