//
//  JCCall.h
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JCPhoneSipSession.h"

@class JCCallCard;

@protocol JCCallCardDelegate <NSObject>

// Notify delegate to answer an Incoming call card.
-(void)answerCall:(JCCallCard *)callCard completion:(CompletionHandler)completion;

// Notify delegate to hangs up a specific call card.
-(void)hangUpCall:(JCCallCard *)callCard completion:(CompletionHandler)completion;

// Notify delegate to place a specific call on hold.
-(void)holdCall:(JCCallCard *)callCard completion:(CompletionHandler)completion;

// Notify delegate to take a specific call off hold.
-(void)unholdCall:(JCCallCard *)callCard completion:(CompletionHandler)completion;

@end

@interface JCCallCard : NSObject

@property (nonatomic, weak) id <JCCallCardDelegate> delegate;
@property (nonatomic, strong) NSDate *started;
@property (nonatomic, strong) NSDate *holdStarted;

@property (nonatomic, readonly) JCPhoneSipSession *lineSession;
@property (nonatomic, readonly) NSString *callerId;
@property (nonatomic, readonly) NSString *dialNumber;

-(instancetype)initWithLineSession:(JCPhoneSipSession *)lineSession;

-(void)answerCall:(CompletionHandler)completion;
-(void)endCall:(CompletionHandler)completion;
-(void)holdCall:(CompletionHandler)completion;
-(void)unholdCall:(CompletionHandler)completion;

@end