//
//  JCSMSClient.m
//  JiveOne
//
//  Created by P Leonard on 2/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSMSClient.h"

NSString *const kJCSMSClientBaseUrl = @"https://api.jive.com/sms";

@implementation JCSMSClient

-(instancetype)init
{
    NSURL *url = [NSURL URLWithString:kJCSMSClientBaseUrl];
    return [self initWithBaseURL:url];
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
