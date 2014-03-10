//
//  JCVoicemailClient.m
//  JiveOne
//
//  Created by Daniel George on 3/7/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailClient.h"
#import "KeychainItemWrapper.h"
#import "JCOmniPresence.h"
#import "Company.h"

@interface JCVoicemailClient()
@property  (strong, nonatomic) NSArray *extensions;
@property (strong, nonatomic) NSArray *voiceMail;

@end

@implementation JCVoicemailClient
{
    KeychainItemWrapper *keyChainWrapper;
    NSManagedObjectContext *localContext;
}

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
    //what are these? -DG
    keyChainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
    localContext  = [NSManagedObjectContext MR_contextForCurrentThread];
    
    //For voicemail
    NSURL *voicemailOnV4compat = [NSURL URLWithString:[NSString stringWithFormat:@"%@", kVoicemaiBaseURL]];
    _manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:voicemailOnV4compat];
    
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
#warning REMOVE BEFORE PRODUCTION. This is meant to work with invalid certificates (local/testing.my.jive.com)
    //#if DEBUG
    _manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    _manager.securityPolicy.allowInvalidCertificates = YES;
    
    //#endif
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

//fetch all extensions related to this users pbxId and userId
-(void)fetchExtensions:(void (^)(id JSON))success
               failure:(void (^)(NSError *err))failure{
    
    [self setRequestAuthHeader];


    //TODO: check if the extensions exist in Core data
    //else get from server
    NSString *userId = [[JCOmniPresence sharedInstance] me].externalId;
    NSString *pbxId = [[JCOmniPresence sharedInstance] me].entityCompany.pbxId;
    

    [self.manager GET:[NSString stringWithFormat:kVoicemailFetchRoute, pbxId, userId ] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
//        NSArray * extensionsAndVMBIDs = [responseObject objectForKey:@""];
        //TODO: save extensionNumbers and voicemailbox id's to core data, so that we don't have to fetch every time
        
        success(responseObject);
        NSLog(@"%@", responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];

    
}

-(void)fetchVoiceMails:(void (^)(id JSON))success
               failure:(void (^)(NSError *err))failure
{
    
    }

@end
