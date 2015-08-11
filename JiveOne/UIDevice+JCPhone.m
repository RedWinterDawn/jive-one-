//
//  UIDevice+JCPhone.m
//  JiveOne
//
//  Created by Robert Barclay on 8/11/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "UIDevice+JCPhone.h"

#import <ifaddrs.h>
@import CoreTelephony;

@implementation UIDevice (JCPhone)

-(BOOL)carrierAllowsVOIP
{
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    return carrier.allowsVOIP;
}

-(NSString *)defaultCarrier
{
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    return carrier.carrierName;
}

-(NSString *)carrierIsoCountryCode
{
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    return carrier.isoCountryCode;
}


-(BOOL)canMakeCall
{
    //    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    //    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    //    NSString *carrierName = carrier.carrierName;
    //    BOOL allowsVoip = carrier.allowsVOIP;
    //    NSString *mobileNetworkCode = carrier.mobileNetworkCode;
    
    
    BOOL hasCellular = [self hasCellular];
    BOOL canOpenURL = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]];
    BOOL canMakeCall = false;
    
    // If we are iOS 7, which does not support continuity, the device has to have cellular, and be able to open the
    // tel:// scheme.
    if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0f)
    {
        canMakeCall = hasCellular && canOpenURL;
    }
    
    // iOS 8+, support for continuity.
    else
    {
        canMakeCall = hasCellular || canOpenURL;
    }
    return canMakeCall;
}

- (bool) hasCellular {
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    bool found = false;
    if (getifaddrs(&addrs) == 0) {
        cursor = addrs;
        while (cursor != NULL) {
            NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
            if ([name isEqualToString:@"pdp_ip0"]) {
                found = true;
                break;
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    return found;
}

/*
 
 CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
 NSLog(@"Current Radio Access Technology: %@", telephonyInfo.currentRadioAccessTechnology);
 [NSNotificationCenter.defaultCenter addObserverForName:CTRadioAccessTechnologyDidChangeNotification
 object:nil
 queue:nil
 usingBlock:^(NSNotification *note)
 {
 NSLog(@"New Radio Access Technology: %@", telephonyInfo.currentRadioAccessTechnology);
 }];
 
 */

@end
