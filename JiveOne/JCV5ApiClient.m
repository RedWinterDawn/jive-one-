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
#import "JCAuthenticationManager.h"

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

#pragma mark - PBX Info -

#ifndef PBX_INFO_NUMBER_OF_TRIES
#define PBX_INFO_SEND_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ApiPBXInfoRequestPath = @"/jif/v3/user/jiveId/%@";

+ (void)requestPBXInforForUser:(User *)user competion:(JCApiClientCompletionHandler)completion
{
    if (!user) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"User Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiPBXInfoRequestPath, user.jiveUserId];
    [self getWithPath:path
           parameters:nil
    requestSerializer:nil
              retries:PBX_INFO_SEND_NUMBER_OF_TRIES
           completion:completion];
}

#pragma mark - Jedi -

#ifndef GET_JEDI_IDENTIFIER_NUMBER_OF_TRIES
#define GET_JEDI_IDENTIFIER_NUMBER_OF_TRIES 1
#endif

#ifndef UPDATE_JEDI_TOKEN_NUMBER_OF_TRIES
#define UPDATE_JEDI_TOKEN_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ApiJediIdentifierRequestPath = @"/jedi/v1/subscription/ios/%@";
NSString *const kJCV5ApiJediUpdatePath            = @"/jedi/v1/%@/%@";

+ (void)requestJediIdForDeviceToken:(NSString *)deviceToken completion:(JCApiClientCompletionHandler)completion
{
    if (!deviceToken) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Device Token Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiJediIdentifierRequestPath, deviceToken];
    [self postWithPath:path
            parameters:nil
     requestSerializer:[JCAuthenticationJSONRequestSerializer new]
               retries:GET_JEDI_IDENTIFIER_NUMBER_OF_TRIES
            completion:completion];
}

+ (void)updateJediFromOldDeviceToken:(NSString *)oldDeviceToken toNewDeviceToken:(NSString *)newDeviceToken completion:(JCApiClientCompletionHandler)completion
{
    if (!oldDeviceToken) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Old Device Token Is Null"]);
        }
        return;
    }
    
    if (!newDeviceToken) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"New Device Token Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiJediUpdatePath, oldDeviceToken, newDeviceToken];
    [self putWithPath:path
           parameters:nil
    requestSerializer:[JCAuthenticationJSONRequestSerializer new]
              retries:UPDATE_JEDI_TOKEN_NUMBER_OF_TRIES
           completion:completion];
}


#pragma mark - Jasmine -

#ifndef GET_JASMINE_PRIORITY_SESSION_NUMBER_OF_TRIES
#define GET_JASMINE_PRIORITY_SESSION_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ClientSocketBaseURL           = @"https://realtime.jive.com";
NSString *const kJCV5ClientSocketSessionRequestURL = @"/v2/session/priority/jediId/%@";

+ (void)requestPrioritySessionForJediId:(NSString *)jediId completion:(JCApiClientCompletionHandler)completion
{
    if (!jediId) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Jedi ID Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ClientSocketSessionRequestURL, jediId];
    JCV5ApiClient *client = [[JCV5ApiClient alloc] initWithBaseURL:[NSURL URLWithString:kJCV5ClientSocketBaseURL]];
    [client requestWithType:JCApiClientPost
                       path:path parameters:nil
          requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
         responceSerializer:nil
                    retries:GET_JASMINE_PRIORITY_SESSION_NUMBER_OF_TRIES
                    success:^(id responseObject) {
                        if (completion) {
                            completion(YES, responseObject, nil);
                        }
                    }
                    failure:^(id responseObject, NSError *error) {
                        if (completion) {
                            completion(NO, responseObject, error);
                        }
                    }];
}

#pragma mark - Internal Contacts -

#ifndef GET_EXTENSIONS_NUMBER_OF_TRIES
#define GET_EXTENSIONS_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ApiExtensionsRequestPath = @"/contacts/2014-07/%@/line/id/%@";

+ (void)downloadInternalExtensionsForLine:(Line *)line completion:(JCApiClientCompletionHandler)completion
{
    if (!line) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Line Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiExtensionsRequestPath, line.pbx.pbxId, line.lineId];
    [self getWithPath:path
           parameters:nil
    requestSerializer:nil
              retries:GET_EXTENSIONS_NUMBER_OF_TRIES
           completion:completion];
}

#pragma mark - Contacts -

#ifndef GET_CONTACTS_NUMBER_OF_TRIES
#define GET_CONTACTS_NUMBER_OF_TRIES 1
#endif

#ifndef UPLOAD_CONTACT_NUMBER_OF_TRIES
#define UPLOAD_CONTACT_NUMBER_OF_TRIES 1
#endif

#ifndef DELETE_CONTACT_NUMBER_OF_TRIES
#define DELETE_CONTACT_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ApiContactsDownloadRequestPath = @"/contacts/v3/user/contacts";
NSString *const kJCV5ApiContactDownloadRequestPath  = @"/contacts/v3/user/contact/%@";
NSString *const kJCV5ApiContactUploadRequestPath    = @"/contacts/v3/user/contact";

