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
#import <XMLDictionary/XMLDictionary.h>

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
	});
	return _sharedClient;
}

//- (void)initialize
//{
//	
//	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", kv4Provisioning]];
//	_manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
//	_manager.responseSerializer = [AFJSONResponseSerializer serializer];
//	
//	KeychainItemWrapper* _keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
//	localContext  = [NSManagedObjectContext MR_contextForCurrentThread];
//	
//	NSLog(@"About to go into debug mode for server certificate");
//#if DEBUG
//	NSLog(@"Debug mode active");
//	_manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
//	_manager.securityPolicy.allowInvalidCertificates = YES;
//#endif
//}
//
//- (void)setRequestAuthHeader
//{
//	
//	KeychainItemWrapper* _keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
//	NSString *token = [_keychainWrapper objectForKey:(__bridge id)(kSecAttrAccount)];
//	
//	[self clearCookies];
//	
//	if (!token) {
//		token = (NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
//	}
//	
//	_manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
//	[_manager.requestSerializer clearAuthorizationHeader];
//	[_manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];
//	[_manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
//}
//
//- (void)clearCookies {
//	
//	//This will delete ALL cookies.
//	NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//	
//	for (NSHTTPCookie *cookie in [cookieJar cookies]) {
//		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
//	}
//	
//}po

- (void) requestProvisioningFile:(NSString *)payload completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
{
	NSURL *url = [NSURL URLWithString:kv4Provisioning];
	NSData *postData = [payload dataUsingEncoding:NSUTF8StringEncoding];
	
	// Create the request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"POST"];
	[request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:@"Content-Length"];
	//[request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:postData];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		// Peform the request
		NSURLResponse *response;
		NSError *error = nil;
		NSData *receivedData = [NSURLConnection sendSynchronousRequest:request
													 returningResponse:&response
																 error:&error];
		if (error) {
			// Deal with your error
			if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
				NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
				NSLog(@"HTTP Error: %ld %@", (long)httpResponse.statusCode, error);
			}
			NSLog(@"Error %@", error);
			completed(NO, nil, nil, error);
			return;
		}
		
		
		
		@try {
			NSDictionary *response = [NSDictionary dictionaryWithXMLData:receivedData];
			[LineConfiguration addConfiguration:response completed:^(BOOL success) {
				completed(YES, response, nil, nil);
			}];
		}
		@catch (NSException *exception) {
			completed(NO, nil, nil, exception);
		}
	});
}

@end
