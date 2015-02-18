//
//  Message+SMSClient.h
//  JiveOne
//
//  Created by P Leonard on 2/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "SMSMessage.h"
#import "DID.h"
#import "JCPersonDataSource.h"

@interface SMSMessage (SMSClient)

// Creates a SMS message from dictionary data. This is meant to be used for processing from a
// network or or socket event that has requested data, and delivered this response. Any messages
// made will be linked to the passed DID. The Passed DID should be from the same context as the
// passed managed object context. The passed data dictionary should follow this format:
// @{
//      "id": {id},
//      "number": "{number}",
//      "didId": "{did_id}",
//      "body": "{message body}",
//      "direction": "{outbound | inbound}",
//      "arrivalTime": "{yyyy-mm-dd HH:mm:ss.SSSS}"
//  }
//
+ (void)createSmsMessageWithMessageData:(NSDictionary *)dataDictionary did:(DID *)did;

#pragma mark - Send -

// Sends a sent request. If successfully sent, creates a message from the send success response.
+(void)sendMessage:(NSString *)message toPerson:(id<JCPersonDataSource>)person fromDid:(DID *)did completion:(CompletionHandler)completion;

#pragma mark - Receive -

// Downloads all messages for all DIDs in Parallel. Calls downloadMessagesForDID:completion:;
+(void)downloadMessagesForDIDs:(NSSet *)dids completion:(CompletionHandler)completion;

// Downloads all messages for a DID.
+(void)downloadMessagesForDID:(DID *)did completion:(CompletionHandler)completion;

// Downloads all messages for a conversation thread between a DID and a number.
+(void)downloadMessagesForDID:(DID *)did toPerson:(id<JCPersonDataSource>)person completion:(CompletionHandler)completion;


@end
