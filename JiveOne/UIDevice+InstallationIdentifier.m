//
//  UIDevice+InstallationIdentifier.m
//  JiveOne
//
//  Created by Robert Barclay on 12/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "UIDevice+InstallationIdentifier.h"
#import "KeychainItemWrapper.h"

NSString *const kUIDeviceInstallationId = @"installationIdentifier";
static KeychainItemWrapper *keychain;

@implementation UIDevice (InstallationIdentifier)

-(NSString *)installationIdentifier
{
    if (!keychain)
        keychain = [[KeychainItemWrapper alloc] initWithIdentifier:kUIDeviceInstallationId accessGroup:nil];
    
    NSString *string = nil;;
    id object = [keychain objectForKey:(__bridge id)(kSecValueData)];
    if ([object isKindOfClass:[NSString class]])
        string = (NSString *)object;
    
    if (string.length == 0)
    {
        //Generate UUID to serve as device ID
        CFUUIDRef uuidObj = CFUUIDCreate(nil);
        CFStringRef uuidString = CFUUIDCreateString(nil, uuidObj);
        string = [NSString stringWithString:(__bridge NSString*)uuidString];
        CFRelease(uuidString);
        CFRelease(uuidObj);
        
        [keychain setObject:string forKey:(__bridge id)(kSecValueData)];
    }
    return string;
}

-(void)clearInstallationIdentifier
{
    if (!keychain)
        keychain = [[KeychainItemWrapper alloc] initWithIdentifier:kUIDeviceInstallationId accessGroup:nil];
    [keychain resetKeychainItem];
}

@end
