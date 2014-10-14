//
//  IncomingCall+Custom.h
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "IncomingCall.h"
#import "JCLineSession.h"

@interface IncomingCall (Custom)

+(void)addIncommingCallWithLineSession:(JCLineSession *)session;

@end
