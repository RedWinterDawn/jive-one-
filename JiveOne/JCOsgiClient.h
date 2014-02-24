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

@interface JCOsgiClient : NSObject

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

+ (instancetype)sharedClient;

- (void) RetrieveClientEntitites:(void (^)(id JSON))success
                            failure:(void (^)(NSError *err))failure;

- (void) RetrieveMyEntitity:(void (^)(id JSON))success
                    failure:(void (^)(NSError *err))failure;

- (void) RetrieveMyCompany:(NSString*)company :(void (^)(id JSON))success
                    failure:(void (^)(NSError *err))failure;

- (void) RetrieveConversations:(void (^)(id JSON))success
                       failure:(void (^)(NSError *err))failure;

- (void) RetrieveConversationsByConverationId:(NSString*)conversationId success:(void (^)(Conversation * conversation)) success failure:(void (^)(NSError *err))failure;


- (void) RequestSocketSession:(void (^)(id JSON))success
                       failure:(void (^)(NSError *err))failure;

- (void) OAuthLoginWithUsername:(NSString*)username password:(NSString*)password success:(void (^)(id JSON))success
                      failure:(void (^)(NSError *err))failure;

- (void) SubscribeToSocketEventsWithAuthToken:(NSString*)token subscriptions:(NSDictionary*)subscriptions success:(void (^)(id JSON))success
                                      failure:(void (^)(NSError* err))failure;

- (void) SubmitChatMessageForConversation:(NSString*)conversation message:(NSString*)message withEntity:(NSString*)entity success:(void (^)(id JSON))success
                                 failure:(void (^)(NSError* err))failure;
- (void) clearCookies;

#pragma mark - CRUD for Conversation
- (void)addConversations:(NSArray*)conversationArray;
- (Conversation *)addConversation:(NSDictionary*)conversation;
- (Conversation *)updateConversation:(Conversation*)conversation withDictinonary:(NSDictionary*)dictionary;

#pragma mark - CRUD for ConversationEntry
- (void)addConversationEntries:(NSArray *)entryArray;
- (ConversationEntry *)addConversationEntry:(NSDictionary*)entry;
- (ConversationEntry *)updateConversationEntry:(ConversationEntry*)entry withDictionary:(NSDictionary*)dictionary;
@end
