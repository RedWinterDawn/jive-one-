//
//  JCV4ProvisioningClient.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCV4ProvisioningClient : NSObject

+(void)requestProvisioningForUser:(NSString *)user password:(NSString *)password completed:(void (^)(BOOL suceeded, NSError *error))completed;

+(NSString *)xmlProvisioningRequestFor:(NSString *)userName password:(NSString *)password;

@end
