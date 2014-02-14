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
    
    [_manager GET:kOsgiMyEntityRoute parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", operation.responseString);
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



@end
