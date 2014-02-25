//
//  JCOsgiClient.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCOsgiClient.h"
#import "KeychainItemWrapper.h"

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

- (void) RetrieveClientEntitites:(void (^)(id JSON))success
                         failure:(void (^)(NSError *err))failure
{
    [self setRequestAuthHeader];
    
    [_manager GET:kOsgiEntityRoute parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void) RetrieveMyEntitity:(void (^)(id JSON))success
                         failure:(void (^)(NSError *err))failure
{
    [self setRequestAuthHeader];
   
    NSString * url = [NSString stringWithFormat:@"%@%@", [_manager baseURL], kOsgiMyEntityRoute];//TODO: not attaching baseURL to route constant
    NSLog(@"%@", url);
    
    [_manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
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
        [self addConversations:responseObject[@"entries"]];
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", operation.responseString);
        failure(error);
    }];
}

- (void) RetrieveConversationsByConverationId:(NSString*)conversationId success:(void (^)(Conversation * conversation)) success failure:(void (^)(NSError *err))failure
{
    [self setRequestAuthHeader];
    
    NSString *url = [NSString stringWithFormat:@"%@%@", [_manager baseURL], conversationId];//TODO: not attaching baseURL to route constant
    
    [_manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {        ;
        success([self addConversation:responseObject]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void) OAuthLoginWithUsername:(NSString*)username password:(NSString*)password success:(void (^)(id JSON))success
                        failure:(void (^)(NSError *err))failure
{
}


- (void) RequestSocketSession:(void (^)(id))success failure:(void (^)(NSError *))failure
{
    [self setRequestAuthHeader];
    
    [_manager POST:kOsgiSessionRoute parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
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
    
    if (!token) {
        token = (NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
    }
    
    _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [_manager.requestSerializer clearAuthorizationHeader];
    [_manager.requestSerializer setValue:token forHTTPHeaderField:@"Auth"];
}

- (void)SubmitChatMessageForConversation:(NSString*)conversation message:(NSString*)message withEntity:(NSString*)entity success:(void (^)(id JSON))success
                                 failure:(void (^)(NSError* err))failure
{
    [self setRequestAuthHeader];
    
    NSDictionary *messageDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:message, @"raw", nil];
    NSDictionary *conversationDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:entity, @"entity", conversation, @"conversation", messageDictionary, @"message", nil];
    
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

- (void)RetrieveEntitiesPresence:(void (^)(BOOL updated))success failure:(void(^)(NSError *err))failure
{
    [self setRequestAuthHeader];
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

- (void) UpdatePresence:(JCPresenceType)presence success:(void (^)(BOOL updated))success failure:(void(^)(NSError *err))failure
{
    NSString *presenceURN = [[JCOmniPresence sharedInstance] me].presence;
    
    NSDictionary *chatDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:presence], @"chat", nil];
    NSDictionary *iteractionsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:presenceURN, @"urn", chatDictionary, @"iteractions", nil];
    NSDictionary *presenceDictionary = [NSDictionary dictionaryWithObjectsAndKeys:iteractionsDictionary, @"presence", nil];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:presenceDictionary options:kNilOptions error:nil];
    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", jsonString);
   
    NSString *url = [NSString stringWithFormat:@"%@%@", [_manager baseURL], presenceURN];
    
    [_manager PATCH:url parameters:presenceDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        [self addPresence:responseObject];
        success(YES);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        failure(error);
    }];
    
}

