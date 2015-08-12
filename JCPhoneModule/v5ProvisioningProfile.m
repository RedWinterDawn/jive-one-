//
//  v5ProvisioningProfile.m
//  JiveOne
//
//  Created by Robert Barclay on 8/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "v5ProvisioningProfile.h"

@implementation v5ProvisioningProfile

-(BOOL)isProvisioned
{
    return YES;
}

-(BOOL)isV5
{
    return YES;
}

-(NSString *)displayName
{
    return @"6669 Robert Barclay Mobile";
}

-(NSString *)username
{
    return @"014ed67c3a035158d8000100610001";
}

-(NSString *)password
{
    return @"yrpZT0gcG3RnYxeu";
}

-(NSString *)outboundProxy
{
    return @"mobile.jive.rtcfront.net";
}

-(NSString *)registrationHost
{
    return @"reg.jiveip.net";
}

-(NSString *)server
{
    return self.outboundProxy;
}

-(void)refreshProvisioningProfileWithCompletion:(void (^)(BOOL, NSError *))completion
{
    if (completion) {
        completion(YES, nil);
    }
}

@end
