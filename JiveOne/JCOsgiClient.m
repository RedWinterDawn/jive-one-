//
//  JCOsgiClient.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCOsgiClient.h"
#import "KeychainItemWrapper.h"
#import "PersonEntities+Custom.h"
#import "Voicemail+Custom.h"
#import "Presence+Custom.h"
#import "NSNull+IntValue.h"
#import "Common.h"


#if DEBUG
@interface NSURLRequest(Private)
+(void)setAllowsAnyHTTPSCertificate:(BOOL)inAllow forHost:(NSString *)inHost;
@end
#endif

@implementation JCOsgiClient
{
    KeychainItemWrapper *keyChainWrapper;
    NSManagedObjectContext *localContext;
}



#pragma mark - class initialization

+ (JCOsgiClient*)sharedClient {
    static JCOsgiClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[super alloc] init];
        [_sharedClient initialize];
    });
    return _sharedClient;
}

-(void)initialize
{
    
    //TODO:implement AFCompoundSerializer This is useful for supporting multiple potential types and structures of server responses with a single serializer. @dleonard00 3/14/14
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kOsgiBaseURL, kOsgiURNScheme]];
    _manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    keyChainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
    localContext  = [NSManagedObjectContext MR_contextForCurrentThread];

    

#if DEBUG
    _manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    _manager.securityPolicy.allowInvalidCertificates = YES;
#endif
}

#pragma mark - Retrieve Operations

- (void) RetrieveClientEntitites:(void (^)(id JSON))success
                         failure:(void (^)(NSError *err))failure
{
    [self setRequestAuthHeader];
    
    [_manager GET:kOsgiEntityRoute parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *me = [responseObject objectForKey:@"me"];
        NSArray* entityArray = [responseObject objectForKey:@"entries"];
        [PersonEntities addEntities:entityArray me:me];
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void) RetrieveMyEntitity:(void (^)(id JSON, id operation))success
                    failure:(void (^)(NSError *err, id operation))failure
{
    [self setRequestAuthHeader];
   
    NSString * url = [NSString stringWithFormat:@"%@%@", [_manager baseURL], kOsgiMyEntityRoute];//TODO: not attaching baseURL to route constant
    NSLog(@"%@", url);
    
    [_manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject, operation);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error, operation);
    }];
}

- (void) RetrieveMyCompany:(NSString*)company :(void (^)(id JSON))success
                              failure:(void (^)(NSError *err))failure
{
    [self setRequestAuthHeader];
    
    NSString *url = [NSString stringWithFormat:@"%@%@", [_manager baseURL], company];//TODO: not attaching baseURL to route constant
    [_manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void) RetrieveConversations:(void (^)(id JSON))success
                    failure:(void (^)(NSError *err))failure
{
    
    [self setRequestAuthHeader];
    
    [_manager GET:kOsgiConverationRoute parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [Conversation saveConversationEtag:[responseObject[@"ETag"] integerValue] managedContext:nil];
        [Conversation addConversations:responseObject[@"entries"]];
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", operation.responseString);
        failure(error);
    }];
}

