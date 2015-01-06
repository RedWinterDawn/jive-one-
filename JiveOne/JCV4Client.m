	//
//  JCV4ProvisioningClient.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCV4Client.h"

NSString *const kJCV4ClientBaseUrl = @"https://pbx.onjive.com";

@implementation JCV4Client

-(instancetype)init
{
    return [self initWithBaseURL:[NSURL URLWithString:kJCV4ClientBaseUrl]];
}

-(instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self) {
        _manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        _manager.responseSerializer = [JCXMLParserResponseSerializer serializer];
    }
    return self;
}

@end