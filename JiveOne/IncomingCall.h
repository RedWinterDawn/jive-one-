//
//  IncommingCall.h
//  JiveOne
//
//  Created by P Leonard on 10/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Call.h"
#import "JCPhoneSipSession.h"

extern NSString *const kIncomingCallEntityName;

@interface IncomingCall : Call

@end

@interface IncomingCall (MagicalRecord)

+(void)addIncommingCallWithLineSession:(JCPhoneSipSession *)session line:(Line *)line;

@end