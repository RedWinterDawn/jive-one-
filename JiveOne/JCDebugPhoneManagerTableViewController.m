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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkConnectivityChanged:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
    _appSettings = [JCAppSettings sharedSettings];
    [_appSettings addObserver:self forKeyPath:NSStringFromSelector(@selector(isWifiOnly)) options:0 context:NULL];
    
    _phoneManager = [JCPhoneManager sharedManager];
    [_phoneManager addObserver:self forKeyPath:@"connecting" options:0 context:NULL];
    [_phoneManager addObserver:self forKeyPath:@"connected" options:0 context:NULL];
    
    [self updateStatus];
    
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_appSettings removeObserver:self forKeyPath:NSStringFromSelector(@selector(isWifiOnly))];
    [_phoneManager removeObserver:self forKeyPath:@"connecting"];
    [_phoneManager removeObserver:self forKeyPath:@"connected"];
}

-(void)updateStatus
{
    self.reachability.text = [self stringForReachabilityStatus:_manager.networkReachabilityStatus];
    self.previousReachability.text = [self stringForReachabilityStatus:(AFNetworkReachabilityStatus)_phoneManager.networkType];
    self.wifiOnly.text = _appSettings.isWifiOnly ? @"Yes" : @"No";
    self.connecting.text = _phoneManager.isConnecting ? @"Yes" : @"No";
    self.connected.text = _phoneManager.isConnected ? @"Yes" : @"No";
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

-(void)networkConnectivityChanged:(NSNotification *)notification
{
    [self updateStatus];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(isWifiOnly))]) {
        [self updateStatus];
    }
    else if ([keyPath isEqualToString:@"connecting"]) {
        [self updateStatus];
    }
    else if ([keyPath isEqualToString:@"connected"]) {
        [self updateStatus];
    }
}

@end
