//
//  JCSMSConversationGroup.h
//  JiveOne
//
//  Created by Robert Barclay on 4/28/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMultiPersonPhoneNumber.h"
#import "JCConversationGroupObject.h"
#import "SMSMessage.h"

@interface JCSMSConversationGroup : JCPhoneNumber <JCConversationGroupObject>

-(instancetype)initWithPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber;
-(instancetype)initWithMessage:(SMSMessage *)smsMessage phoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber;

@end
