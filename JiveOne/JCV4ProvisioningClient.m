//
//  JCV4ProvisioningClient.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCV4ProvisioningClient.h"
#import "Common.h"
#import "LineConfiguration+Custom.h"

@implementation JCV4ProvisioningClient
{
	KeychainItemWrapper *keyChainWrapper;
	NSManagedObjectContext *localContext;
}
+ (JCV4ProvisioningClient*)sharedClient {
	static JCV4ProvisioningClient *_sharedClient = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedClient = [[super alloc] init];
		[_sharedClient initialize];
	});
	return _sharedClient;
}

- (void)initialize
{
	
	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", kv4Provisioning]];
	_manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
	_manager.responseSerializer = [AFJSONResponseSerializer serializer];
	
	KeychainItemWrapper* _keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
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
	
	_manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
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

- (void) requestProvisioningFile:(NSDictionary *)payload completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_manager.baseURL];
	NSString *error;
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:payload format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];

	request.HTTPBody = data;
	request.HTTPMethod = @"POST";
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
 
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
 
	// Make sure to set the responseSerializer correctly
	operation.responseSerializer = [AFXMLParserResponseSerializer serializer];
	
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		completed(YES, responseObject, operation, nil);
		
		//TODO parse XML, save in database:
		
		[LineConfiguration addConfiguration:nil completed:^(BOOL success) {
			//TODO wow.
		}];
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		completed(NO, nil, operation, error);
	}];
}

@end
