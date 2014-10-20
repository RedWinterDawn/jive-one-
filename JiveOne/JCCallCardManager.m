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
NSString *const kJCCallCardManagerTransferFailed = @"tranferFailed";

NSString *const kJCCallCardManagerUpdatedIndex = @"index";
NSString *const kJCCallCardManagerPriorUpdateCount = @"priorCount";
NSString *const kJCCallCardManagerUpdateCount = @"updateCount";
NSString *const kJCCallCardManagerLastCallState = @"lastCallState";

NSString *const kJCCallCardManagerNewCall       = @"newCall";
NSString *const kJCCallCardManagerActiveCall    = @"activeCall";

@interface JCCallCardManager ()
{
    SipHandler *_sipHandler;
	NSString *_warmTransferNumber;
}

@end

@implementation JCCallCardManager

-(id)init
{
    self = [super init];
    if (self)
    {
        _sipHandler = [SipHandler sharedHandler];
    }
    return self;
}

/**
 * Dial an number. 
 *
 * If the SIP hsndler is not registered, try to reconnect before dialing number. If fails with error, returns error 
 * state.
 */
-(void)dialNumber:(NSString *)dialNumber type:(JCCallCardDialTypes)dialType completion:(void (^)(bool success, NSDictionary *callInfo))completion
{
    if(!_sipHandler.isRegistered)
    {
        [_sipHandler connect:^(bool success, NSError *error) {
            if (success)
                [self internal_dialNumber:dialNumber type:dialType completion:completion];
            else
                completion(false, nil);
            
            if (error)
                NSLog(@"%@", [error description]);
        }];
    }
    else
        [self internal_dialNumber:dialNumber type:dialType completion:completion];
}

-(void)answerCall:(JCCallCard *)newCallCard
{
	[_sipHandler answerCall];
    newCallCard.started = [NSDate date];
	[self removeIncomingCall:newCallCard];
	[self addCurrentCallCard:newCallCard];
}

-(void)hangUpCall:(JCCallCard *)callCard remote:(BOOL)remote
{
	if (!remote)
		[_sipHandler hangUpCallWithSession:callCard.lineSession.mSessionId];
    
   [self removeCurrentCall:callCard];
}

-(void)toggleCallHold:(JCCallCard *)callCard
{
	[_sipHandler toggleHoldForLineWithSessionId:callCard.lineSession.mSessionId];
}

-(void)finishWarmTransfer:(void (^)(bool success))completion
{
	if (_warmTransferNumber) {
		[_sipHandler attendedRefer:_warmTransferNumber completion:^(bool success, NSError *error) {
            completion(success);
        }];
	}
}

-(void)addIncomingCall:(JCLineSession *)session
{
    NSUInteger priorCount = self.calls.count;
    JCCallCard *callCard = [[JCCallCard alloc] init];
    callCard.started = [NSDate date];
    callCard.lineSession = session;
    callCard.incoming = true;
    [self addCurrentCallCard:callCard];
    
    // Sort the array and fetch the resulting new index of the call card.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"started" ascending:NO];
    [self.calls sortUsingDescriptors:@[sortDescriptor]];
    
    NSUInteger newIndex = [self.calls indexOfObject:callCard];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerAddedIncomingCallNotification
                                                        object:self
                                                      userInfo:@{
                                                                 kJCCallCardManagerUpdatedIndex:[NSNumber numberWithInteger:newIndex],
                                                                 kJCCallCardManagerPriorUpdateCount:[NSNumber numberWithInteger:priorCount],
                                                                 kJCCallCardManagerUpdateCount: [NSNumber numberWithInteger:self.calls.count]
                                                                 }];
}

#pragma mark - Properties -

- (NSMutableArray *)calls
{
	if (!_calls)
		_calls = [NSMutableArray array];

	return _calls;
}

#pragma mark - Private -

