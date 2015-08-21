//
//  JCDebugPhoneManagerTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 1/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCDebugPhoneManagerTableViewController.h"
#import "JCAppSettings.h"
#import "JCPhoneManager.h"

@interface JCDebugPhoneManagerTableViewController ()
{
    AFNetworkReachabilityManager *_manager;
    JCAppSettings *_appSettings;
    JCPhoneManager *_phoneManager;
}

@end

@implementation JCDebugPhoneManagerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _manager = [AFNetworkReachabilityManager sharedManager];
    _phoneManager = self.phoneManager;
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(updateStatus) name:AFNetworkingReachabilityDidChangeNotification object:nil];
    [center addObserver:self selector:@selector(updateStatus) name:kJCPhoneManagerRegisteredNotification object:_phoneManager];
    [center addObserver:self selector:@selector(updateStatus) name:kJCPhoneManagerUnregisteredNotification object:_phoneManager];
    [center addObserver:self selector:@selector(updateStatus) name:kJCPhoneManagerRegisteringNotification object:_phoneManager];
    [center addObserver:self selector:@selector(updateStatus) name:kJCPhoneManagerRegistrationFailureNotification object:_phoneManager];
    
    _appSettings = [JCAppSettings sharedSettings];
    [_appSettings addObserver:self forKeyPath:NSStringFromSelector(@selector(isWifiOnly)) options:0 context:NULL];
    
    [self updateStatus];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_appSettings removeObserver:self forKeyPath:NSStringFromSelector(@selector(isWifiOnly))];
}

-(void)updateStatus
{
    self.reachability.text = [self stringForReachabilityStatus:_manager.networkReachabilityStatus];
    self.previousReachability.text = [self stringForReachabilityStatus:(AFNetworkReachabilityStatus)_phoneManager.networkType];
    self.wifiOnly.text = _phoneManager.settings.isWifiOnly ? @"Yes" : @"No";
    self.connecting.text = _phoneManager.isRegistering ? @"Yes" : @"No";
    self.connected.text = _phoneManager.isRegistered ? @"Yes" : @"No";
}

-(NSString *)stringForReachabilityStatus:(AFNetworkReachabilityStatus)status
{
    switch (status) {
        case AFNetworkReachabilityStatusUnknown:
            return @"Unknown";
            
        case AFNetworkReachabilityStatusNotReachable:
            return @"None";
            
        case AFNetworkReachabilityStatusReachableViaWiFi:
            return @"Wifi";
            
        case AFNetworkReachabilityStatusReachableViaWWAN:
            return @"Cellular";
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(isWifiOnly))]) {
        [self updateStatus];
    }
}

@end
