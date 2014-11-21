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

@class JCCallCard;

@protocol JCCallCardDelegate <NSObject>

// Notify delegate to answer an Incoming call card.
-(void)answerCall:(JCCallCard *)callCard;

// Notify delegate to hangs up a specific call card.
-(void)hangUpCall:(JCCallCard *)callCard;

// Notify the delegate to sets the specified call state for the given call card.
-(void)setCallHold:(bool)hold forCall:(JCCallCard *)callCard;

@end

@interface JCCallCard : NSObject

@property (nonatomic, weak) id <JCCallCardDelegate> delegate;
@property (nonatomic, strong) NSDate *started;
@property (nonatomic, strong) NSDate *holdStarted;
@property (nonatomic, getter=isHolding) bool hold;

@property (nonatomic, readonly) JCLineSession *lineSession;
@property (nonatomic, readonly) NSString *identifer;
@property (nonatomic, readonly) NSString *callerId;
@property (nonatomic, readonly) NSString *dialNumber;
@property (nonatomic, readonly) JCLineSessionState callState;
@property (nonatomic, readonly) bool isIncoming;

-(instancetype)initWithLineSession:(JCLineSession *)lineSession;

-(void)answerCall;
-(void)endCall;

@end