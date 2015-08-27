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
#import "DID.h"
#import "Contact+V5Client.h"
#import "PBX.h"
#import "Line.h"
#import "ContactGroup+V5Client.h"
#import "JCAuthManager.h"

NSString *const kJCV5ApiClientBaseUrl = @"https://api.jive.com/";

@implementation JCV5ApiClient

#pragma mark - class methods

+ (instancetype)sharedClient {
	static JCV5ApiClient *sharedClient = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedClient = [super new];
	});
	return sharedClient;
}

-(instancetype)init
{
    NSURL *url = [NSURL URLWithString:kJCV5ApiClientBaseUrl];
    return [self initWithBaseURL:url];
}

-(instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        _manager.requestSerializer = [JCBearerAuthenticationJSONRequestSerializer serializer];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    }
    return self;
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

@end
