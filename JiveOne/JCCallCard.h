//
//  JCCall.h
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JCLineSession.h"

typedef enum : NSUInteger {
    JCCallCardCurrentCall = 0,
    JCCallCardIncomingCall,
} JCCallCardState;

extern NSString *const kJCCallCardStatusChangeKey;
extern NSString *const kJCCallCardHoldKey;

@interface JCCallCard : NSObject <JCLineSessionDelegate>

@property (nonatomic, strong) NSString *identifer;
@property (nonatomic, strong) NSString *callerId;
@property (nonatomic, strong) NSString *dialNumber;
@property (nonatomic, strong) JCLineSession *lineSession;
@property (nonatomic, strong) NSDate *started;
@property (nonatomic, strong) NSDate *holdStarted;
@property (nonatomic) JCCall lastState;
@property (nonatomic, getter=isIncoming) bool incoming;

@property (nonatomic) BOOL hold;

-(void)answerCall;
-(void)endCall;

@end
