//
//  JCLineSession.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Contact;

extern NSString *const kJCLineSessionStateKey;
extern NSString *const kJCLineSessionHoldKey;

typedef enum {
    JCNoCall,               // Idle line state.
    JCCallInitiated,        // Start of an outgoing call.
    JCCallIncoming,         // Incoming call
    JCCallTrying,           // Outgoing call request is processed.
    JCCallProgress,         // Notification of early media and if audio or video exists.
    JCCallRinging,          // Outgoing call rang
    JCCallAnswered,         // Outgoing call was answered
    JCCallConnected,        // Outgoing call fully connected.
    JCCallFailed,           // Outgoing call failed.
    JCCallCanceled,         // Call Was Canceled.
    JCTransferIncoming,     // Incoming Transfer Call
    JCTransferAccepted,     // Tranfer Accepted.
    JCTransferRejected,     // Transfer Rejected;
    JCTransferTrying,
    JCTransferRinging,
    JCTransferSuccess,
    JCTransferFailed,
} JCLineSessionState;

@interface JCLineSession : NSObject

@property (nonatomic, strong) Contact *contact;
@property (nonatomic, strong) NSString *callTitle;
@property (nonatomic, strong) NSString *callDetail;

// State
@property (nonatomic) JCLineSessionState sessionState;

// Identifiers
@property (nonatomic) long mSessionId;
@property (nonatomic, getter=getOriginalCallSessionId) long mOriginCallSessionId;

// Flags
@property (nonatomic, getter=isActive) BOOL active;
@property (nonatomic, getter=isHolding) BOOL hold;
@property (nonatomic, getter=isUpdatable) BOOL updatable;
@property (nonatomic, getter=isIncomming) bool incomming;

//@property (nonatomic) bool mSessionState;
@property (nonatomic) bool mConferenceState;
@property (nonatomic, getter=isReferCall) bool mIsReferCall;
@property (nonatomic) bool mExistEarlyMedia;
@property (nonatomic) bool mVideoState;

- (void)setReferCall:(BOOL)referCall originalCallSessionId:(long)originalCallSessionId;
- (void)reset;

@end
