//
//  JCV5ApiClient.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient.h"
#import "Common.h"

#import "User.h"

@implementation JCV5ApiClient

#pragma mark - class methods

+ (instancetype)sharedClient {
	static JCV5ApiClient *_sharedClient = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedClient = [[super alloc] init];
		[_sharedClient initialize];
	});
	return _sharedClient;
}

-(void)initialize
{
	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", kV5BaseUrl]];
	_manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
	_manager.responseSerializer = [AFJSONResponseSerializer serializer];
	_manager.requestSerializer = [AFJSONRequestSerializer serializer];
	
	NSLog(@"About to go into debug mode for server certificate");
#if DEBUG
	NSLog(@"Debug mode active");
	_manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
	_manager.securityPolicy.allowInvalidCertificates = YES;
#endif
}


- (void)setRequestAuthHeader:(BOOL) demandsBearer
{
	NSString *token = [JCAuthenticationManager sharedInstance].authToken;
	
	[self clearCookies];
    
	_manager.requestSerializer = [AFJSONRequestSerializer serializer];
	[_manager.requestSerializer clearAuthorizationHeader];
	[_manager.requestSerializer setValue:[NSString stringWithFormat:@"%@%@", demandsBearer? @"Bearer " : @"", token] forHTTPHeaderField:@"Authorization"];
	[_manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
}

- (void)clearCookies {
	
	//This will delete ALL cookies.
	NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	
	for (NSHTTPCookie *cookie in [cookieJar cookies]) {
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
	}
}

- (void) stopAllOperations
{
	[_manager.operationQueue cancelAllOperations];
}

- (BOOL) isOperationRunning:(NSString *)operationName
{
	NSArray *operations = [_manager.operationQueue operations];
	for (AFHTTPRequestOperation *op in operations) {
		if ([op.name isEqualToString:operationName]) {
			return op.isExecuting;
		}
	}
	
	return NO;
}

#pragma mark - Contact API Calls
- (void)RetrieveMyInformation:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed
{
	[self setRequestAuthHeader:YES];
	
	NSString *url = [NSString stringWithFormat:@"/contacts/2014-07/jiveuser/info/jiveid/%@", [JCAuthenticationManager sharedInstance].jiveUserId];
	
	//NSLog(@"%@", url);
	
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
	[self setRequestAuthHeader:YES];
	
	NSArray *pbxs = [PBX MR_findAll];
	
	for (PBX *pbx in pbxs)
    {
		
		NSString *username = [JCAuthenticationManager sharedInstance].jiveUserId;
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(pbxId == %@) AND (userName == %@)", pbx.pbxId, username];
		
		Line *line = [Line MR_findFirstWithPredicate:predicate];
		
		if (line) {
			NSString *url = [NSString stringWithFormat:@"/contacts/2014-07/%@/line/id/%@", line.pbxId, line.lineId];
			
			[_manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
				NSArray *contactArray = (NSArray *)responseObject;
				if (contactArray) {
					[Line addLines:contactArray pbx:pbx completed:^(BOOL succeeded) {
						if (completed) {
							completed(YES, responseObject, operation, nil);
						}
					}];
				}
			} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				if (completed) {
					completed(NO, nil, operation, error);
				}
				
			}];
		}
		
	}
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

#pragma mark - Voicemail API Calls
-(void)getVoicemails :(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed
{
	[self setRequestAuthHeader:NO];
	
	NSPredicate *linesWithUrlNotNil = [NSPredicate predicateWithFormat:@"mailboxUrl != nil"];
	NSArray* lines = [Line MR_findAllWithPredicate:linesWithUrlNotNil];
	__block BOOL succeededGettingAtLeastOne = NO;
	
	[lines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		
		Line *line = (Line *)obj;
		
		if (line.mailboxUrl && ![Common stringIsNilOrEmpty:line.mailboxUrl]) {
			[_manager GET:line.mailboxUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
				[Voicemail addVoicemails:responseObject mailboxUrl:line.mailboxUrl completed:^(BOOL suceeded) {
					succeededGettingAtLeastOne = YES;
					if (completed) {
						completed(YES, responseObject, operation, nil);
					}
				}];
				
				
			} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				if ((lines.count -1) == idx) {
					if (succeededGettingAtLeastOne) {
						if (completed) {
							completed(YES, nil, operation, error);
						}
					}
					else {
						if (completed) {
							completed(NO, nil, operation, error);
						}
					}
				}
			}];
		}
	}];
}

//download actual voicemail
//-(void)downloadVoicemailEntry:(Voicemail*)voicemail completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed
//{
//	[self setRequestAuthHeader:NO];
//	
//	if (![Common stringIsNilOrEmpty:voicemail.url_changeStatus]) {
//		[_manager GET:voicemail.url_download parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//			
//			[Voicemail fetchAllVoicemailDataInBackground];
//			
//		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//			completed(NO, nil, operation, error);
//		}];
//	}
//}

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

- (void)deleteVoicemail:(NSString *)url completed:(void (^)(BOOL succeeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed
{
	
	[self setRequestAuthHeader:NO];
	
	
	[_manager DELETE:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		completed(YES, responseObject, operation, nil);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		completed(NO, nil, operation, error);
	}];
}

#pragma mark - JIF API Calls -

NSString *const JCV5ApiClientUserPbxInfoRequestPath = @"/jif/v1/user/jiveId/%@?depth=1";
NSString *const JCV5APIClientUserPbxInfoRequestResultKey = @"userPbxs";

+ (void)getPbxInformationForUser:(User *)user completed:(void(^)(BOOL success, NSArray *pbxs, NSError *error))completion
{
    if (!user) {
        [NSException raise:NSInvalidArgumentException format:@"User is Nil"];
    }
    
    JCV5ApiClient *client = [JCV5ApiClient sharedClient];
    [client setRequestAuthHeader:NO];
    [client.manager GET:[NSString stringWithFormat:JCV5ApiClientUserPbxInfoRequestPath, user.jiveUserId]
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    if ([responseObject isKindOfClass:[NSDictionary class]])
                    {
                        NSDictionary *result = (NSDictionary *)responseObject;
                        id object = [result objectForKey:JCV5APIClientUserPbxInfoRequestResultKey];
                        if ([object isKindOfClass:[NSArray class]])
                        {
                            [PBX addPBXs:(NSArray *)object user:user completed:completion];
                        }
                        else {
                            completion(NO, nil, [NSError errorWithDomain:NSInvalidArgumentException code:0 userInfo:nil]);
                        }
                    }
                    else
                    {
                        completion(NO, nil, [NSError errorWithDomain:NSInvalidArgumentException code:0 userInfo:nil]);
                    }
                }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    completion(NO, nil, error);
                }];
}


@end
