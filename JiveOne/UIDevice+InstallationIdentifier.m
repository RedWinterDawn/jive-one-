//
//  UIDevice+InstallationIdentifier.m
//  JiveOne
//
//  Created by Robert Barclay on 12/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "UIDevice+InstallationIdentifier.h"
#import "JCKeychain.h"

NSString *const kUIDeviceInstallationId = @"installationIdentifier";

@implementation UIDevice (InstallationIdentifier)

-(NSString *)installationIdentifier
{
    NSString *key = self.installationIdentifierKey;
    NSString *string = (NSString *)[JCKeychain loadValueForKey:key];
    if (string.length == 0)
    {
        //Generate UUID to serve as device ID
        CFUUIDRef uuidObj = CFUUIDCreate(nil);
        CFStringRef uuidString = CFUUIDCreateString(nil, uuidObj);
        string = [NSString stringWithString:(__bridge NSString*)uuidString];
        CFRelease(uuidString);
        CFRelease(uuidObj);
        
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
    return [NSString stringWithFormat:@"%@.%@", bundleIdentifier, kUIDeviceInstallationId];
}

@end
