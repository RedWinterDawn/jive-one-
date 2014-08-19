//
//  JCContactsClient.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCContactsClient.h"
#import "PBX+Custom.h"
#import "Lines+Custom.h"
#import "Membership+Custom.h"
#import "Common.h"

@implementation JCContactsClient
{
    KeychainItemWrapper *keyChainWrapper;
    NSManagedObjectContext *localContext;
}

#pragma mark - class methods

+ (JCContactsClient*)sharedClient {
    static JCContactsClient *_sharedClient = nil;
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
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", kContactsService]];
    _manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    //_manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
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
    
//    KeychainItemWrapper* _keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
//    NSString *token = [_keychainWrapper objectForKey:(__bridge id)(kSecAttrAccount)];
	
	NSString *token = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
    
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

#pragma mark - class methods

- (void)RetrieveMyInformation:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed
{
    [self setRequestAuthHeader];
    
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:kUserName];
    NSString *url = [NSString stringWithFormat:@"https://api.jive.com/contacts/2014-07/jiveuser/info/jiveid/%@", username];
    
    NSLog(@"%@", url);
    
    [_manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [Membership addMemberships:responseObject completed:^(BOOL suceeded) {
            completed(YES, responseObject, operation, nil);
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completed(NO, nil, operation, error);
    }];
}

- (void)RetrieveContacts:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed
{
    [self setRequestAuthHeader];
    
	NSArray *pbxs = [PBX MR_findAll];
	
	for (PBX *pbx in pbxs) {
		
		NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(pbxId == %@) AND (userName == %@)", pbx.pbxId, username];
		
		Lines *line = [Lines MR_findFirstWithPredicate:predicate];
		
		if (line) {
			NSString *url = [NSString stringWithFormat:@"https://api.jive.com/contacts/2014-07/%@/line/id/%@", line.pbxId, line.lineId];
			
			[_manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
				NSArray *contactArray = (NSArray *)responseObject;
				if (contactArray) {
					[Lines addLines:contactArray pbxId:line.pbxId userName:nil completed:^(BOOL succeeded) {
						completed(YES, responseObject, operation, nil);
					}];
				}
			} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				completed(NO, nil, operation, error);
			}];
		}
		
	}
	
	
    
}

- (void)SubscribeToSocketEvents:(NSString *)subscriptionURL dataDictionary:(NSDictionary *)dataDictionary
{
    [self setRequestAuthHeader];
    
	if (![Common stringIsNilOrEmpty:subscriptionURL]) {
		[_manager POST:subscriptionURL parameters:dataDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
			NSLog(@"Success");
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			NSLog(@"Error Subscribing %@", error);
			// boo!
		}];
	}   
}

- (void) RequestSocketSession:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed
{
    
    [self setRequestAuthHeader];
    
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:UDdeviceToken];
    NSDictionary *params = nil;
    if (deviceToken) {
        params = [NSDictionary dictionaryWithObject:deviceToken forKey:UDdeviceToken];
    }
    
    NSString *sessionURL = @"https://realtime.jive.com/session";
    
    [_manager POST:sessionURL parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completed(YES, responseObject, operation, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completed(NO, nil, operation, error);
    }];
}


@end