+ (void)downloadContactsWithCompletion:(JCApiClientCompletionHandler)completion
{
    [self getWithPath:kJCV5ApiContactsDownloadRequestPath
           parameters:nil
    requestSerializer:nil
              retries:GET_CONTACTS_NUMBER_OF_TRIES
           completion:completion];
}

+ (void)downloadContact:(Contact *)contact completion:(JCApiClientCompletionHandler)completion
{
    if (!contact) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Contact Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiContactDownloadRequestPath, contact.contactId];
    [self getWithPath:path
           parameters:nil
    requestSerializer:nil
              retries:GET_CONTACTS_NUMBER_OF_TRIES
           completion:completion];
}

+ (void)uploadContact:(Contact *)contact completion:(JCApiClientCompletionHandler)completion
{
    if (!contact) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Contact Is Null"]);
        }
        return;
    }
    
    
    NSDictionary *serializedData = contact.serializedData;
    if (!contact.contactId) {
        [self postWithPath:kJCV5ApiContactUploadRequestPath
                parameters:serializedData
         requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
                   retries:UPLOAD_CONTACT_NUMBER_OF_TRIES
                completion:completion];
    }
    else {
        [self putWithPath:kJCV5ApiContactUploadRequestPath
               parameters:serializedData
        requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
                  retries:UPLOAD_CONTACT_NUMBER_OF_TRIES
               completion:completion];
    }
}

+ (void)deleteContact:(Contact *)contact conpletion:(JCApiClientCompletionHandler)completion
{
    if (!contact) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Contact Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiContactDownloadRequestPath, contact.contactId];
    [self deleteWithPath:path
              parameters:nil
       requestSerializer:nil
                 retries:DELETE_CONTACT_NUMBER_OF_TRIES
              completion:completion];
}

#pragma mark Contact Groups

NSString *const kJCV5ApiContactGroupUploadRequestPath   = @"/contacts/v3/user/group/";
NSString *const kJCV5ApiContactGroupDeleteRequestPath   = @"/contacts/v3/user/group/%@";

+ (void)downloadContactGroupsWithCompletion:(JCApiClientCompletionHandler)completion
{
    //  TODO: not yet implemented server side.
    if (completion) {
        completion(YES, nil, nil);
    }
}

+ (void)uploadContactGroup:(ContactGroup *)contactGroup completion:(JCApiClientCompletionHandler)completion
{
    if (!contactGroup) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Contact Group Is Null"]);
        }
        return;
    }
    
    NSString *path = kJCV5ApiContactGroupUploadRequestPath;
    AFHTTPRequestSerializer *serializer = [JCBearerAuthenticationJSONRequestSerializer new];
    NSDictionary *serializedData = contactGroup.serializedData;
    if (!contactGroup.groupId) {
        [self postWithPath:path
                parameters:serializedData
         requestSerializer:serializer
                   retries:UPLOAD_CONTACT_NUMBER_OF_TRIES
                completion:completion];
    }
    else {
        [self putWithPath:path
               parameters:serializedData
        requestSerializer:serializer
                  retries:UPLOAD_CONTACT_NUMBER_OF_TRIES
               completion:completion];
    }
}

+ (void)deleteContactGroup:(ContactGroup *)contactGroup completion:(JCApiClientCompletionHandler)completion
{
    if (!contactGroup) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Contact Group Is Null"]);
        }
        return;
    }
    
    
    if (!contactGroup.groupId) {
        if (completion) {
            completion(YES, nil, nil);
        }
        return;
    }
    
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiContactGroupDeleteRequestPath, contactGroup.groupId];
    [self deleteWithPath:path
              parameters:nil
       requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
                 retries:DELETE_CONTACT_NUMBER_OF_TRIES
              completion:completion];
}

#pragma mark Contact Group Associations

NSString *const kJCV5ApiContactGroupAddAssociationRequestPath      = @"/contacts/v3/user/group/add/%@";
NSString *const kJCV5ApiContactGroupRemoveAssociationRequestPath   = @"/contacts/v3/user/group/remove/%@";

+ (void)associatedContactGroupAssociations:(NSDictionary *)contactGroupAssociations completion:(JCApiClientCompletionHandler)handler
{
    NSArray *groups = contactGroupAssociations.allKeys;
    NSMutableArray *remaining = groups.mutableCopy;
    for (NSString *group in groups) {
        
        NSString *path = [NSString stringWithFormat:kJCV5ApiContactGroupAddAssociationRequestPath, group];
        NSArray *contactIds = [contactGroupAssociations objectForKey:group];
        
        NSLog(@"%@ -> %@", path, contactIds);
    }
}

+ (void)disassociatedContactGroupAssociations:(NSDictionary *)contactGroupAssociations completion:(JCApiClientCompletionHandler)handler
{
    NSArray *groups = contactGroupAssociations.allKeys;
    NSMutableArray *remaining = groups.mutableCopy;
    for (NSString *group in groups) {
        
        NSString *path = [NSString stringWithFormat:kJCV5ApiContactGroupRemoveAssociationRequestPath, group];
        NSArray *contactIds = [contactGroupAssociations objectForKey:group];
        
        NSLog(@"%@ -> %@", path, contactIds);
    }
}


