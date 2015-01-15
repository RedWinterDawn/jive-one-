//
//  JCError.h
//  JiveOne
//
//  Created by Robert Barclay on 1/14/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

@interface JCError : NSError

+(instancetype)errorWithCode:(NSInteger)code;
+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason;
+(instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo;

+(instancetype)errorWithDomain:(NSString *)domain code:(NSInteger)code reason:(NSString *)reason;
+(instancetype)errorWithDomain:(NSString *)domain code:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error;

+(NSString *)failureReasonFromCode:(NSInteger)integer;

@end
