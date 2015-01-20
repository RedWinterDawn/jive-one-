//
//  JCLineSession.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLineSession.h"

#define LINE_BASE 0
#define MAX_LINES 2
#define INVALID_SESSION_ID -1

NSString *const kJCLineSessionStateKey = @"sessionState";
NSString *const kJCLineSessionHoldKey = @"hold";

@implementation JCLineSession

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self reset]; // Sets the initial state of the Line Session.
    }
    return self;
}

- (NSString *)description
{
    NSMutableString *output = [NSMutableString string];
    [output appendString:[self stringForState:_sessionState]];
    [output appendFormat:@", %@", (_active) ? @"Active": @"Inactive"];
    [output appendFormat:@", %@", (_updatable) ? @"updatable": @"locked"];
    [output appendFormat:@", %@", (_hold) ? @"On Hold": @"Off Hold"];
    return output;
}

#pragma mark - Public Methods -

- (void) setReferCall:(BOOL)referCall originalCallSessionId:(long)originalCallSessionId
{
    _mIsReferCall = referCall;
    _mOriginCallSessionId = originalCallSessionId;
}

/**
 * Resets the line session to its default values.
 */
- (void)reset
{
    _callTitle              = nil;
    _callDetail             = nil;
    _hold                   = false;
    _updatable              = false;
    _active                 = false;
    _incomming              = false;
    
    _sessionId              = INVALID_SESSION_ID;
    _mOriginCallSessionId   = INVALID_SESSION_ID;
    _conference       = false;
    _mIsReferCall           = false;
    _mExistEarlyMedia       = false;
    _video                  = false;
    
    self.sessionState       = JCNoCall;  // We do this last because we have KVO Listeners watching it.
}

#pragma mark - Actions -

NSString *const kJCLineSessionNoCallState   = @"Idle Line";
NSString *const kJCLineSessionUnknownState  = @"Unknown Line State";
NSString *const kJCLineSessionIncomingCall  = @"Incoming Call: %lu";
NSString *const kJCLineSessionCall  = @"Call %@: %lu, %@ (%@)";
NSString *const kJCLineSessionTransfer  = @"Transfer %@: %lu, %@ (%@)";

NSString *const kJCLineSessionCallFailed = @"Call Failed: %lu";
NSString *const kJCLineSessionCallCanceled = @"Call Canceled: %lu";

-(NSString *)stringForState:(JCLineSessionState)state
{
    switch (state) {
        case JCNoCall:
            return kJCLineSessionNoCallState;
            
        case JCCallInitiated:
            return [NSString stringWithFormat:kJCLineSessionCall, @"Initiated", _sessionId, _callTitle, _callDetail];
         
        case JCCallIncoming:
            return [NSString stringWithFormat:kJCLineSessionIncomingCall, _sessionId];
            
        case JCCallTrying:
            return [NSString stringWithFormat:kJCLineSessionCall, @"Trying", _sessionId, _callTitle, _callDetail];
            
        case JCCallProgress:
            return [NSString stringWithFormat:kJCLineSessionCall, @"Progress", _sessionId, _callTitle, _callDetail];
            
        case JCCallRinging:
            return [NSString stringWithFormat:kJCLineSessionCall, @"Ringing",  _sessionId, _callTitle, _callDetail];
            
        case JCCallAnswered:
            return [NSString stringWithFormat:kJCLineSessionCall, @"Answered", _sessionId, _callTitle, _callDetail];
            
        case JCCallConnected:
            return [NSString stringWithFormat:kJCLineSessionCall, @"Connected", _sessionId, _callTitle, _callDetail];
            
        case JCCallFailed:
            return [NSString stringWithFormat:kJCLineSessionCallFailed, _sessionId];
                    
        case JCCallCanceled:
            return [NSString stringWithFormat:kJCLineSessionCallCanceled, _sessionId];
        
        // Transfers
        case JCTransferIncoming:
            return [NSString stringWithFormat:@"Incoming Transfer: %lu", _sessionId];
            
        case JCTransferAccepted:
            return [NSString stringWithFormat:kJCLineSessionTransfer, @"Accepted", _sessionId, _callTitle, _callDetail];
            
        case JCTransferRejected:
            return [NSString stringWithFormat:kJCLineSessionTransfer, @"Rejected", _sessionId, _callTitle, _callDetail];
            
        case JCTransferTrying:
            return [NSString stringWithFormat:kJCLineSessionTransfer, @"Trying", _sessionId, _callTitle, _callDetail];
            
        case JCTransferRinging:
            return [NSString stringWithFormat:kJCLineSessionTransfer, @"Ringing", _sessionId, _callTitle, _callDetail];
            
        case JCTransferSuccess:
            return [NSString stringWithFormat:kJCLineSessionTransfer, @"Success", _sessionId, _callTitle, _callDetail];
            
        case JCTransferFailed:
            return [NSString stringWithFormat:kJCLineSessionTransfer, @"Failed", _sessionId, _callTitle, _callDetail];
            
        default:
            return kJCLineSessionUnknownState;
    }
}

@end
