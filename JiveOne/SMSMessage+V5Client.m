//
//  Message+SMSClient.m
//  JiveOne
//
//  Created by P Leonard on 2/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "SMSMessage+V5Client.h"
#import "JCV5ApiClient+SMSMessaging.h"

#import <JCPhoneModule/JCProgressHUD.h>

NSString *const kSMSMessageSendRequestToKey                 = @"to";
NSString *const kSMSMessageSendRequestFromKey               = @"from";
NSString *const kSMSMessageSendRequestBodyKey               = @"body";

NSString *const kSMSMessageResponseStatusKey                = @"status";
NSString *const kSMSMessageResponseErrorMsgKey              = @"errorMessage";
NSString *const kSMSMessageResponseErrorCodeKey             = @"errorCode";
NSString *const kSMSMessageResponseObjectKey                = @"message";
NSString *const kSMSLastMessageResponseObjectKey            = @"lastMessage";

NSString *const kSMSMessageResponseObjectEventIdKey              = @"uid";
NSString *const kSMSMessageResponseObjectDidIdKey              = @"didId";
NSString *const kSMSMessageResponseObjectNumberKey             = @"number";
NSString *const kSMSMessageResponseObjectTextKey               = @"body";
NSString *const kSMSMessageResponseObjectDirectionKey          = @"direction";
NSString *const kSMSMessageResponseObjectDirectionInboundValue     = @"inbound";
NSString *const kSMSMessageResponseObjectArrivalTimeKey        = @"epochTime";

@implementation SMSMessage (V5Client)

+ (void)createSmsMessageWithMessageData:(NSDictionary *)data {
    
    NSString *didId = [data stringValueForKey:kSMSMessageResponseObjectDidIdKey];
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        DID *did = [DID MR_findFirstByAttribute:NSStringFromSelector(@selector(didId)) withValue:didId inContext:localContext];
        if (did) {
            [self createSmsMessageWithMessageData:data did:did];
        }
    } completion:nil];
}

+ (SMSMessage *)createSmsMessageWithMessageData:(NSDictionary *)data did:(DID *)did
{
    // Fetch values from data object.
    NSString *number    = [data stringValueForKey:kSMSMessageResponseObjectNumberKey];
    NSString *text      = [data stringValueForKey:kSMSMessageResponseObjectTextKey];
    NSString *direction = [data stringValueForKey:kSMSMessageResponseObjectDirectionKey];
    NSString *eventId   = [data stringValueForKey:kSMSMessageResponseObjectEventIdKey];
    
    // We check to see if we already have a message using the stored server hash, and if we don't,
    // we create one with the data.
    SMSMessage *message = [SMSMessage MR_findFirstByAttribute:NSStringFromSelector(@selector(eventId)) withValue:eventId inContext:did.managedObjectContext];
    if (!message) {
        message = [SMSMessage MR_createEntityInContext:did.managedObjectContext];
        message.eventId = eventId;
        [message setNumber:number name:nil];
        message.text = text;
        message.inbound = [direction isEqualToString:kSMSMessageResponseObjectDirectionInboundValue] ? true : false;
        message.read = [direction isEqualToString:kSMSMessageResponseObjectDirectionInboundValue] ? false : true;
        message.unixTimestamp = [data integerValueForKey:kSMSMessageResponseObjectArrivalTimeKey];
        message.did = did;
    } else {
        message.unixTimestamp = [data integerValueForKey:kSMSMessageResponseObjectArrivalTimeKey];
    }
    return message;
}

#pragma mark - Send -

+(void)sendMessage:(NSString *)message toMessageGroup:(JCMessageGroup *)messageGroup fromDid:(DID *)did completion:(SMSMessageSendCompletionHandler)completion
{
    NSDictionary *parameters = @{kSMSMessageSendRequestToKey: messageGroup.phoneNumber.dialableNumber,
                                 kSMSMessageSendRequestFromKey: did.number,
                                 kSMSMessageSendRequestBodyKey: message};
    
    [UIApplication showStatus:NSLocalizedString(@"Sending", @"SMS messaging")];
    [JCV5ApiClient sendSMSMessageWithParameters:parameters completion:^(BOOL success, id response, NSError *error) {
        if (success) {
            [self processSMSSendResponseObject:response did:did completion:completion];
            [UIApplication hideStatus];
        } else {
            if (completion) {
                completion(NO, nil, error);
            }
        }
    }];
}

