//
//  MissedCall.h
//  JiveOne
//
//  Created by P Leonard on 10/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Call.h"

#import <JCPhoneModule/JCPhoneModule.h>

extern NSString *const kMissedCallEntityName;

@interface MissedCall : Call

@end

@interface MissedCall (MagicalRecord)

+(void)addMissedCallWithLineSession:(JCPhoneSipSession *)session line:(Line *)line;

@end
