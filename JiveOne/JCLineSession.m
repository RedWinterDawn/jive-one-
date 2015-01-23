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

-(id)copyWithZone:(NSZone *)zone
{
    JCLineSession *copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        copy.sessionId          = self.sessionId;
        copy.referedSessionId   = self.referedSessionId;
        copy.callTitle          = self.callTitle;
        copy.callDetail         = self.callDetail;
        copy.active             = self.isActive;
        copy.hold               = self.isHolding;
        copy.updatable          = self.isUpdatable;
        copy.incoming           = self.isIncoming;
        copy.conference         = self.isConference;
        copy.video              = self.isVideo;
        copy.audio              = self.isAudio;
        copy.transfer           = self.isTransfer;
        copy.refer              = self.isRefer;
        copy.mExistEarlyMedia   = self.mExistEarlyMedia;
    }
    return copy;
}


- (NSString *)description
{
    NSMutableString *output = [NSMutableString string];
    [output appendString:[self stringForState:_sessionState]];
    [output appendFormat:@", %@", (_incoming) ? @"Incoming Call": @""];
    [output appendFormat:@", %@", (_active) ? @"Active": @"Inactive"];
    [output appendFormat:@", %@", (_updatable) ? @"updatable": @"locked"];
    [output appendFormat:@", %@", (_hold) ? @"On Hold": @"Off Hold"];
    [output appendFormat:@", %@", (_conference) ? @"Conference Call": @""];
    
    if (_transfer) {
        [output appendFormat:@", Transfer"];
    }
    if (_refer) {
        [output appendFormat:@", Refering (%li -> %li)", (long)_referedSessionId, (long)_sessionId];
    }
    return output;
}

#pragma mark - Public Methods -

//- (void) setReferCall:(BOOL)referCall originalCallSessionId:(long)originalCallSessionId
//{
//    _mIsReferCall = referCall;
//    _mOriginCallSessionId = originalCallSessionId;
//}

/**
 * Resets the line session to its default values.
 */
- (void)reset
{
    _sessionId              = INVALID_SESSION_ID;
    _referedSessionId       = INVALID_SESSION_ID;
    _callTitle              = nil;
    _callDetail             = nil;
    _contact                = nil;
    _hold                   = FALSE;
    _updatable              = FALSE;
    _active                 = FALSE;
    _incoming               = FALSE;
    _conference             = FALSE;
    _video                  = FALSE;
    _audio                  = FALSE;
    _transfer               = FALSE;
    _refer                  = FALSE;
    
    _mExistEarlyMedia       = false;

    self.sessionState       = JCNoCall;  // We do this last because we have KVO Listeners watching it.
}

#pragma mark - Actions -

NSString *const kJCLineSessionNoCallState   = @"Idle Line";
NSString *const kJCLineSessionUnknownState  = @"Unknown Line State";
NSString *const kJCLineSessionIncomingCall  = @"Incoming Call: %lu";
NSString *const kJCLineSessionCall          = @"Call %@: %lu, %@ (%@)";
NSString *const kJCLineSessionTransfer      = @"Transfer %@: %lu, %@ (%@)";

NSString *const kJCLineSessionCallFailed    = @"Call Failed: %lu";
NSString *const kJCLineSessionCallCanceled  = @"Call Canceled: %lu";

-(NSString *)stringForState:(JCLineSessionState)state
{
    switch (state) {
        case JCNoCall:
            return kJCLineSessionNoCallState;
            
        case JCCallInitiated:
            return [NSString stringWithFormat:kJCLineSessionCall, @"Initiated", (long)_sessionId, _callTitle, _callDetail];
         
        case JCCallIncoming:
            return [NSString stringWithFormat:kJCLineSessionIncomingCall, (long)_sessionId];
            
        case JCCallTrying:
            return [NSString stringWithFormat:kJCLineSessionCall, @"Trying", (long)_sessionId, _callTitle, _callDetail];
            
        case JCCallProgress:
            return [NSString stringWithFormat:kJCLineSessionCall, @"Progress", (long)_sessionId, _callTitle, _callDetail];
            
        case JCCallRinging:
            return [NSString stringWithFormat:kJCLineSessionCall, @"Ringing",  (long)_sessionId, _callTitle, _callDetail];
            
        case JCCallAnswerInitiated:
            return [NSString stringWithFormat:kJCLineSessionCall, @"Answering", (long)_sessionId, _callTitle, _callDetail];
        
        case JCCallAnswered:
            return [NSString stringWithFormat:kJCLineSessionCall, @"Answered", (long)_sessionId, _callTitle, _callDetail];
            
        case JCCallConnected:
            return [NSString stringWithFormat:kJCLineSessionCall, @"Connected", (long)_sessionId, _callTitle, _callDetail];
            
        case JCCallConference:
            return [NSString stringWithFormat:kJCLineSessionCall, @"Conference", (long)_sessionId, _callTitle, _callDetail];
            
        case JCCallFailed:
            return [NSString stringWithFormat:kJCLineSessionCallFailed, (long)_sessionId];
                    
        case JCCallCanceled:
            return [NSString stringWithFormat:kJCLineSessionCallCanceled, (long)_sessionId];
        
        // Transfers
        case JCTransferIncoming:
            return [NSString stringWithFormat:@"Incoming Transfer: %lu", (long)_sessionId];
            
        case JCTransferAccepted:
            return [NSString stringWithFormat:kJCLineSessionTransfer, @"Accepted", (long)_sessionId, _callTitle, _callDetail];
            
        case JCTransferRejected:
            return [NSString stringWithFormat:kJCLineSessionTransfer, @"Rejected", (long)_sessionId, _callTitle, _callDetail];
            
        case JCTransferTrying:
            return [NSString stringWithFormat:kJCLineSessionTransfer, @"Trying", (long)_sessionId, _callTitle, _callDetail];
            
        case JCTransferRinging:
            return [NSString stringWithFormat:kJCLineSessionTransfer, @"Ringing", (long)_sessionId, _callTitle, _callDetail];
            
        case JCTransferSuccess:
            return [NSString stringWithFormat:kJCLineSessionTransfer, @"Success", (long)_sessionId, _callTitle, _callDetail];
            
        case JCTransferFailed:
            return [NSString stringWithFormat:kJCLineSessionTransfer, @"Failed", (long)_sessionId, _callTitle, _callDetail];
            
        default:
            return kJCLineSessionUnknownState;
    }
}

@end