#pragma mark - SMS Messaging -

#ifndef MESSAGES_SEND_NUMBER_OF_TRIES
#define MESSAGES_SEND_NUMBER_OF_TRIES 1
#endif

#ifndef CONVERSATIONS_DOWNLOAD_NUMBER_OF_TRIES
#define CONVERSATIONS_DOWNLOAD_NUMBER_OF_TRIES 1
#endif

#ifndef MESSAGES_DOWNLOAD_NUMBER_OF_TRIES
#define MESSAGES_DOWNLOAD_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ApiSMSMessageSendRequestUrlPath                   = @"sms/send";
NSString *const kJCV5ApiSMSMessageRequestConversationsDigestURLPath    = @"sms/digest/did/%@/";
NSString *const kJCV5ApiSMSMessageRequestConversationsURLPath          = @"sms/messages/did/%@";
NSString *const kJCV5ApiSMSMessageRequestConversationURLPath           = @"sms/messages/did/%@/number/%@";

+ (void)sendSMSMessageWithParameters:(NSDictionary *)parameters completion:(JCApiClientCompletionHandler)completion
{
    [self postWithPath:kJCV5ApiSMSMessageSendRequestUrlPath
            parameters:parameters
     requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
               retries:MESSAGES_SEND_NUMBER_OF_TRIES
            completion:completion];
}

+ (void)downloadMessagesDigestForDID:(DID *)did completion:(JCApiClientCompletionHandler)completion
{
    if (!did) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"DID Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageRequestConversationsDigestURLPath, did.number];
    [self getWithPath:path
           parameters:nil
    requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
              retries:CONVERSATIONS_DOWNLOAD_NUMBER_OF_TRIES
           completion:completion];
}

+ (void)downloadMessagesForDID:(DID *)did completion:(JCApiClientCompletionHandler)completion
{
    if (!did) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"DID Is Null"]);
        }
        return;
    }
    
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageRequestConversationsURLPath, did.number];
    [self getWithPath:path
           parameters:nil
    requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
              retries:MESSAGES_DOWNLOAD_NUMBER_OF_TRIES
           completion:completion];
}

+ (void)downloadMessagesForDID:(DID *)did toConversationGroup:(id<JCConversationGroupObject>)conversationGroup completion:(JCApiClientCompletionHandler)completion
{
    if (!did) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"DID Is Null"]);
        }
        return;
    }
    
    if (!conversationGroup) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Person Is Null"]);
        }
        return;
    }
    
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageRequestConversationURLPath, did.number, conversationGroup.dialableNumber];
    [self getWithPath:path
           parameters:nil
    requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
              retries:MESSAGES_DOWNLOAD_NUMBER_OF_TRIES
           completion:completion];
}

#pragma mark - SMS Message Blocking -

#ifndef MESSAGES_BLOCK_NUMBER_OF_TRIES
#define MESSAGES_BLOCK_NUMBER_OF_TRIES 1
#endif

#ifndef MESSAGES_UNBLOCK_NUMBER_OF_TRIES
#define MESSAGES_UNBLOCK_NUMBER_OF_TRIES 1
#endif

#ifndef MESSAGES_BLOCKED_NUMBER_DOWNLOAD_NUMBER_OF_TRIES
#define MESSAGES_BLOCKED_NUMBER_DOWNLOAD_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ApiSMSMessageBlockedNumbersURLPath                = @"sms/blockedNumbers/did/%@";
NSString *const kJCV5ApiSMSMessageBlockURLPath                         = @"sms/block/did/%@/number/%@";
NSString *const kJCV5ApiSMSMessageUnblockURLPath                       = @"sms/unblock/did/%@/number/%@";

+ (void)blockSMSMessageForDID:(DID *)did
                       number:(id<JCPhoneNumberDataSource>)phoneNumber
                   completion:(JCApiClientCompletionHandler)completion
{
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageBlockURLPath, did.number, phoneNumber.dialableNumber];
    [self postWithPath:path
            parameters:nil
     requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
               retries:MESSAGES_UNBLOCK_NUMBER_OF_TRIES
            completion:completion];
}

+ (void)unblockSMSMessageForDID:(DID *)did
                         number:(id<JCPhoneNumberDataSource>)phoneNumber
                     completion:(JCApiClientCompletionHandler)completion
{
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageUnblockURLPath, did.number, phoneNumber.dialableNumber];
    [self postWithPath:path
            parameters:nil
     requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
               retries:MESSAGES_UNBLOCK_NUMBER_OF_TRIES
            completion:completion];
}

+ (void)downloadMessagesBlockedForDID:(DID *)did
                           completion:(JCApiClientCompletionHandler)completion
{
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageBlockedNumbersURLPath, did.number];
    [self getWithPath:path
           parameters:nil
    requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
              retries:MESSAGES_BLOCKED_NUMBER_DOWNLOAD_NUMBER_OF_TRIES
           completion:completion];
}

@end
