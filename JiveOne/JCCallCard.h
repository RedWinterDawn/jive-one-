//
//  JCCall.h
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JCLineSession.h"

extern NSString *const kJCCallCardStatusChangeKey;
extern NSString *const kJCCallCardHoldKey;

@interface JCCallCard : NSObject <JCLineSessionDelegate>

@property (nonatomic, strong) JCLineSession *lineSession;
@property (nonatomic, strong) NSDate *started;
@property (nonatomic, strong) NSDate *holdStarted;

@property (nonatomic, readonly) NSString *identifer;
@property (nonatomic, readonly) NSString *callerId;
@property (nonatomic, readonly) NSString *dialNumber;

@property (nonatomic, getter=isIncoming) bool incoming;
@property (nonatomic, getter=isConference) bool conference;
@property (nonatomic) BOOL hold;
@property (nonatomic) JCCall callState;

-(id)initWithLineSession:(JCLineSession *)lineSession;
-(id)initWithCalls:(NSArray *)calls;
-(id)initWithLineSessions:(NSArray *)sessions;

-(void)answerCall;
-(void)endCall;

-(void)addCall:(JCCallCard *)call;
-(void)addCalls:(NSArray *)calls;

-(void)removeCall:(JCCallCard *)call;
-(void)removeCalls:(NSArray *)calls;

@end
