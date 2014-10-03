//
//  JCCallManager.m
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardManager.h"
#import "SipHandler.h"
#import "JCLineSession.h"

NSString *const kJCCallCardManagerAddedCallNotification = @"addedCall";

NSString *const kJCCallCardManagerUpdatedIndex = @"index";

@interface JCCallCardManager ()
{
    NSMutableArray *_currentCalls;
}

@end


@implementation JCCallCardManager


-(void)dialNumber:(NSString *)dialNumber
{
    JCCallCard *callCard = [[JCCallCard alloc] init];
    callCard.dialNumber = dialNumber;
    callCard.started = [NSDate date];
    
    [self addCallCard:callCard];
}

-(void)refreshCallDatasource
{
	if (!_currentCalls) {
		_currentCalls = [NSMutableArray array];
	} else {
		[_currentCalls removeAllObjects];
	}
	
	for (JCLineSession *line in [[SipHandler sharedHandler] findAllActiveLines]) {
		JCCallCard *callCard = [JCCallCard new];
		callCard.lineSession = line;
		callCard.started = [NSDate date];
		
		[self addCallCard:callCard];
	}
	
}

-(void)hangUpCall:(JCCallCard *)callCard
{
	[[SipHandler sharedHandler] hangUpCallWithSession:callCard.lineSession.mSessionId];
	[self refreshCallDatasource];
}

-(void)placeCallOnHold:(JCCallCard *)callCard
{
	[[SipHandler sharedHandler] toggleHoldForLineWithSessionId:callCard.lineSession.mSessionId];
}

-(void)removeFromHold:(JCCallCard *)callCard
{
    
}

-(NSUInteger)totalCalls
{
    return self.incomingCalls.count + self.currentCalls.count;
}

                     
#pragma mark - Private -
                     
-(void)addCallCard:(JCCallCard *)callCard
{
    if (!_currentCalls)
        _currentCalls = [NSMutableArray array];
    [_currentCalls addObject:callCard];
    
    // Sort the array and fetch the resulting new index of the call card.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"started" ascending:YES];
    [_currentCalls sortUsingDescriptors:@[sortDescriptor]];
    
    NSUInteger newIndex = [_currentCalls indexOfObject:callCard];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerAddedCallNotification object:self userInfo:@{kJCCallCardManagerUpdatedIndex:[NSNumber numberWithInteger:newIndex]}];
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