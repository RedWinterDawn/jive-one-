//
//  JCOsgiClient.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import "ConversationEntry.h"
#import "Conversation+Custom.h"
#import "ConversationEntry.h"
#import "PersonEntities.h"
#import "Voicemail.h"

@interface JCOsgiClient : NSObject

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;


+ (instancetype)sharedClient;


#pragma mark - Retrieve Operations
- (void) RetrieveClientEntitites:(void (^)(id JSON))success
                            failure:(void (^)(NSError *err))failure;
- (void) RetrieveMyEntitity:(void (^)(id JSON, id operation))success
                    failure:(void (^)(NSError *err, id operation))failure;
- (void) RetrieveMyCompany:(NSString*)company :(void (^)(id JSON))success
                    failure:(void (^)(NSError *err))failure;
- (void) RetrieveConversations:(void (^)(id JSON))success
                       failure:(void (^)(NSError *err))failure;
- (void) RetrieveConversationsByConversationId:(NSString*)conversationId success:(void (^)(Conversation * conversation)) success failure:(void (^)(NSError *err))failure;
- (void)RetrieveEntitiesPresence:(void (^)(BOOL updated))success failure:(void(^)(NSError *err))failure;
- (void) RetrievePresenceForEntity:(NSString*)entity withPresendUrn:(NSString*)presenceUrn success:(void (^)(BOOL updated))success failure:(void(^)(NSError *err))failure;
- (void) RequestSocketSession:(void (^)(id JSON))success
                       failure:(void (^)(NSError *err))failure;

#pragma mark - Submit Operations
- (void) OAuthLoginWithUsername:(NSString*)username password:(NSString*)password success:(void (^)(id JSON))success
                      failure:(void (^)(NSError *err))failure;
- (void) SubscribeToSocketEventsWithAuthToken:(NSString*)token subscriptions:(NSDictionary*)subscriptions success:(void (^)(id JSON))success
                                      failure:(void (^)(NSError* err))failure;
- (void) SubmitConversationWithName:(NSString *)groupName forEntities:(NSArray *)entities creator:(NSString *)creator isGroupConversation:(BOOL)isGroup success:(void (^)(id JSON))success
                            failure:(void (^)(NSError* err))failure;
- (void)SubmitChatMessageForConversation:(NSString*)conversation message:(NSString*)message withEntity:(NSString*)entity withTimestamp:(long)timestamp success:(void (^)(id JSON))success
                                 failure:(void (^)(NSError* err))failure;
- (void) DeleteConversation:(NSString*)conversation success:(void(^)(id JSON, AFHTTPRequestOperation *operation))success
                    failure:(void (^)(NSError*err, AFHTTPRequestOperation *operation))failure;

#pragma mark - Voicemail
- (void) RetrieveVoicemailForEntity:(PersonEntities*)entity success:(void (^)(id JSON))success
                            failure:(void (^)(NSError *err))failure;


- (void) DeleteVoicemail:(Voicemail*)voicemail success:(void (^)(id JSON))success
                 failure:(void (^)(NSError *err))failure;

- (void) UpdateVoicemailToRead:(Voicemail*)voicemail success:(void (^)(id JSON))success
                       failure:(void (^)(NSError *err))failure;

#pragma mark - Update Oparations

- (void) UpdatePresence:(JCPresenceType)presence success:(void (^)(BOOL updated))success failure:(void(^)(NSError *err))failure;

#pragma mark - Class Operations

- (void) clearCookies;
@end
