//
//  JCPhoneManagerError.m
//  JiveOne
//
//  Created by Robert Barclay on 1/15/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneManagerError.h"

NSString *const kJCPhoneManagerErrorDomain = @"PhoneManagerDomain";

@implementation JCPhoneManagerError

+(instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    return [self errorWithDomain:kJCPhoneManagerErrorDomain code:code userInfo:userInfo];
}

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error
{
    return [self errorWithDomain:kJCPhoneManagerErrorDomain code:code reason:reason underlyingError:error];
}

@end
