//
//  JCAuthenticationManagerError.h
//  JiveOne
//
//  Created by Robert Barclay on 11/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

typedef enum : NSUInteger {
    InvalidAuthenticationParameters,
    AutheticationError,
    NetworkError,
    TimeoutError,
    NoPbx,
    MultiplePbx,
    ProvisioningFailure,
    
} JCAuthenticationManagerErrorType;

@interface JCAuthenticationManagerError : NSError

+(instancetype)errorWithType:(JCAuthenticationManagerErrorType)type
                 description:(NSString *)reason;

@end
