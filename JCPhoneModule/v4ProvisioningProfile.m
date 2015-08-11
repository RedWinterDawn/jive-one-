//
//  ProvisioningProfile.m
//  JiveOne
//
//  Created by Robert Barclay on 8/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "v4ProvisioningProfile.h"

@implementation v4ProvisioningProfile

-(BOOL)isProvisioned
{
    return YES;
}

-(BOOL)isV5
{
    return NO;
}

-(NSString *)displayName
{
    return @"display name";
}

-(NSString *)username
{
    return @"username";
}

-(NSString *)password
{
    return @"password";
}

-(NSString *)outboundProxy
{
    return @"outbound proxy";
}

-(NSString *)registrationHost
{
    return @"registration host";
}

-(NSString *)server
{
    return @"server";
}

-(void)refreshProvisioningProfileWithCompletion:(void (^)(BOOL, NSError *))completion
{
    if (completion) {
        completion(YES, nil);
    }
}

@end
