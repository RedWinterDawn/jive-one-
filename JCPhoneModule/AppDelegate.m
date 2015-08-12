//
//  AppDelegate.m
//  JCPhoneModule
//
//  Created by Robert Barclay on 8/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "AppDelegate.h"

#import "JCPhoneManager.h"

#import "v4ProvisioningProfile.h"
#import "v5ProvisioningProfile.h"

@interface AppDelegate ()<JCPhoneManagerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    JCPhoneManager *phoneManager = [JCPhoneManager sharedManager];
    [phoneManager.settings loadDefaultsFromFile:@"UserDefaults.plist"];  // Load the Defaults.
    
    v5ProvisioningProfile *provisioningProfile = [v5ProvisioningProfile phoneNumberWithName:@"test" number:@"1001"];
    phoneManager.delegate = self;
    [phoneManager connectWithProvisioningProfile:provisioningProfile];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Phone Manager Delegate -

-(void)phoneManager:(JCPhoneManager *)phoneManger phoneNumbersForKeyword:(NSString *)keyword provisioning:(id<JCPhoneProvisioningDataSource>)provisioning completion:(void (^)(NSArray *))completion
{
    if (completion) {
        completion(nil);
    }
}

-(void)phoneManager:(JCPhoneManager *)phoneManager provisioning:(id<JCPhoneProvisioningDataSource>)provisioning didReceiveUpdatedVoicemailCount:(NSUInteger)count
{
    
}

-(void)phoneManager:(JCPhoneManager *)manager reportCallOfType:(JCPhoneManagerCallType)type lineSession:(JCPhoneSipSession *)lineSession provisioningProfile:(id<JCPhoneProvisioningDataSource>)provisioningProfile
{
    
}

-(id<JCPhoneNumberDataSource>)phoneManager:(JCPhoneManager *)phoneManager lastCalledNumberForProvisioning:(id<JCPhoneProvisioningDataSource>)provisioning
{
    return nil;
}

-(id<JCPhoneNumberDataSource>)phoneManager:(JCPhoneManager *)manager phoneNumberForNumber:(NSString *)number name:(NSString *)name provisioning:(id<JCPhoneProvisioningDataSource>)provisioning
{
    return [JCPhoneNumber phoneNumberWithName:name number:number];
}

@end
