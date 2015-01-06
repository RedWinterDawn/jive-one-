//
//  LineConfiguration+V4ProvisioningClient.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "LineConfiguration.h"
#import "JCV4Client.h"

@interface LineConfiguration (V4Client)

+(void)downloadLineConfigurationForLine:(Line *)line completion:(CompletionHandler)completion;

@end

@interface JCProvisioningXmlRequestSerializer : AFHTTPRequestSerializer

@property (nonatomic, readonly) NSString *xml;

@end