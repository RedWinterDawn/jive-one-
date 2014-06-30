//
//  JCJifClient.m
//  JiveOne
//
//  Created by Daniel George on 6/26/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCJifClient.h"
#import "Mailbox+Custom.h"

@implementation JCJifClient
{
    KeychainItemWrapper *keyChainWrapper;
    NSManagedObjectContext *localContext;
}


#pragma mark - init methods

+ (JCJifClient*)sharedClient {
    static JCJifClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[super alloc] init];
        [_sharedClient initialize];
    });
    return _sharedClient;
}

-(void)initialize
{

    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", kJifService]];
    _manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    keyChainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
    localContext  = [NSManagedObjectContext MR_contextForCurrentThread];
    
    NSLog(@"About to go into debug mode for server certificate");
#if DEBUG
    NSLog(@"Debug mode active");
    _manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    _manager.securityPolicy.allowInvalidCertificates = YES;
#endif
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
    [_manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];
    [_manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
}

- (void)clearCookies {
    
    //This will delete ALL cookies.
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    for (NSHTTPCookie *cookie in [cookieJar cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    
}

#pragma mark - Rest Calls
-(void)getMailboxReferencesForUser:(NSString*)jiveId :(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed
{
    [self setRequestAuthHeader];
    NSString* url = [NSString stringWithFormat:@"jiveId/%@", jiveId];
    [_manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //parse list of mailbox references
        [Mailbox addMailboxes:responseObject  completed:^(BOOL suceeded) {
            completed(YES, responseObject, operation, nil);
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completed(NO, nil, operation, error);
    }];
    
}

@end
