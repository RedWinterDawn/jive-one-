//
//  JCSMSClient.m
//  JiveOne
//
//  Created by P Leonard on 2/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSMSClient.h"

#ifndef DEBUG
NSString *const kJCSMSClientBaseUrl = @"https://api.jive.com/sms";
#else
NSString *const kJCSMSClientBaseUrl = @"http://10.20.130.20:60257";
#endif

@implementation JCSMSClient

-(instancetype)init
{
    return [self initWithBaseURL:[NSURL URLWithString:kJCSMSClientBaseUrl]];
}

-(instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self) {
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.requestSerializer = [JCAuthenticationJSONRequestSerializer serializer];
    }
    return self;
}

@end
