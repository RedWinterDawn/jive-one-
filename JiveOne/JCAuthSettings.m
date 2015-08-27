//
//  JCAuthenticationSettings.m
//  JiveOne
//
//  Created by Robert Barclay on 8/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthSettings.h"

@implementation JCAuthSettings

-(void)setRememberMe:(BOOL)remember
{
    [self setBoolValue:remember forKey:NSStringFromSelector(@selector(rememberMe))];
}

- (BOOL)rememberMe
{
    return [self.userDefaults boolForKey:NSStringFromSelector(@selector(rememberMe))];
}

-(void)setRememberMeUser:(NSString *)rememberMeUser
{
    [self setValue:rememberMeUser forKey:NSStringFromSelector(@selector(rememberMeUser))];
}

-(NSString *)rememberMeUser
{
    return [self.userDefaults valueForKey:NSStringFromSelector(@selector(rememberMeUser))];
}


@end
