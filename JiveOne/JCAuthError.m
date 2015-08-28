//
//  JCAuthError.m
//  JiveOne
//
//  Created by Robert Barclay on 1/14/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthError.h"

@implementation JCAuthError

NSString *kJCAuthErrorDomain = @"AuthErrorDomain";

-(NSError *)underlyingError
{
    return [self.userInfo objectForKey:NSUnderlyingErrorKey];
}

-(NSError *)rootError
{
    return [[self class] underlyingErrorForError:self];
}

+(NSError *)underlyingErrorForError:(NSError *)error
{
    NSError *underlyingError = [error.userInfo objectForKey:NSUnderlyingErrorKey];
    if (underlyingError) {
        return [self underlyingErrorForError:underlyingError];
    }
    return error;
}

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
    return [self errorWithDomain:kJCAuthErrorDomain code:code reason:reason underlyingError:nil];
}

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error
{
    return [self errorWithDomain:kJCAuthErrorDomain code:code reason:reason underlyingError:error];
}

+(instancetype)errorWithDomain:(NSString *)domain code:(NSInteger)code reason:(NSString *)reason
{
    
    return [self errorWithDomain:domain code:code reason:reason underlyingError:nil];
}

+(NSInteger)underlyingErrorCodeForError:(NSError *)error
{
    return [self underlyingErrorForError:error].code;
}

+(instancetype)errorWithDomain:(NSString *)domain code:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error
{
    NSMutableDictionary *userInfo = nil;
    NSString *description = [self descriptionFromCode:code];
    if (!description && reason) {
        description = reason;
    }
    
    if (description) {
        userInfo = [NSMutableDictionary new];
        [userInfo setObject:description forKey:NSLocalizedDescriptionKey];
    }
    
    NSString *shortReason = [self failureReasonFromCode:code];
    if (!shortReason) {
        shortReason = reason;
    }
    
    if (shortReason) {
        if (!userInfo) {
            userInfo = [NSMutableDictionary new];
        }
        [userInfo setObject:shortReason forKey:NSLocalizedFailureReasonErrorKey];
    }
    
    if (error) {
        if (!userInfo) {
            userInfo = [NSMutableDictionary new];
        }
        [userInfo setObject:error forKey:NSUnderlyingErrorKey];
    }
    
    return [self errorWithDomain:domain code:code userInfo:userInfo];
}

+(instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    return [self errorWithDomain:kJCAuthErrorDomain code:code userInfo:userInfo];
}


+(NSString *)failureReasonFromCode:(NSInteger)integer
{
    return nil;
}

+(NSString *)descriptionFromCode:(NSInteger)integer
{
    return nil;
}

@end