- (void) RetrieveConversationsByConversationId:(NSString*)conversationId success:(void (^)(Conversation * conversation)) success failure:(void (^)(NSError *err))failure
{
    [self setRequestAuthHeader];
    
    NSString *url = [NSString stringWithFormat:@"%@%@", [_manager baseURL], conversationId];//TODO: not attaching baseURL to route constant
    
    [_manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {        ;
        success([Conversation addConversation:responseObject]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)RetrieveEntitiesPresence:(void (^)(BOOL updated))success failure:(void(^)(NSError *err))failure
{
    [self setRequestAuthHeader];
    
    [_manager GET:kOsgiPresenceRoute parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *presences = responseObject[@"entries"];
        [Presence addPresences:presences];
        success(YES);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void) RetrievePresenceForEntity:(NSString*)entity withPresendUrn:(NSString*)presenceUrn success:(void (^)(BOOL updated))success failure:(void(^)(NSError *err))failure
{
    [self setRequestAuthHeader];
    NSString *url = nil;
    if (presenceUrn) {
        url = [NSString stringWithFormat:@"%@%@", [_manager baseURL], presenceUrn];
    }
    else {
        url = [NSString stringWithFormat:@"%@presence:%@", [_manager baseURL], entity];
    }
    
    [_manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (void) RequestSocketSession:(void (^)(id))success failure:(void (^)(NSError *))failure
{
    [self setRequestAuthHeader];
    
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"];
    NSDictionary *params = nil;
    if (deviceToken) {
        params = [NSDictionary dictionaryWithObject:deviceToken forKey:@"deviceToken"];
    }
    
    
    [_manager POST:kOsgiSessionRoute parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

#pragma mark - Submit Operations

- (void) OAuthLoginWithUsername:(NSString*)username password:(NSString*)password success:(void (^)(id JSON))success
                        failure:(void (^)(NSError *err))failure
{
}

- (void) SubscribeToSocketEventsWithAuthToken:(NSString*)token subscriptions:(NSDictionary*)subscriptions success:(void (^)(id JSON))success
                                      failure:(void (^)(NSError* err))failure
{
    
    [self setRequestAuthHeaderWithSocketSessionToken:token];
    
    [_manager POST:kOsgiSubscriptionRoute parameters:subscriptions success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
    
//    NSURL *url = [NSURL URLWithString:@"https://my.jive.com/urn/subscriptions"];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
//    [request setValue:pipedToken forHTTPHeaderField:@"Auth"];
//    request.HTTPMethod = @"POST";
//    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
//    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
//
//    operation.responseSerializer = [AFJSONResponseSerializer serializer];
//    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"%@", responseObject);
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"%@", error);
//    }];
//    
//    
//    [operation start];
    
    

//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:subscriptions options:kNilOptions error:nil];
//    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    NSLog(jsonString);
//    [request setHTTPBody:jsonData];
//    
//    NSURLResponse * response = nil;
//    NSError * error = nil;
//    NSData * data = [NSURLConnection sendSynchronousRequest:request
//                                          returningResponse:&response
//                                                      error:&error];
//    
//    if (error == nil)
//    {
//        NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
//        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//        success(dictionary);
//    }
//    else
//    {
//        failure(error);
//    }
    
    
}

- (void) SubmitConversationWithName:(NSString *)groupName forEntities:(NSArray *)entities creator:(NSString *)creator isGroupConversation:(BOOL)isGroup success:(void (^)(id JSON))success
                            failure:(void (^)(NSError* err))failure
{
    [self setRequestAuthHeader];
    
    NSMutableDictionary * conversationDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:entities, @"entities", creator, @"creator", nil];
    if (isGroup) {
        [conversationDictionary setObject:@"groupconversations" forKey:@"type"];
        [conversationDictionary setObject:groupName forKey:@"name"];
    }
    
    [_manager POST:kOsgiConverationRoute parameters:conversationDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [Conversation addConversation:responseObject];
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)SubmitChatMessageForConversation:(NSString*)conversation message:(NSDictionary*)message withEntity:(NSString*)entity withTimestamp:(long)timestamp withTempUrn:(NSString*)tempUrn success:(void (^)(id JSON))success
                                 failure:(void (^)(NSError* err))failure
{
    [self setRequestAuthHeader];
    
//    NSDictionary *messageDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:message, @"raw", nil];
    NSDictionary *conversationDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:entity, @"entity", conversation, @"conversation", message, @"message", [NSString stringWithFormat: @"%ld", timestamp], @"createdDate", tempUrn, @"tempUrn", nil];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:conversationDictionary options:kNilOptions error:nil];
    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", jsonString);
    
    NSString *urlWithEntry = [NSString stringWithFormat:@"%@%@:entries", [_manager baseURL], conversation];
    
    [_manager POST:urlWithEntry parameters:conversationDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void) DeleteConversation:(NSString*)conversation success:(void(^)(id JSON, AFHTTPRequestOperation *operation))success
                                                             failure:(void (^)(NSError*err, AFHTTPRequestOperation *operation))failure
{
    [self setRequestAuthHeader];
    
    NSString *urlWithConv = [NSString stringWithFormat:@"%@%@", [_manager baseURL], conversation];
    
    [_manager DELETE:urlWithConv parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject, operation);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error, operation);
    }];
}


#pragma mark - Update Operations

- (void) UpdatePresence:(JCPresenceType)presence success:(void (^)(BOOL updated))success failure:(void(^)(NSError *err))failure
{
    NSString *presenceURN = [[JCOmniPresence sharedInstance] me].presence;
    
    NSDictionary *chatCodeDictonary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:presence], @"code", nil];
    NSDictionary *chatDictionary = [NSDictionary dictionaryWithObjectsAndKeys:chatCodeDictonary, @"chat", nil];
    //NSDictionary *iteractionsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:presenceURN, @"urn", chatDictionary, @"iteractions", nil];
    NSDictionary *iteractionsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:chatDictionary, @"interactions", nil];
    //NSDictionary *presenceDictionary = [NSDictionary dictionaryWithObjectsAndKeys:iteractionsDictionary, @"presence", nil];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:iteractionsDictionary options:kNilOptions error:nil];
    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", jsonString);
   
    NSString *url = [NSString stringWithFormat:@"%@%@", [_manager baseURL], presenceURN];
    
    [_manager PATCH:url parameters:iteractionsDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"%@", responseObject);
        [Presence addPresence:responseObject];
        success(YES);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        failure(error);
    }];
    
}