-(void)internal_dialNumber:(NSString *)dialNumber type:(JCCallCardDialTypes)dialType completion:(void (^)(bool success, NSDictionary *callInfo))completion
{
    if (dialType == JCCallCardDialBlindTransfer) {
        [_sipHandler referCall:dialNumber completion:^(bool success, NSError *error) {
            
            if (completion != NULL)
                completion(success, @{});
            
            if (error)
                NSLog(@"%@", [error description]);
        }];
        return;
    }
    else if (dialType == JCCallCardDialWarmTransfer)
    {
        _warmTransferNumber = dialNumber;
    }
    
    JCLineSession *session = [_sipHandler makeCall:dialNumber videoCall:NO contactName:[self getContactNameByNumber:dialNumber]];
    if (session.mSessionState)
    {
        JCCallCard *callCard = [[JCCallCard alloc] init];
        callCard.dialNumber = dialNumber;
        callCard.started = [NSDate date];
        callCard.lineSession = session;
        [self addCurrentCallCard:callCard];
		
        NSUInteger index = [self.calls indexOfObject:callCard];
        if (completion != NULL)
            completion(true, @{
                               kJCCallCardManagerNewCall: callCard,
                               kJCCallCardManagerUpdatedIndex: [NSNumber numberWithInteger:index],
                               });
    }
    else
    {
         NSLog(@"Error Making Call");
        if (completion != NULL)
            completion(false, @{});
    }
}


- (NSString *)getContactNameByNumber:(NSString *)number
{
    Lines *contact = [Lines MR_findFirstByAttribute:@"externsionNumber" withValue:number];
    if (contact) {
        return contact.displayName;
    }
    
    return nil;
}

-(void)removeIncomingCall:(JCCallCard *)callCard
{
    if (![_calls containsObject:callCard])
        return;
    
    NSUInteger index = [self.calls indexOfObject:callCard];
    NSUInteger priorCount = self.calls.count;
    [_calls removeObject:callCard];
    callCard.incoming = false;
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerRemoveIncomingCallNotification
                                                        object:self
                                                      userInfo:@{
                                                                 kJCCallCardManagerUpdatedIndex:[NSNumber numberWithInteger:index],
                                                                 kJCCallCardManagerPriorUpdateCount:[NSNumber numberWithInteger:priorCount],
                                                                 kJCCallCardManagerUpdateCount: [NSNumber numberWithInteger:self.calls.count]
                                                                 }];
}

-(void)removeCurrentCall:(JCCallCard *)callCard
{
    if (![_calls containsObject:callCard])
        [self removeIncomingCall:callCard];
    
    NSUInteger index = [_calls indexOfObject:callCard];
	JCCall lastState = callCard.lastState;
    [_calls removeObject:callCard];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerRemoveCurrentCallNotification object:self userInfo:@{
																																	  kJCCallCardManagerUpdatedIndex:[NSNumber numberWithInteger:index],
																																	  kJCCallCardManagerLastCallState: [NSNumber numberWithInt:lastState]
																																	  }];
}

-(void)addCurrentCallCard:(JCCallCard *)callCard
{
    if (!_calls)
        _calls = [NSMutableArray array];
    
    // Place other calls on hold.
    for (JCCallCard *card in _calls)
        card.hold = true;
    
    [_calls addObject:callCard];
    
    // Sort the array and fetch the resulting new index of the call card.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"started" ascending:NO];
    [_calls sortUsingDescriptors:@[sortDescriptor]];
    
    NSUInteger newIndex = [_calls indexOfObject:callCard];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerAddedCurrentCallNotification object:self userInfo:@{kJCCallCardManagerUpdatedIndex:[NSNumber numberWithInteger:newIndex]}];
}

- (void)transferFailed:(JCCallCard *)callCard
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerTransferFailed object:self userInfo:@{kJCCallCardManagerLastCallState:[NSNumber numberWithInt:callCard.lastState]}];
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