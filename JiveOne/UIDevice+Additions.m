//
//  UIDevice+Additions.m
//  JiveOne
//
//  Created by Robert Barclay on 12/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "UIDevice+Additions.h"

@implementation UIDevice (Compatibility)

-(BOOL)iOS8
{
    return !([self.systemVersion floatValue] < 8.0f);
}

+(BOOL)iOS8
{
    return [UIDevice currentDevice].iOS8;
}

@end

//
//  UIDevice+CellularData.m
//  JiveOne
//
//  Created by Robert Barclay on 12/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <ifaddrs.h>

@import CoreTelephony;

@implementation UIDevice (CellularData)

-(BOOL)carrierAllowsVOIP
{
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    return carrier.allowsVOIP;
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

//
//  UIDevice+InstallationIdentifier.m
//  JiveOne
//
//  Category created to provide a uuid identifier that is generated on first use and stored in the
//  system keychain. 
//
//  Created by Robert Barclay on 12/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCKeychain.h"
#import "NSString+Additions.h"

NSString *const kUIDeviceSimulatorInstallationIdString = @"00000000-0000-0000-0000-000000000000";
NSString *const kUIDeviceInstallationKeychainIdKey = @"installationIdentifier";

@implementation UIDevice (InstallationIdentifier)

-(NSString *)installationIdentifier
{
    NSString *key = self.installationIdentifierKey;
    NSString *string = (NSString *)[JCKeychain loadValueForKey:key];
    if (string.length == 0)
    {

#if TARGET_IPHONE_SIMULATOR
        
        string = kUIDeviceSimulatorInstallationIdString;
        
#else
        
        //Generate UUID to serve as device ID
        CFUUIDRef uuidObj = CFUUIDCreate(nil);
        CFStringRef uuidString = CFUUIDCreateString(nil, uuidObj);
        string = [NSString stringWithString:(__bridge NSString*)uuidString];
        CFRelease(uuidString);
        CFRelease(uuidObj);
        
#endif
        
        [JCKeychain saveValue:string forKey:key];
    }
    return string;
}

-(void)clearInstallationIdentifier
{
    [JCKeychain deleteValueForKey:self.installationIdentifierKey];
}

-(NSString *)installationIdentifierKey
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:(__bridge id)kCFBundleIdentifierKey];
    return [NSString stringWithFormat:@"%@.%@", bundleIdentifier, kUIDeviceInstallationKeychainIdKey];
}

-(NSString *)userUniqueIdentiferForUser:(NSString *)username
{
    return [[NSString stringWithFormat:@"%@-%@", self.installationIdentifier, username] MD5Hash];
}

@end
