//
//  JCAuthError.h
//  JiveOne
//
//  Created by Robert Barclay on 1/14/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

@interface JCAuthError : NSError

@property (nonatomic, readonly) NSError *rootError;
@property (nonatomic, readonly) NSError *underlyingError;

+(instancetype)errorWithCode:(NSInteger)code;
+(instancetype)errorWithCode:(NSInteger)code underlyingError:(NSError *)error;

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason;
+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error;

+(instancetype)errorWithDomain:(NSString *)domain code:(NSInteger)code reason:(NSString *)reason;
+(instancetype)errorWithDomain:(NSString *)domain code:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error;

+(instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo;

+(NSString *)failureReasonFromCode:(NSInteger)integer;
+(NSString *)descriptionFromCode:(NSInteger)integer;

+(NSError *)underlyingErrorForError:(NSError *)error;
+(NSInteger)underlyingErrorCodeForError:(NSError *)error;


@end
