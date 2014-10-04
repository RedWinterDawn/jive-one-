//
//  JCCallManager.m
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardManager.h"

NSString *const kJCCallCardManagerAddedIncomingCallNotification = @"addedIncommingCall";
NSString *const kJCCallCardManagerRemoveIncomingCallNotification = @"removedIncommingCall";

NSString *const kJCCallCardManagerAddedCurrentCallNotification = @"addedCurrentCall";
NSString *const kJCCallCardManagerRemoveCurrentCallNotification = @"removedCurrentCall";

NSString *const kJCCallCardManagerUpdatedIndex = @"index";
NSString *const kJCCallCardManagerPriorUpdateCount = @"priorCount";
NSString *const kJCCallCardManagerUpdateCount = @"updateCount";

NSString *const kJCCallCardManagerNewCall       = @"newCall";
NSString *const kJCCallCardManagerActiveCall    = @"activeCall";

@interface JCCallCardManager ()
{
    NSMutableArray *_currentCalls;
    NSMutableArray *_incomingCalls;
}

@end

@implementation JCCallCardManager

-(void)addIncomingCall:(JCCallCard *)callCard
{
    if (!_incomingCalls)
        _incomingCalls = [NSMutableArray array];
    
    NSUInteger priorCount = self.totalCalls;
    [_incomingCalls addObject:callCard];
    callCard.incoming = true;
    
    // Sort the array and fetch the resulting new index of the call card.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"started" ascending:NO];
    [_incomingCalls sortUsingDescriptors:@[sortDescriptor]];
    
    NSUInteger newIndex = [self.calls indexOfObject:callCard];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerAddedIncomingCallNotification
                                                        object:self
                                                      userInfo:@{
                                                                 kJCCallCardManagerUpdatedIndex:[NSNumber numberWithInteger:newIndex],
                                                                 kJCCallCardManagerPriorUpdateCount:[NSNumber numberWithInteger:priorCount],
                                                                 kJCCallCardManagerUpdateCount: [NSNumber numberWithInteger:self.totalCalls]
                                                                }];
}

-(void)removeIncomingCall:(JCCallCard *)callCard
{
    if (![_incomingCalls containsObject:callCard])
        return;
    
    NSUInteger index = [self.calls indexOfObject:callCard];
    NSUInteger priorCount = self.totalCalls;
    [_incomingCalls removeObject:callCard];
    callCard.incoming = false;
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerRemoveIncomingCallNotification
                                                        object:self
                                                      userInfo:@{
                                                                 kJCCallCardManagerUpdatedIndex:[NSNumber numberWithInteger:index],
                                                                 kJCCallCardManagerPriorUpdateCount:[NSNumber numberWithInteger:priorCount],
                                                                 kJCCallCardManagerUpdateCount: [NSNumber numberWithInteger:self.totalCalls]
                                                                }];
}

-(void)dialNumber:(NSString *)dialNumber
{
    JCCallCard *callCard = [[JCCallCard alloc] init];
    callCard.dialNumber = dialNumber;
    callCard.started = [NSDate date];
    
    // TODO: Do something to initiate the call.
    
    [self addCurrentCallCard:callCard];
    
    //[self dialNumber:dialNumber type:JCCallCardDialSingle completion:NULL];
}

-(void)dialNumber:(NSString *)dialNumber type:(JCCallCardDialTypes)dialType completion:(void (^)(bool success, NSDictionary *callInfo))completion
{
    JCCallCard *callCard = [[JCCallCard alloc] init];
    callCard.dialNumber = dialNumber;
    callCard.started = [NSDate date];
    
    // TODO: Do something to initiate the call.
    
    [self addCurrentCallCard:callCard];
    
    bool success = true;
    NSUInteger index = [self.calls indexOfObject:callCard];
    NSDictionary *dictionary = @{
                                 kJCCallCardManagerNewCall: callCard,
                                 kJCCallCardManagerUpdatedIndex: [NSNumber numberWithInteger:index],
                                 };
    
    if (completion != NULL)
        completion(success, dictionary);
}

-(void)answerCall:(JCCallCard *)newCallCard
{
    // TODO: do something to answer the call;
    
    for (JCCallCard *callCard in _currentCalls)
        callCard.hold = true;
    
    newCallCard.started = [NSDate date];
    [self removeIncomingCall:newCallCard];
    [self addCurrentCallCard:newCallCard];
}

-(void)hangUpCall:(JCCallCard *)callCard
{
    // TODO: do something to end call
    
    
    [self removeCurrentCall:callCard];
}

-(void)placeCallOnHold:(JCCallCard *)callCard
{
    // TODO: do something to place the call on hold
    
}

-(void)removeFromHold:(JCCallCard *)callCard
{
    // TODO: do something to remove call from hold.
}

#pragma mark - Properties -

-(NSUInteger)totalCalls
{
    return self.calls.count;
}

-(NSArray *)calls
{
    if (!_incomingCalls)
        _incomingCalls = [NSMutableArray array];
    
    return [_incomingCalls arrayByAddingObjectsFromArray:_currentCalls];
}
                     
#pragma mark - Private -

-(void)removeCurrentCall:(JCCallCard *)callCard
{
    if (![_currentCalls containsObject:callCard])
        return;
    
    NSUInteger index = [_currentCalls indexOfObject:callCard];
    [_currentCalls removeObject:callCard];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerRemoveCurrentCallNotification object:self userInfo:@{kJCCallCardManagerUpdatedIndex:[NSNumber numberWithInteger:index]}];
}

-(void)addCurrentCallCard:(JCCallCard *)callCard
{
    if (!_currentCalls)
        _currentCalls = [NSMutableArray array];
    [_currentCalls addObject:callCard];
    
    // Sort the array and fetch the resulting new index of the call card.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"started" ascending:NO];
    [_currentCalls sortUsingDescriptors:@[sortDescriptor]];
    
    NSUInteger newIndex = [_currentCalls indexOfObject:callCard];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerAddedCurrentCallNotification object:self userInfo:@{kJCCallCardManagerUpdatedIndex:[NSNumber numberWithInteger:newIndex]}];
}

@end


static JCCallCardManager *singleton = nil;

@implementation JCCallCardManager (Singleton)

+(JCCallCardManager *)sharedManager
{
    if (singleton != nil)
        return singleton;
    
    // Makes the startup of this singleton thread safe.
    static dispatch_once_t pred;        // Lock
    dispatch_once(&pred, ^{             // This code is called at most once per app
        singleton = [[JCCallCardManager alloc] init];
    });
    
    return singleton;
}

+ (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end