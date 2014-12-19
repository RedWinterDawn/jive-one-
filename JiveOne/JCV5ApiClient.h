//
//  JCV5ApiClient.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Voicemail;
@class Line;
@class User;

typedef void(^CompletionHandler)(BOOL success, NSError *error);

@interface JCV5ApiClient : NSObject

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

+ (instancetype)sharedClient;

- (void) clearCookies;
- (void) stopAllOperations;
- (BOOL) isOperationRunning:(NSString *)operationName;
- (void)setRequestAuthHeader:(BOOL) demandsBearer;

#pragma mark - Socket API Calls
- (void)SubscribeToSocketEvents:(NSString *)subscriptionURL dataDictionary:(NSDictionary *)dataDictionary;
- (void) RequestSocketSession:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;

- (void)updateVoicemailToRead:(Voicemail*)voicemail completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
- (void)deleteVoicemail:(NSString *)url completed:(void (^)(BOOL succeeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;


@end


typedef enum : NSUInteger {
    JCV5ApiClientInvalidArgumentErrorCode,
    JCV5ApiClientRequestErrorCode,
    JCV5ApiClientResponseParseErrorCode,
} JCV5ApiClientErrorCode;

@interface JCV5ApiClientError : NSError

+(instancetype)errorWithCode:(JCV5ApiClientErrorCode)code reason:(NSString *)reason;

@end