//
//  JCCallManager.h
//  JiveOne
//
//  Singleton Manager that interfaces the UI/UX with the back end call architecture.
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JCCallCard.h"
#import "JCLineSession.h"

extern NSString *const kJCCallCardManagerAddedCallNotification;
extern NSString *const kJCCallCardManagerAnswerCallNotification;
extern NSString *const kJCCallCardManagerRemoveCallNotification;

extern NSString *const kJCCallCardManagerAddedConferenceCallNotification;
extern NSString *const kJCCallCardManagerRemoveConferenceCallNotification;

extern NSString *const kJCCallCardManagerUpdatedIndex;
extern NSString *const kJCCallCardManagerPriorUpdateCount;
extern NSString *const kJCCallCardManagerUpdateCount;
extern NSString *const kJCCallCardManagerRemovedCells;
extern NSString *const kJCCallCardManagerAddedCells;
extern NSString *const kJCCallCardManagerLastCallState;
extern NSString *const kJCCallCardManagerIncomingCall;

extern NSString *const kJCCallCardManagerNewCall;
extern NSString *const kJCCallCardManagerTransferedCall;


typedef enum : NSUInteger {
    JCCallCardDialSingle = 0,
    JCCallCardDialBlindTransfer,
    JCCallCardDialWarmTransfer,
} JCCallCardDialTypes;

@interface JCCallCardManager : NSObject

@property (nonatomic, strong) NSMutableArray *calls;

-(void)dialNumber:(NSString *)dialNumber
             type:(JCCallCardDialTypes)dialType
       completion:(void (^)(bool success, NSDictionary *callInfo))completion;

-(void)hangUpCall:(JCCallCard *)callCard;

-(void)setCallCallHoldState:(bool)hold forCard:(JCCallCard *)callCard;

-(void)answerCall:(JCCallCard *)callCard;
-(void)addIncomingCallSession:(JCLineSession *)session;
-(void)finishWarmTransfer:(void (^)(bool success))completion;

-(void)mergeCalls:(void (^)(bool success))completion;
-(void)splitCalls;
-(void)swapCalls;

-(void)removeCall:(JCCallCard *)callCard;

@end


@interface JCCallCardManager (Singleton)

+ (JCCallCardManager *)sharedManager;

@end