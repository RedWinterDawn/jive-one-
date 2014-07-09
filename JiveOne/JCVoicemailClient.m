//
//  JCVoicemailClient.m
//  JiveOne
//
//  Created by Daniel George on 6/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailClient.h"
#import "Voicemail+Custom.h"
#import "Mailbox+Custom.h"

@implementation JCVoicemailClient
{
    KeychainItemWrapper *keyChainWrapper;
    NSManagedObjectContext *localContext;
}


#pragma mark - init methods

+ (JCVoicemailClient*)sharedClient {
    static JCVoicemailClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[super alloc] init];
        [_sharedClient initialize];
    });
    return _sharedClient;
}

-(void)initialize
{
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", kVoicemailService]];
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
//get mailbox info and voicemails
-(void)getVoicemails :(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed
{
    [self setRequestAuthHeader];
    
    NSArray* mailboxes = [Mailbox MR_findAll];
    
    [mailboxes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

        Mailbox *mailbox = (Mailbox *)obj;
        NSArray *urlSlit = [mailbox.url_self_mailbox componentsSeparatedByString:@"mailbox/id/"];
        NSString* url = [NSString stringWithFormat:@"%@mailbox/id/014575fe-6ef6-953f-b3a4-000100620002", urlSlit[0]];
        
        if ([url rangeOfString:@"api.jive.com"].location != NSNotFound) {
            NSArray *urlSplit = [url componentsSeparatedByString:@".com/"];
            url = urlSplit[1];
        }
        
        
        
        [_manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [Voicemail addVoicemails:responseObject mailboxUrl:mailbox.url_self_mailbox completed:^(BOOL suceeded) {
                completed(YES, responseObject, operation, nil);
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            completed(NO, nil, operation, error);
        }];
    }];
}

//download actual voicemail
-(void)downloadVoicemailEntry:(NSString*)entryId fromMailbox:(NSString*)mailboxId completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed
{
    NSString* url = [NSString stringWithFormat:@"%@/voicemail/%@/listen", mailboxId, entryId];
         
    [_manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [Voicemail fetchVoicemailInBackground];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completed(NO, nil, operation, error);
    }];
    
}

//update voicemail to read
-(void)updateVoicemailToRead:(Voicemail*)voicemail completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed{
    
    [self setRequestAuthHeader];
    
    NSString *url = [NSString stringWithFormat:@"%@?verify=%@", voicemail.url_changeStatus, [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"]];//TODO: remove when voicemail accepts auth through headers
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@"true" forKey:@"read"];
    
    [self.manager PUT:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completed(YES, responseObject, operation, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        completed(NO, nil, nil, error);
  }];
    
}

//JCRest implementations
//- (void) RetrieveVoicemailForEntity:(PersonEntities*)entity success:(void (^)(id JSON))success
//                            failure:(void (^)(NSError *err))failure
//{
//
//    [self setRequestAuthHeader];
//    NSString * url = [NSString stringWithFormat:@"%@%@", [_manager baseURL], kOsgiVoicemailRoute];
//    NSLog(@"%@", url);
//
//    [_manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//
//        [Voicemail saveVoicemailEtag:[responseObject[@"ETag"] integerValue] managedContext:nil];
//        NSArray *entries = [responseObject objectForKey:@"entries"];
//        //get all voicemail metadata, but not actual voicemail messages
//        [Voicemail addVoicemails:entries completed:^(BOOL succeeded) {
//            success(responseObject);
//        }];
//
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"%@",error);
//        failure(error);
//     }];
//
//}
//
- (void)deleteVoicemail:(NSString *)url completed:(void (^)(BOOL succeeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed
{

    [self setRequestAuthHeader];
    
    url = [NSString stringWithFormat:@"%@?verify=%@",  url, [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"]];//TODO: remove when voicemail accepts auth through headers

    [_manager DELETE:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completed(YES, responseObject, operation, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completed(NO, nil, operation, error);
    }];
    
}

@end
