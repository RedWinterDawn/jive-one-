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

extern NSString *const kJCCallCardManagerAddedIncomingCallNotification;
extern NSString *const kJCCallCardManagerRemoveIncomingCallNotification;

extern NSString *const kJCCallCardManagerAddedCurrentCallNotification;
extern NSString *const kJCCallCardManagerRemoveCurrentCallNotification;

extern NSString *const kJCCallCardManagerUpdatedIndex;
extern NSString *const kJCCallCardManagerPriorUpdateCount;
extern NSString *const kJCCallCardManagerUpdateCount;

typedef enum : NSUInteger {
    JCCallCardDialSingle = 0,
    JCCallCardDialBlindTransfer,
    JCCallCardDialWarmTransfer,
} JCCallCardDialTypes;

@interface JCCallCardManager : NSObject

//@property (nonatomic, readonly) NSArray *incomingCalls;
@property (nonatomic, strong) NSMutableArray *currentCalls;
@property (nonatomic, readonly) NSUInteger totalCalls;

-(void)hangUpCall:(JCCallCard *)callCard remote:(BOOL)remote;
-(void)placeCallOnHold:(JCCallCard *)callCard;
-(void)removeFromHold:(JCCallCard *)callCard;

-(void)dialNumber:(NSString *)dialNumber;
-(void)dialNumber:(NSString *)dialNumber type:(JCCallCardDialTypes)dialType completion:(void (^)(bool success, NSDictionary *callInfo))completion;

-(void)finishWarmTransfer:(void (^)(bool success))completion;

-(void)answerCall:(JCCallCard *)callCard;

// Temporary for POC
-(void)addIncomingCall:(JCLineSession *)session;
-(void)removeIncomingCall:(JCCallCard *)callCard;

@end


@interface JCCallCardManager (Singleton)

// Singleton accessor
+ (JCCallCardManager *)sharedManager;

@end