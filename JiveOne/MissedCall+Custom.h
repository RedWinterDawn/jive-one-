//
//  MissedCall+Custom.h
//  JiveOne
//
//  Created by P Leonard on 10/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "MissedCall.h"

@interface MissedCall (Custom)

+(void)addMissedCallWithLineSession:(JCLineSession *)session;

@end
