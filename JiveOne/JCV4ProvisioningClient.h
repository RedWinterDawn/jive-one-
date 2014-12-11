//
//  JCV4ProvisioningClient.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "User.h"

@interface JCV4ProvisioningRequest : NSMutableURLRequest

+(NSMutableURLRequest *)requestWithLine:(Line *)line;

@end

@interface JCV4ProvisioningClient : NSObject

+(void)requestProvisioningForLine:(Line *)line completed:(void (^)(BOOL suceeded, NSError *error))completed;

@end

typedef enum : NSUInteger {
    UnknownProvisioningError = 0,
    InvalidRequestParametersError,
    RequestResponseError,
    ResponseParseError
} JCV4ProvisioningErrorType;

@interface JCV4ProvisioningError : NSError

+(instancetype)errorWithType:(JCV4ProvisioningErrorType)type reason:(NSString *)reason;

@end