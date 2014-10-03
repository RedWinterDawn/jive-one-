//
//  JCCall.h
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    JCCallCardCurrentCall = 0,
    JCCallCardIncomingCall,
} JCCallCardState;


@interface JCCallCard : NSObject

@property (nonatomic, strong) NSString *identifer;
@property (nonatomic, strong) NSString *callerId;
@property (nonatomic, strong) NSString *dialNumber;

@property (nonatomic, strong) NSDate *started;
@property (nonatomic, strong) NSDate *holdStarted;
@property (nonatomic, getter=isIncoming) bool incoming;

@property (nonatomic) BOOL hold;

-(void)answerCall;
-(void)endCall;

@end
