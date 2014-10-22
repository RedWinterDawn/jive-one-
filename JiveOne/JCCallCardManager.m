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
#import <MBProgressHUD.h>

NSString *const kJCCallCardManagerAddedCallNotification      = @"addedCall";
NSString *const kJCCallCardManagerUpdateCallNotification     = @"updatedCall";
NSString *const kJCCallCardManagerRemoveCallNotification     = @"removedCall";

NSString *const kJCCallCardManagerAddedConferenceCallNotification   = @"addedConferenceCall";
NSString *const kJCCallCardManagerRemoveConferenceCallNotification  = @"removeConferenceCall";

NSString *const kJCCallCardManagerUpdatedIndex      = @"index";
NSString *const kJCCallCardManagerPriorUpdateCount  = @"priorCount";
NSString *const kJCCallCardManagerUpdateCount       = @"updateCount";
NSString *const kJCCallCardManagerRemovedCells      = @"removedCells";
NSString *const kJCCallCardManagerAddedCells        = @"addedCells";
NSString *const kJCCallCardManagerLastCallState     = @"lastCallState";

NSString *const kJCCallCardManagerNewCall           = @"newCall";
NSString *const kJCCallCardManagerActiveCall        = @"activeCall";
NSString *const kJCCallCardManagerIncomingCall      = @"incomingCall";
NSString *const kJCCallCardManagerTransferedCall    = @"transferedCall";

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

-(void)answerCall:(JCCallCard *)callCard
{
	[_sipHandler answerCall];
    callCard.incoming = false;
    callCard.started = [NSDate date];
    
    [self setCallCallHoldState:NO forCard:callCard];
    [self updateCall:callCard];
}

-(void)hangUpCall:(JCCallCard *)callCard remote:(BOOL)remote
{
	if (!remote)
		[_sipHandler hangUpCallWithSession:callCard.lineSession.mSessionId];
    
    if (callCard.isConference) {
        [_sipHandler hangUpAll];
    }
    [self removeCall:callCard];
}

-(void)setCallCallHoldState:(bool)hold forCard:(JCCallCard *)callCard
{
    // If we are in a conference call, all the child cards show recieve the hold call state.
    if (callCard.isConference)
    {
        for (JCCallCard *card in callCard.calls)
        {
            [_sipHandler setHoldCallState:hold forSessionId:card.lineSession.mSessionId];
        }
    }
    
    // If we are not in a conference call, all other call should be placed on hold while we are not on hold on a line.
    // When a line is placed on hold, then only it should be placed on hold. If it is returning from hold, all other
    // lines should be placed on hold that are not already on hold.
    else
    {
        if (!hold)
        {
            for (JCCallCard *card in self.calls)
            {
                if (card != callCard)
                {
                    card.hold = TRUE;
                }
            }
        }
        [_sipHandler setHoldCallState:hold forSessionId:callCard.lineSession.mSessionId];
    }
}

-(void)finishWarmTransfer:(void (^)(bool success))completion
{
	if (_warmTransferNumber) {
		[_sipHandler attendedRefer:_warmTransferNumber completion:^(bool success, NSError *error) {
            completion(success);
            if (error) {
                NSLog(@"%@", [error description]);
            }
        }];
	}
}

-(void)mergeCalls:(void (^)(bool success))completion
{
	bool inConference = [_sipHandler setConference:true];
	if (inConference)
    {
		NSArray *calls = self.calls;
		[self addConferenceCallWithCallArray:calls];
	}
	completion(inConference);
}

-(void)splitCalls
{
    JCCallCard *callCard = [self.calls objectAtIndex:0];
    [self removeConferenceCall:callCard];
	[_sipHandler setConference:false];
}

-(void)swapCalls
{
    JCCallCard *inactiveCall = [self findInactiveCallCard];
    inactiveCall.hold = false;
}

-(void)addIncomingCallSession:(JCLineSession *)session
{
    JCCallCard *callCard = [[JCCallCard alloc] initWithLineSession:session];
    callCard.incoming = true;
    [self addCall:callCard];
}

#pragma mark - Properties -

- (NSMutableArray *)calls
{
	if (!_calls)
		_calls = [NSMutableArray array];
	return _calls;
}

#pragma mark - Private -

