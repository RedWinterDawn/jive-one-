//
//  LineConfiguration+V4ProvisioningClient.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "LineConfiguration.h"

@interface LineConfiguration (V4ProvisioningClient)

+(void)downloadLineConfigurationForLine:(Line *)line completion:(CompletionHandler)completion;

@end
