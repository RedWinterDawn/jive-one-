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
#import "Lines+Custom.h"

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
//    NSMutableArray *_currentCalls;
//    NSMutableArray *_incomingCalls;
}

@end

@implementation JCCallCardManager

-(void)addIncomingCall:(JCLineSession *)session
{
	NSUInteger priorCount = self.totalCalls;
	JCCallCard *callCard = [[JCCallCard alloc] init];
	callCard.started = [NSDate date];
	callCard.lineSession = session;
	callCard.incoming = true;
	[self addCurrentCallCard:callCard];
	
	// Sort the array and fetch the resulting new index of the call card.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"started" ascending:NO];
	[self.currentCalls sortUsingDescriptors:@[sortDescriptor]];
	
	NSUInteger newIndex = [self.currentCalls indexOfObject:callCard];
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
    if (![_currentCalls containsObject:callCard])
        return;
	
    NSUInteger index = [self.currentCalls indexOfObject:callCard];
    NSUInteger priorCount = self.totalCalls;
    [_currentCalls removeObject:callCard];
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
    [self dialNumber:dialNumber type:JCCallCardDialSingle completion:NULL];
}

-(void)dialNumber:(NSString *)dialNumber type:(JCCallCardDialTypes)dialType completion:(void (^)(bool success, NSDictionary *callInfo))completion
{
    JCLineSession *session = [[SipHandler sharedHandler] makeCall:dialNumber videoCall:NO contactName:[self getContactNameByNumber:dialNumber]];
    if (session.mSessionState)
    {
        JCCallCard *callCard = [[JCCallCard alloc] init];
        callCard.dialNumber = dialNumber;
        callCard.started = [NSDate date];
        callCard.lineSession = session;
        [self addCurrentCallCard:callCard];
        
        NSUInteger index = [self.currentCalls indexOfObject:callCard];
        if (completion != NULL)
            completion(true, @{
                               kJCCallCardManagerNewCall: callCard,
                               kJCCallCardManagerUpdatedIndex: [NSNumber numberWithInteger:index],
                               });
    }
    else
    {
        if (completion != NULL)
            completion(false, @{});
    }
}

//-(void)refreshCallDatasource
//{
//	if (!_currentCalls) {
//		_currentCalls = [NSMutableArray array];
//	} else {
//		[_currentCalls removeAllObjects];
//	}
//	
//	for (JCLineSession *line in [[SipHandler sharedHandler] findAllActiveLines]) {
//		JCCallCard *callCard = [JCCallCard new];
//		callCard.lineSession = line;
//		callCard.started = [NSDate date];
//		
//		[self addCurrentCallCard:callCard];
//	}
//	
//}

-(void)answerCall:(JCCallCard *)newCallCard
{
    // TODO: do something to answer the call;
    
    for (JCCallCard *callCard in _currentCalls)
        callCard.hold = true;
    
    newCallCard.started = [NSDate date];
    [self removeIncomingCall:newCallCard];
    [self addCurrentCallCard:newCallCard];
}

-(void)hangUpCall:(JCCallCard *)callCard remote:(BOOL)remote
{
	if (!remote) {
		[[SipHandler sharedHandler] hangUpCallWithSession:callCard.lineSession.mSessionId];
	}
   [self removeCurrentCall:callCard];
}

-(void)placeCallOnHold:(JCCallCard *)callCard
{
	[[SipHandler sharedHandler] toggleHoldForLineWithSessionId:callCard.lineSession.mSessionId];
}

-(void)removeFromHold:(JCCallCard *)callCard
{
    // TODO: do something to remove call from hold.
}
#pragma mark - Contact
- (NSString *)getContactNameByNumber:(NSString *)number
{
	Lines *contact = [Lines MR_findFirstByAttribute:@"externsionNumber" withValue:number];
	if (contact) {
		return contact.displayName;
	}
	
	return nil;
}

-(void)finishWarmTransfer:(void (^)(bool success))completion
{
    completion(true);
}

#pragma mark - Properties -

-(NSUInteger)totalCalls
{
    return self.currentCalls.count;
}

- (NSMutableArray *)currentCalls
{
	if (!_currentCalls)
		_currentCalls = [NSMutableArray array];

	return _currentCalls;
}

#pragma mark - Private -

-(void)removeCurrentCall:(JCCallCard *)callCard
{
    if (![_currentCalls containsObject:callCard])
        [self removeIncomingCall:callCard];
    
    NSUInteger index = [_currentCalls indexOfObject:callCard];
    [_currentCalls removeObject:callCard];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerRemoveCurrentCallNotification object:self userInfo:@{kJCCallCardManagerUpdatedIndex:[NSNumber numberWithInteger:index]}];
}

-(void)addCurrentCallCard:(JCCallCard *)callCard
{
    if (!_currentCalls)
        _currentCalls = [NSMutableArray array];
    
    // Place other calls on hold.
    for (JCCallCard *card in _currentCalls)
        card.hold = true;
    
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