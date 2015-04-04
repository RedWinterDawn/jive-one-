//
//  JCV5ApiClient.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient.h"
#import "Common.h"
#import "Voicemail.h"
#import "User.h"

#import "JCAuthenticationManager.h"

NSString *const kV5BaseUrl = @"https://api.jive.com/";

@implementation JCV5ApiClient

#pragma mark - class methods

+ (instancetype)sharedClient {
	static JCV5ApiClient *sharedClient = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedClient = [[super alloc] init];
	});
	return sharedClient;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        _manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:kV5BaseUrl]];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
        #if DEBUG
        _manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        _manager.securityPolicy.allowInvalidCertificates = YES;
        #endif
    }
    return self;
}


- (void)setRequestAuthHeader:(BOOL) demandsBearer
{
	[self clearCookies];
    
	_manager.requestSerializer = [AFJSONRequestSerializer serializer];
	[_manager.requestSerializer clearAuthorizationHeader];
    
    NSString *token = [JCAuthenticationManager sharedInstance].authToken;
	[_manager.requestSerializer setValue:[NSString stringWithFormat:@"%@%@", demandsBearer? @"Bearer " : @"", token] forHTTPHeaderField:@"Authorization"];
	[_manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
}

- (void)clearCookies {
	NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	for (NSHTTPCookie *cookie in [cookieJar cookies]) {
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
	}
}

- (void)stopAllOperations
{
	[_manager.operationQueue cancelAllOperations];
}

- (BOOL)isOperationRunning:(NSString *)operationName
{
	NSArray *operations = [_manager.operationQueue operations];
	for (AFHTTPRequestOperation *op in operations) {
		if ([op.name isEqualToString:operationName]) {
			return op.isExecuting;
		}
	}
	return NO;
}

#pragma mark - Socket API Calls

- (void)SubscribeToSocketEvents:(NSString *)subscriptionURL dataDictionary:(NSDictionary *)dataDictionary
{
	[self setRequestAuthHeader:NO];
	
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
	[self setRequestAuthHeader:NO];
	
    NSString *deviceToken = [JCAuthenticationManager sharedInstance].deviceToken;
	NSString *sessionURL = @"https://realtime.jive.com/session";
	
	[_manager POST:sessionURL
        parameters:@{@"deviceToken": deviceToken}
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               completed(YES, responseObject, operation, nil);
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               completed(NO, nil, operation, error);
           }];
}

//update voicemail to read
-(void)updateVoicemailToRead:(Voicemail*)voicemail completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed{
    
    [self setRequestAuthHeader:NO];
    
    NSString *url = [NSString stringWithFormat:@"%@", voicemail.url_changeStatus];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@"true" forKey:@"read"];
    
    if (![Common stringIsNilOrEmpty:url]) {
        [self.manager PUT:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            completed(YES, responseObject, operation, nil);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"%@", error);
            completed(NO, nil, nil, error);
        }];
    }
}

- (void)deleteVoicemail:(NSString *)url completed:(void (^)(BOOL succeeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed {
    
    [self setRequestAuthHeader:NO];
    
    
    [_manager DELETE:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completed(YES, responseObject, operation, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completed(NO, nil, operation, error);
    }];
}

@end

@implementation JCV5ApiClientError

+(instancetype)errorWithCode:(JCV5ApiClientErrorCode)code reason:(NSString *)reason
{
    return [JCV5ApiClientError errorWithDomain:@"JCV5ApiClientError" code:code userInfo:@{NSLocalizedDescriptionKey: reason}];
}

@end
