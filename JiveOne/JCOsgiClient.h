//
//  JCOsgiClient.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import "ConversationEntry.h"
#import "Conversation.h"
#import "ConversationEntry.h"
#import "Presence.h"
#import "ClientEntities.h"

@interface JCOsgiClient : NSObject

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

//for Voicemanil
@property (nonatomic, strong) AFHTTPRequestOperationManager *tempManager;

+ (instancetype)sharedClient;

- (void) RetrieveClientEntitites:(void (^)(id JSON))success
                            failure:(void (^)(NSError *err))failure;

- (void) RetrieveMyEntitity:(void (^)(id JSON))success
                    failure:(void (^)(NSError *err))failure;

- (void) RetrieveMyCompany:(NSString*)company :(void (^)(id JSON))success
                    failure:(void (^)(NSError *err))failure;

- (void) RetrieveConversations:(void (^)(id JSON))success
                       failure:(void (^)(NSError *err))failure;

- (void) RetrieveConversationsByConversationId:(NSString*)conversationId success:(void (^)(Conversation * conversation)) success failure:(void (^)(NSError *err))failure;


- (void) RequestSocketSession:(void (^)(id JSON))success
                       failure:(void (^)(NSError *err))failure;

- (void) OAuthLoginWithUsername:(NSString*)username password:(NSString*)password success:(void (^)(id JSON))success
                      failure:(void (^)(NSError *err))failure;

- (void) SubscribeToSocketEventsWithAuthToken:(NSString*)token subscriptions:(NSDictionary*)subscriptions success:(void (^)(id JSON))success
                                      failure:(void (^)(NSError* err))failure;

- (void) SubmitChatMessageForConversation:(NSString*)conversation message:(NSString*)message withEntity:(NSString*)entity success:(void (^)(id JSON))success
                                 failure:(void (^)(NSError* err))failure;

- (void)RetrieveEntitiesPresence:(void (^)(BOOL updated))success failure:(void(^)(NSError *err))failure;


- (void) RetrievePresenceForEntity:(NSString*)entity withPresendUrn:(NSString*)presenceUrn success:(void (^)(BOOL updated))success failure:(void(^)(NSError *err))failure;

- (void) UpdatePresence:(JCPresenceType)presence success:(void (^)(BOOL updated))success failure:(void(^)(NSError *err))failure;

- (void) clearCookies;

#pragma mark - CRUD for Conversation
- (void)addConversations:(NSArray*)conversationArray;
- (Conversation *)addConversation:(NSDictionary*)conversation;
- (Conversation *)updateConversation:(Conversation*)conversation withDictinonary:(NSDictionary*)dictionary;

#pragma mark - CRUD for ConversationEntry
- (void)addConversationEntries:(NSArray *)entryArray;
- (ConversationEntry *)addConversationEntry:(NSDictionary*)entry;
- (ConversationEntry *)updateConversationEntry:(ConversationEntry*)entry withDictionary:(NSDictionary*)dictionary;

#pragma mark - CRUD for Presence
- (void)addPresences:(NSArray*)presences;
- (Presence *)addPresence:(NSDictionary*)presence;
- (Presence *)updatePresence:(Presence *)presence dictionary:(NSDictionary *)dictionary;

@end
