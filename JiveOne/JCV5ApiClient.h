//
//  JCV5ApiClient.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Voicemail+Custom.h"
#import "Membership+Custom.h"
#import "Lines+Custom.h"
#import "PBX+Custom.h"


@interface JCV5ApiClient : NSObject

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
+ (instancetype)sharedClient;

- (void) clearCookies;
- (void) stopAllOperations;
- (BOOL) isOperationRunning:(NSString *)operationName;


#pragma mark - Contact API Calls
- (void)RetrieveMyInformation:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
- (void)RetrieveContacts:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;

#pragma mark - Socket API Calls
- (void)SubscribeToSocketEvents:(NSString *)subscriptionURL dataDictionary:(NSDictionary *)dataDictionary;
- (void) RequestSocketSession:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;

#pragma mark - Voicemail API Calls
- (void)getVoicemails :(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
//- (void)downloadVoicemailEntry:(Voicemail*)voicemail completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
- (void)updateVoicemailToRead:(Voicemail*)voicemail completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
- (void)deleteVoicemail:(NSString *)url completed:(void (^)(BOOL succeeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;

#pragma mark - JIF API Calls
- (void)getMailboxReferencesForUser:(NSString*)jiveId completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
- (void)getPbxInformationFromUrl:(NSString *)url completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
@end