- (void)clearCookies {
    
    //This will delete ALL cookies. 
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    for (NSHTTPCookie *cookie in [cookieJar cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    
}

#pragma mark - CRUD for Conversation
- (void)addConversations:(NSArray *)conversationArray
{
    for (NSDictionary *conversation in conversationArray) {
        [self addConversation:conversation];
    }
}

- (Conversation *)addConversation:(NSDictionary *)conversation
{
    // check if we already have that conversation
    NSArray *result = [Conversation MR_findByAttribute:@"conversationId" withValue:conversation[@"id"]];
    Conversation *conv;
    if (result.count > 0) {
        conv = result[0];
        [self updateConversation:conv withDictinonary:conversation];
    }
    else {
        if ([conversation[@"entries"] count] > 0) {
            
            conv = [Conversation MR_createInContext:localContext];
            conv.createdDate = conversation[@"createdDate"];
            conv.lastModified = conversation[@"lastModified"];
            conv.urn = conversation[@"urn"];
            conv.conversationId = conversation[@"id"];
            
            if (conversation[@"group"] && conversation[@"name"]) {
                conv.isGroup = [NSNumber numberWithBool:YES];
                conv.group = conversation[@"group"];
                conv.name = conversation[@"name"];
                //conv.conversationId = conversation[@"groupId"];
            }
            else {
                //conv.conversationId = conversation[@"_id"];
                conv.entities = conversation[@"entities"];
            }
            
            // Save conversation
            [localContext MR_saveToPersistentStoreAndWait];
            
            [self addConversationEntries:conversation[@"entries"]];
        }
    }
    return conv;
}

- (Conversation *)updateConversation:(Conversation*)conversation withDictinonary:(NSDictionary*)dictionary
{
    //conversation.createdDate = dictionary[@"createdDate"];
    conversation.lastModified = dictionary[@"lastModified"];
    //conversation.urn = dictionary[@"urn"];
    //conversation.conversationId = dictionary[@"id"];
    
    if (dictionary[@"group"] && dictionary[@"name"]) {
        conversation.isGroup = [NSNumber numberWithBool:YES];
        conversation.group = dictionary[@"group"];
        conversation.name = dictionary[@"name"];
        //conv.conversationId = conversation[@"groupId"];
    }
    else {
        //conv.conversationId = conversation[@"_id"];
        conversation.entities = dictionary[@"entities"];
    }
    
    // Save conversation
    [localContext MR_saveToPersistentStoreAndWait];
    
    // Save/Update entries
    [self addConversationEntries:dictionary[@"entries"]];
    
    return conversation;
}



#pragma mark - CRUD for ConversationEntry
- (void)addConversationEntries:(NSArray *)entryArray
{
    for (NSDictionary *entry in entryArray) {
        if ([entry isKindOfClass:[NSDictionary class]]) {
            [self addConversationEntry:entry];
        }        
    }
}
    
- (ConversationEntry *)addConversationEntry:(NSDictionary*)entry
{
    ConversationEntry *convEntry;
    NSString *entryId =  entry[@"id"];
    NSArray *result = [ConversationEntry MR_findByAttribute:@"entryId" withValue:entryId];
    
    // if there are results, we're updating, else we're creating
    if (result.count > 0) {
        convEntry = result[0];
        [self updateConversationEntry:convEntry withDictionary:entry];
    }
    else {
        convEntry = [ConversationEntry MR_createInContext:localContext];
        convEntry.conversationId = entry[@"conversation"];
        convEntry.entityId = entry[@"entity"];
        convEntry.lastModified = entry[@"lastModified"];
        convEntry.createdDate = entry[@"createDate"];
        convEntry.call = entry[@"call"];
        convEntry.file = entry[@"file"];
        convEntry.message = entry[@"message"];
        convEntry.mentions = entry[@"mentions"];
        convEntry.tags = entry[@"tags"];
        convEntry.deliveryDate = entry[@"deliveryDate"];
        convEntry.type = entry[@"type"];
        convEntry.urn = entry[@"urn"];
        convEntry.entryId = entry[@"id"];
        
        //Save conversation entry
        [localContext MR_saveToPersistentStoreAndWait];
    }
    return convEntry;
}

- (ConversationEntry *)updateConversationEntry:(ConversationEntry*)entry withDictionary:(NSDictionary*)dictionary
{
    // if last modified timestamps are the same, then there's no need to update anything.
    int lastModifiedFromEntity = [entry.lastModified integerValue];
    int lastModifiedFromDictionary = [dictionary[@"lastModified"] integerValue];
    
    if (lastModifiedFromDictionary != lastModifiedFromEntity) {
    
        entry.conversationId = dictionary[@"conversation"];
        entry.entityId = dictionary[@"entity"];
        entry.lastModified = dictionary[@"lastModified"];
        entry.createdDate = dictionary[@"createDate"];
        entry.call = dictionary[@"call"];
        entry.file = dictionary[@"file"];
        entry.message = dictionary[@"message"];
        entry.mentions = dictionary[@"mentions"];
        entry.tags = dictionary[@"tags"];
        entry.deliveryDate = dictionary[@"deliveryDate"];
        entry.type = dictionary[@"type"];
        entry.urn = dictionary[@"urn"];
        entry.entryId = dictionary[@"id"];
        
        //Save conversation entry
        [localContext MR_saveToPersistentStoreAndWait];
        
    }
    
    return entry;
}


#pragma mark - Voicemail

//Here is where doug is trying to make requests for voicemail - while currently we are just grabbing a file from dropbox eventually we will get it from osgi.
- (IBAction)grabURLInBackground:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/u/57157576/data/54321-123.m4a"];

}

#pragma mark - CRUD for Presence

- (Presence *)addPresence:(NSDictionary*)presence
{
    NSString *presenceId = presence[@"id"];
    NSArray *result = [Presence MR_findByAttribute:@"presenceId" withValue:presenceId];
    Presence *pres = nil;
    
    if (result.count > 0) {
        pres = result[0];
        [self updatePresence:pres dictionary:presence];
    }
    else
    {
        pres = [Presence MR_createInContext:localContext];
        pres.entityId = presence[@"entity"];
        pres.lastModified = presence[@"lastModified"];
        pres.createDate = presence[@"createDate"];
        pres.interactions = presence[@"interactions"];
        //pres.urn = presence[@"urn"];
        pres.presenceId = presence[@"id"];
        [localContext MR_saveToPersistentStoreAndWait];
    }
    
    return pres;
}

- (Presence *)updatePresence:(Presence *)presence dictionary:(NSDictionary *)dictionary
{
    presence = [Presence MR_createInContext:localContext];
    presence.entityId = dictionary[@"entity"];
    presence.lastModified = dictionary[@"lastModified"];
    //presence.createDate = dictionary[@"createDate"];
    presence.interactions = dictionary[@"interactions"];
    //pres.urn = presence[@"urn"];
    //presence.presenceId = dictionary[@"id"];
    [localContext MR_saveToPersistentStoreAndWait];
    
    return presence;
}

@end