#pragma mark - Receive -

#pragma mark Digest

+(void)downloadMessagesDigestForDIDs:(NSSet *)dids completion:(CompletionHandler)completion
{
    __block NSError *batchError;
    __block NSMutableSet *pendingDids = [NSMutableSet setWithSet:dids];
    for (id object in dids) {
        if ([object isKindOfClass:[DID class]]) {
            __block DID *did = (DID *)object;
            [self downloadMessagesDigestForDID:did completion:^(BOOL success, NSError *error) {
                if (error && !batchError) {
                    batchError = error;
                }
                
                [pendingDids removeObject:did];
                if (pendingDids.count == 0) {
                    if (completion) {
                        completion((error == nil), batchError );
                    }
                }
            }];
        }
    }
}

+(void)downloadMessagesDigestForDID:(DID *)did completion:(CompletionHandler)completion
{
    [JCV5ApiClient downloadMessagesDigestForDID:did completion:^(BOOL success, id response, NSError *error) {
        if (success) {
            [self processSMSDownloadConversationsDigestResponseObject:response did:did completion:completion];
        } else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

#pragma mark Bulk

+(void)downloadMessagesForDIDs:(NSSet *)dids completion:(CompletionHandler)completion
{
    __block NSError *batchError;
    __block NSMutableSet *pendingDids = [NSMutableSet setWithSet:dids];
    for (id object in dids) {
        if ([object isKindOfClass:[DID class]]) {
            __block DID *did = (DID *)object;
            [self downloadMessagesForDID:did completion:^(BOOL success, NSError *error) {
                if (error && !batchError) {
                    batchError = error;
                }
                
                [pendingDids removeObject:did];
                if (pendingDids.count == 0) {
                    if (completion) {
                        completion((error == nil), batchError );
                    }
                }
            }];
        }
    }
}

+(void)downloadMessagesForDID:(DID *)did completion:(CompletionHandler)completion
{
    [JCV5ApiClient downloadMessagesForDID:did completion:^(BOOL success, id response, NSError *error) {
        if (success) {
            [self processSMSDownloadConversationsResponseObject:response did:did completion:completion];
        }
        else
        {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

#pragma mark Conversation

+(void)downloadMessagesForDID:(DID *)did toMessageGroup:(JCMessageGroup *)messageGroup completion:(CompletionHandler)completion
{
    [JCV5ApiClient downloadMessagesForDID:did toMessageGroup:messageGroup completion:^(BOOL success, id response, NSError *error) {
        if(success) {
            [self processSMSDownloadConversationResponseObject:response did:did completion:completion];
        }
        else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

#pragma mark - Private -

#pragma mark Retries

#pragma Response Processing

// The send sms logic does not actually create the core data object until we have gotten a positive
// confimation from the server that the message was sent. When we process the result, we build the
// message from the result and store it locally
+ (void)processSMSSendResponseObject:(id)responseObject did:(DID *)did completion:(SMSMessageSendCompletionHandler)completion
{
    @try {
        // Is dictionary?
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            [NSException raise:NSInvalidArgumentException format:@"Dictionary is null"];
        }
        
        // Is Success?
        NSDictionary *response = (NSDictionary *)responseObject;
        NSInteger errorCode = [response integerValueForKey:kSMSMessageResponseErrorCodeKey];
        if (errorCode != 0) {
            if (completion) {
                completion(false, nil, [JCApiClientError errorWithCode:errorCode]);
            }
            return;
        }
        
        // Do we have a response object?
        id object = [response objectForKey:kSMSMessageResponseObjectKey];
        if(!object || ![object isKindOfClass:[NSDictionary class]]) {
            [NSException raise:NSInvalidArgumentException format:@"Response object is null or invalid"];
        }
        
        __block NSManagedObjectID *objectID;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            DID *localDid = (DID *)[localContext objectWithID:did.objectID];
            SMSMessage *message = [self createSmsMessageWithMessageData:(NSDictionary *)object did:localDid];
            [localContext obtainPermanentIDsForObjects:@[message] error:nil];
            objectID = message.objectID;
        } completion:^(BOOL contextDidSave, NSError *error) {
            SMSMessage *smsMessage = (SMSMessage *)[did.managedObjectContext objectWithID:objectID];
            if (completion) {
                completion(contextDidSave, smsMessage, error);
            }
        }];
    }
    @catch (NSException *exception) {
        NSInteger code;
        if (completion) {
            if ([exception.name isEqualToString:NSInvalidArgumentException]) {
                code = API_CLIENT_SMS_RESPONSE_INVALID;
            }
            completion(NO, nil, [JCApiClientError errorWithCode:code]);
        }
    }
}

+ (void)processSMSDownloadConversationsDigestResponseObject:(id)responseObject did:(DID *)did completion:(CompletionHandler)completion
{
    @try {
        
        // Is Array? We should have an array of messages.
        if (![responseObject isKindOfClass:[NSArray class]]) {
            [NSException raise:NSInvalidArgumentException format:@"Array is null"];
        }
        
        NSArray *digestMessages = (NSArray *)responseObject;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            DID *localDid = (DID *)[localContext objectWithID:did.objectID];
            for (id object in digestMessages) {
                if ([object isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *digestData = (NSDictionary *)object;
                    id messageObject = [digestData objectForKey:kSMSLastMessageResponseObjectKey];
                    if ([messageObject isKindOfClass:[NSDictionary class]]) {
                        [self createSmsMessageWithMessageData:messageObject did:localDid];
                    }
                }
            }
        }
        completion:completion];
    }
    @catch (NSException *exception) {
        NSInteger code;
        if (completion) {
            if ([exception.name isEqualToString:NSInvalidArgumentException]) {
                code = API_CLIENT_SMS_RESPONSE_INVALID;
            }
            completion(NO, [JCApiClientError errorWithCode:code]);
        }
    }
}

+ (void)processSMSDownloadConversationsResponseObject:(id)responseObject did:(DID *)did completion:(CompletionHandler)completion
{
    @try {
        
        // Is Array? We should have an array of messages.
        if (![responseObject isKindOfClass:[NSArray class]]) {
            [NSException raise:NSInvalidArgumentException format:@"Array is null"];
        }
        
        NSArray *messages = (NSArray *)responseObject;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            DID *localDid = (DID *)[localContext objectWithID:did.objectID];
            for (id object in messages) {
                if ([object isKindOfClass:[NSDictionary class]]) {
                    [self createSmsMessageWithMessageData:(NSDictionary *)object did:localDid];
                }
            }
        }
        completion:completion];
        
    }
    @catch (NSException *exception) {
        NSInteger code;
        if (completion) {
            if ([exception.name isEqualToString:NSInvalidArgumentException]) {
                code = API_CLIENT_SMS_RESPONSE_INVALID;
            }
            completion(NO, [JCApiClientError errorWithCode:code]);
        }
    }
}

+ (void)processSMSDownloadConversationResponseObject:(id)responseObject did:(DID *)did completion:(CompletionHandler)completion
{
    @try {
        
        // Is Array? We should have an array of messages.
        if (![responseObject isKindOfClass:[NSArray class]]) {
            [NSException raise:NSInvalidArgumentException format:@"Array is null"];
        }
        
        NSArray *messages = (NSArray *)responseObject;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            DID *localDid = (DID *)[localContext objectWithID:did.objectID];
            for (id object in messages) {
                if ([object isKindOfClass:[NSDictionary class]]) {
                    [self createSmsMessageWithMessageData:(NSDictionary *)object did:localDid];
                }
            }
        }
        completion:completion];
    }
    @catch (NSException *exception) {
        NSInteger code;
        if (completion) {
            if ([exception.name isEqualToString:NSInvalidArgumentException]) {
                code = API_CLIENT_SMS_RESPONSE_INVALID;
            }
            completion(NO, [JCApiClientError errorWithCode:code]);
        }
    }
}

@end
