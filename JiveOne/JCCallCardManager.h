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

extern NSString *const kJCCallCardManagerAddedIncomingCallNotification;
extern NSString *const kJCCallCardManagerRemoveIncomingCallNotification;

extern NSString *const kJCCallCardManagerAddedCurrentCallNotification;
extern NSString *const kJCCallCardManagerRemoveCurrentCallNotification;

extern NSString *const kJCCallCardManagerUpdatedIndex;
extern NSString *const kJCCallCardManagerPriorUpdateCount;
extern NSString *const kJCCallCardManagerUpdateCount;

@interface JCCallCardManager : NSObject

@property (nonatomic, readonly) NSArray *incomingCalls;
@property (nonatomic, readonly) NSArray *currentCalls;
@property (nonatomic, readonly) NSArray *calls;

@property (nonatomic, readonly) NSUInteger totalCalls;

-(void)hangUpCall:(JCCallCard *)callCard;
-(void)placeCallOnHold:(JCCallCard *)callCard;
-(void)removeFromHold:(JCCallCard *)callCard;

-(void)dialNumber:(NSString *)dialNumber;
-(void)refreshCallDatasource;
-(void)answerCall:(JCCallCard *)callCard;

// Temporary for POC
-(void)addIncomingCall:(JCCallCard *)callCard;
-(void)removeIncomingCall:(JCCallCard *)callCard;

@end


@interface JCCallCardManager (Singleton)

// Singleton accessor
+ (JCCallCardManager *)sharedManager;

@end