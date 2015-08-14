//
//  OutGoingCall.h
//  JiveOne
//
//  Created by P Leonard on 10/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Call.h"

extern NSString *const kOutgoingCallEntityName;

@interface OutgoingCall : Call

@end

@interface OutgoingCall (MagicalRecord)

+(void)addOutgoingCallWithLineSession:(JCPhoneSipSession *)session line:(Line *)line;

@end