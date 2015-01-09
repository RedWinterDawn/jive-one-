//
//  JCV5ApiClient.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCApiClient.h"

@interface JCV5ApiClient : JCApiClient

+ (instancetype)sharedClient;

- (void)clearCookies;
- (void)stopAllOperations;
- (BOOL)isOperationRunning:(NSString *)operationName;
- (void)setRequestAuthHeader:(BOOL) demandsBearer;

@end


typedef enum : NSUInteger {
    JCV5ApiClientInvalidArgumentErrorCode,
    JCV5ApiClientRequestErrorCode,
    JCV5ApiClientResponseParseErrorCode,
} JCV5ApiClientErrorCode;

@interface JCV5ApiClientError : NSError

+(instancetype)errorWithCode:(JCV5ApiClientErrorCode)code reason:(NSString *)reason;

@end