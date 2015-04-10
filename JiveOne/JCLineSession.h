//
//  JCLineSession.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JCPhoneNumberDataSource.h"

#define INVALID_SESSION_ID -1

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
    JCCallAnswerInitiated,   // Start answering a call.
    JCCallAnswered,         // Outgoing call was answered
    JCCallConnected,        // Outgoing call fully connected.
    JCCallConference,       // Call in a conference call.
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

@interface JCLineSession : NSObject <NSCopying>

@property (nonatomic, strong) id<JCPhoneNumberDataSource> number;
@property (nonatomic, strong) NSString *callTitle;
@property (nonatomic, strong) NSString *callDetail;

// State
@property (nonatomic) JCLineSessionState sessionState;

// Identifiers
@property (nonatomic) NSInteger sessionId;
@property (nonatomic) NSInteger referedSessionId;

// Flags
@property (nonatomic, getter=isActive) BOOL active;             // Has an active line session on it.
@property (nonatomic, getter=isHolding) BOOL hold;              // Active line hold status.
@property (nonatomic, getter=isUpdatable) BOOL updatable;       // Active line is updateable
@property (nonatomic, getter=isIncoming) BOOL incoming;         // Is incomming call.
@property (nonatomic, getter=isConference) BOOL conference;     // Is member of conference call.
@property (nonatomic, getter=isVideo) BOOL video;               // is a video call (not yet supported)
@property (nonatomic, getter=isAudio) BOOL audio;               // is a audio call (normally true)
@property (nonatomic, getter=isTransfer) BOOL transfer;         // if active call is being transfered.
@property (nonatomic, getter=isRefer) BOOL refer;               // if incoming call is a refer call

@property (nonatomic) bool mExistEarlyMedia;

- (void)reset;

@end