#pragma mark - Class Operations
- (void)setRequestAuthHeaderWithSocketSessionToken:(NSString*)token
{
    KeychainItemWrapper* _keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
    NSString *authtoken = [_keychainWrapper objectForKey:(__bridge id)(kSecAttrAccount)];
    
    if (!authtoken) {
        authtoken = (NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
    }
    
    NSString *pipedToken = [NSString stringWithFormat:@"%@|%@", authtoken, token];
    
    _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [_manager.requestSerializer clearAuthorizationHeader];
    [_manager.requestSerializer setValue:pipedToken forHTTPHeaderField:@"Auth"];
    
}

- (void)setRequestAuthHeader
{
    KeychainItemWrapper* _keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
    NSString *token = [_keychainWrapper objectForKey:(__bridge id)(kSecAttrAccount)];
    
    [self clearCookies];
    
    if (!token) {
        token = (NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
    }
    
    _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [_manager.requestSerializer clearAuthorizationHeader];
    [_manager.requestSerializer setValue:token forHTTPHeaderField:@"Auth"];
}

- (void)clearCookies {
    
    //This will delete ALL cookies. 
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    for (NSHTTPCookie *cookie in [cookieJar cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    
}


#pragma mark - Voicemail

//Retrives all voicemails from the server. Entity object is not used.
- (void) RetrieveVoicemailForEntity:(PersonEntities*)entity success:(void (^)(id JSON))success
                            failure:(void (^)(NSError *err))failure
{
    [self setRequestAuthHeader];
    //https://test.my.jive.com/voicemails
    NSString * url = [NSString stringWithFormat:@"%@%@", [_manager baseURL], kOsgiVoicemailRoute];
    NSLog(@"%@", url);
    
    [_manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [Voicemail saveVoicemailEtag:[responseObject[@"ETag"] integerValue] managedContext:nil];
        NSArray *entries = [responseObject objectForKey:@"entries"];
        //get all voicemail metadata, but not actual voicemail messages
        [Voicemail addVoicemails:entries];
        success(responseObject);
        //get all voicemail messages through a queue
        [Voicemail fetchVoicemailInBackground];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
        failure(error);
     }];
    
}

- (void) DeleteVoicemail:(Voicemail*)voicemail success:(void (^)(id JSON))success
                          failure:(void (^)(NSError *err))failure
{
    [self setRequestAuthHeader];
    NSString *url = [NSString stringWithFormat:@"%@%@", self.manager.baseURL, voicemail.urn];
    
    [_manager DELETE:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void) UpdateVoicemailToRead:(Voicemail*)voicemail success:(void (^)(id JSON))success
                       failure:(void (^)(NSError *err))failure
{
    [self setRequestAuthHeader];
    NSString *url = [NSString stringWithFormat:@"%@%@", self.manager.baseURL, voicemail.urn];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@"true" forKey:@"read"];
    [self.manager PATCH:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        failure(error);
    }];
    
}



#pragma mark - CRUD for Conversation

#pragma mark - CRUD for Presence


#pragma mark - CRUD for Entities

@end
