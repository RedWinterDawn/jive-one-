//
//  JCError.m
//  JiveOne
//
//  Created by Robert Barclay on 1/14/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCError.h"

@implementation JCError

NSString *kJCErrorGerneralDomain = @"JiveGeneralErrorDomain";

+(instancetype)errorWithCode:(NSInteger)code
{
    return [self errorWithCode:code underlyingError:nil];
}

+(instancetype)errorWithCode:(NSInteger)code underlyingError:(NSError *)error
{
    NSString *reason = [self failureReasonFromCode:code];
    return [self errorWithCode:code reason:reason underlyingError:error];
}

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason
{
    return [self errorWithDomain:kJCErrorGerneralDomain code:code reason:reason underlyingError:nil];
}

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error
{
    return [self errorWithDomain:kJCErrorGerneralDomain code:code reason:reason underlyingError:error];
}

+(instancetype)errorWithDomain:(NSString *)domain code:(NSInteger)code reason:(NSString *)reason
{
    
    return [self errorWithDomain:domain code:code reason:reason underlyingError:nil];
}

+(instancetype)errorWithDomain:(NSString *)domain code:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error
{
    NSString *shortReason = [self failureReasonFromCode:code];
    if (!shortReason) {
        shortReason = reason;
    }
    
    NSMutableDictionary *userInfo;
    if (reason) {
        userInfo = [@{NSLocalizedDescriptionKey: NSLocalizedString(reason, nil),
                      NSLocalizedFailureReasonErrorKey: NSLocalizedString(shortReason, nil)} mutableCopy];
    }
    
    if (error) {
        [userInfo setObject:error forKey:NSUnderlyingErrorKey];
    }
    
    return [self errorWithDomain:domain code:code userInfo:userInfo];
}

+(instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    return [self errorWithDomain:kJCErrorGerneralDomain code:code userInfo:userInfo];
}


+(NSString *)failureReasonFromCode:(NSInteger)integer
{
    return nil;
}

@end
