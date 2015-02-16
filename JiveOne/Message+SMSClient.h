//
//  Message+SMSClient.h
//  JiveOne
//
//  Created by P Leonard on 2/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Message.h"
#import "DID.h"
#import "JCPerson.h"

@interface Message (SMSClient)

//+(void)downloadMessagesForUser:(User *)user completion:(CompletionHandler)completion;
+(void)sendMessageForDID:(DID *)did  user:(User *)user person:(id<JCPerson>)person message:(NSString *)message completion:(CompletionHandler)completion;


@end
