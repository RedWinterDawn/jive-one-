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

extern NSString *const kJCCallCardManagerAddedCallNotification;
extern NSString *const kJCCallCardManagerRemoveCallNotification;
extern NSString *const kJCCallCardManagerUpdatedIndex;

@interface JCCallCardManager : NSObject

@property (nonatomic, readonly) NSArray *incomingCalls;
@property (nonatomic, readonly) NSArray *currentCalls;

@property (nonatomic, readonly) NSUInteger totalCalls;

-(void)hangUpCall:(JCCallCard *)callCard;
-(void)placeCallOnHold:(JCCallCard *)callCard;
-(void)removeFromHold:(JCCallCard *)callCard;

-(void)dialNumber:(NSString *)dialNumber;

@end


@interface JCCallCardManager (Singleton)

// Singleton accessor
+ (JCCallCardManager *)sharedManager;

@end