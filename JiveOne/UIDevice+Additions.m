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


#import <sys/sysctl.h>

@implementation UIDevice (Platform)

-(NSString *)platform {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    return platform;
}

-(NSString *)platformType {
    return [self platformType:[self platform]];
}

- (NSString *) platformType:(NSString *)platform
{
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    if ([platform isEqualToString:@"iPad4,3"])      return @"iPad Air";
    if ([platform isEqualToString:@"iPad4,4"])      return @"iPad Mini 2G (WiFi)";
    if ([platform isEqualToString:@"iPad4,5"])      return @"iPad Mini 2G (Cellular)";
    if ([platform isEqualToString:@"iPad4,6"])      return @"iPad Mini 2G";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    return platform;
}

@end

