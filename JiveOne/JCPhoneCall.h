//
//  JCCall.h
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JCPhoneSipSession.h"

@class JCPhoneCall;

typedef void(^PhoneCallCompletionHandler)(BOOL success, NSError *error);

@protocol JCPhoneCallDelegate <NSObject>

// Notify delegate to answer an Incoming call card.
-(void)answerCall:(JCPhoneCall *)phoneCall completion:(PhoneCallCompletionHandler)completion;

// Notify delegate to hangs up a specific call card.
-(void)hangUpCall:(JCPhoneCall *)phoneCall completion:(PhoneCallCompletionHandler)completion;

// Notify delegate to place a specific call on hold.
-(void)holdCall:(JCPhoneCall *)phoneCall completion:(PhoneCallCompletionHandler)completion;

// Notify delegate to take a specific call off hold.
-(void)unholdCall:(JCPhoneCall *)phoneCall completion:(PhoneCallCompletionHandler)completion;

@end

@interface JCPhoneCall : NSObject

@property (nonatomic, weak) id <JCPhoneCallDelegate> delegate;
@property (nonatomic, strong) NSDate *started;
@property (nonatomic, strong) NSDate *holdStarted;

@property (nonatomic, readonly) JCPhoneSipSession *lineSession;
@property (nonatomic, readonly) NSString *callerId;
@property (nonatomic, readonly) NSString *dialNumber;

-(instancetype)initWithSession:(JCPhoneSipSession *)lineSession;

-(void)answerCall:(PhoneCallCompletionHandler)completion;
-(void)endCall:(PhoneCallCompletionHandler)completion;
-(void)holdCall:(PhoneCallCompletionHandler)completion;
-(void)unholdCall:(PhoneCallCompletionHandler)completion;

@end