-(JCCallCard *)findInactiveCallCard
{
    for (JCCallCard *callCard in self.calls) {
        if (callCard.lineSession.mHoldSate == TRUE) {
            return callCard;
        }
    }
    return nil;
}

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
    
    JCLineSession *session = [_sipHandler makeCall:dialNumber videoCall:NO contactName:[self getContactNameByNumber:dialNumber]];
    if (session.mSessionState)
    {
        JCCallCard *transferedCall = self.calls.lastObject;
        JCCallCard *callCard = [[JCCallCard alloc] initWithLineSession:session];
        [self addCall:callCard];
        NSUInteger index = [self.calls indexOfObject:callCard];
        if (completion != NULL)
        {
            if (dialType == JCCallCardDialWarmTransfer) {
                _warmTransferNumber = dialNumber;
                
                completion(true, @{
                                   kJCCallCardManagerTransferedCall: transferedCall,
                                   kJCCallCardManagerNewCall: callCard,
                                   kJCCallCardManagerUpdatedIndex: [NSNumber numberWithInteger:index],
                                   });
            }
            else
            {
                completion(true, @{
                                   kJCCallCardManagerNewCall: callCard,
                                   kJCCallCardManagerUpdatedIndex: [NSNumber numberWithInteger:index],
                                   });
            }
            
            
            
        }
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

-(void)addCall:(JCCallCard *)callCard
{
    if ([self.calls containsObject:callCard])
        return;
    
    NSUInteger priorCount = self.calls.count;
    [self.calls addObject:callCard];
    
    // Sort the array and fetch the resulting new index of the call card.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"started" ascending:NO];
    [self.calls sortUsingDescriptors:@[sortDescriptor]];
    
    NSUInteger newIndex = [self.calls indexOfObject:callCard];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerAddedCallNotification
                                                        object:self
                                                      userInfo:@{
                                                                 kJCCallCardManagerUpdatedIndex:[NSNumber numberWithInteger:newIndex],
                                                                 kJCCallCardManagerPriorUpdateCount:[NSNumber numberWithInteger:priorCount],
                                                                 kJCCallCardManagerUpdateCount: [NSNumber numberWithInteger:self.calls.count],
                                                                 kJCCallCardManagerIncomingCall: [NSNumber numberWithBool:callCard.isIncoming]
                                                                 }];
}

-(void)updateCall:(JCCallCard *)callCard
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerUpdateCallNotification
                                                        object:self
                                                      userInfo:@{
                                                                 kJCCallCardManagerUpdatedIndex:[NSNumber numberWithInteger:[self.calls indexOfObject:callCard]],
                                                                 kJCCallCardManagerIncomingCall: [NSNumber numberWithBool:callCard.isIncoming],
                                                                 kJCCallCardManagerLastCallState:[NSNumber numberWithInt:callCard.lastState]
                                                                 }];
}

-(void)removeCall:(JCCallCard *)callCard
{
    if (![self.calls containsObject:callCard])
        return;
    
    NSUInteger index = [self.calls indexOfObject:callCard];
    NSUInteger priorCount = self.calls.count;
    [self.calls removeObject:callCard];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerRemoveCallNotification
                                                        object:self
                                                      userInfo:@{
                                                                 kJCCallCardManagerUpdatedIndex:[NSNumber numberWithInteger:index],
                                                                 kJCCallCardManagerPriorUpdateCount:[NSNumber numberWithInteger:priorCount],
                                                                 kJCCallCardManagerUpdateCount:[NSNumber numberWithInteger:self.calls.count],
                                                                 kJCCallCardManagerLastCallState:[NSNumber numberWithInt:callCard.lastState]
                                                                }];
}

-(void)addConferenceCallWithCallArray:(NSArray *)callCards
{
    if (!callCards || callCards.count < 2)
        return;
    
    NSUInteger priorCount = self.calls.count;
    NSMutableArray *removeCells = [NSMutableArray array];
    NSMutableArray *calls = [NSMutableArray arrayWithArray:self.calls];
    
    for (JCCallCard *callCard in callCards)
    {
        if ([self.calls containsObject:callCard]) {
            [removeCells addObject:[NSNumber numberWithInteger:[self.calls indexOfObject:callCard]]];
            [calls removeObject:callCard];
        }
    }
    
    self.calls = calls;
    JCCallCard *conferenceCall = [[JCCallCard alloc] initWithCalls:callCards];
    [self setCallCallHoldState:false forCard:conferenceCall];
    [self.calls addObject:conferenceCall];
    NSNumber *index = [NSNumber numberWithInteger:[self.calls indexOfObject:conferenceCall]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerAddedConferenceCallNotification
                                                        object:self
                                                      userInfo:@{
                                                                 kJCCallCardManagerUpdatedIndex : index,
                                                                 kJCCallCardManagerPriorUpdateCount : [NSNumber numberWithInteger:priorCount],
                                                                 kJCCallCardManagerUpdateCount : [NSNumber numberWithInteger:self.calls.count],
                                                                 kJCCallCardManagerRemovedCells : removeCells
                                                                 }];
}

-(void)removeConferenceCall:(JCCallCard *)conferenceCallCard
{
    if (![self.calls containsObject:conferenceCallCard]) {
        return;
    }
    
    NSArray *callCards = conferenceCallCard.calls;
    NSUInteger priorCount = self.calls.count;
    NSInteger removeIndex = [self.calls indexOfObject:conferenceCallCard];
    [self.calls removeObject:conferenceCallCard];
    
    NSMutableArray *addCalls = [NSMutableArray array];
    NSMutableArray *calls = [NSMutableArray arrayWithArray:_calls];
    
    for (JCCallCard *callCard in callCards) {
        [calls addObject:callCard];
        [addCalls addObject:[NSNumber numberWithInteger:[calls indexOfObject:callCard]]];
    }
    self.calls = calls;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCCallCardManagerRemoveConferenceCallNotification
                                                        object:self
                                                      userInfo:@{
                                                                 kJCCallCardManagerUpdatedIndex : [NSNumber numberWithInteger:removeIndex],
                                                                 kJCCallCardManagerPriorUpdateCount : [NSNumber numberWithInteger:priorCount],
                                                                 kJCCallCardManagerUpdateCount : [NSNumber numberWithInteger:self.calls.count],
                                                                 kJCCallCardManagerAddedCells : addCalls
                                                                 }];
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