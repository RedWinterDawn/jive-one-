//
//  Message+SMSClient.h
//  JiveOne
//
//  Created by P Leonard on 2/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "SMSMessage.h"
#import "DID.h"
#import "JCPerson.h"

@interface SMSMessage (SMSClient)

+(void)sendMessage:(NSString *)message toNumber:(NSString *)number fromDid:(DID *)did completion:(CompletionHandler)completion;

+(void)downloadMessagesForDID:(DID *)did completion:(CompletionHandler)completion;
+(void)downloadMessagesForDID:(DID *)did number:(NSString *)number completion:(CompletionHandler)completion;

@end
