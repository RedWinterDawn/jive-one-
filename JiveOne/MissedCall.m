//
//  MissedCall.m
//  JiveOne
//
//  Created by P Leonard on 10/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "MissedCall.h"

NSString *const kMissedCallEntityName = @"MissedCall";

@interface MissedCall ()
{
    
}

@end

@implementation MissedCall
-(UIImage *)icon
{
    // Get icon, but only ever once.
    static UIImage *missedCallIcon;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        missedCallIcon = [UIImage imageNamed:@"red-missed"];
    });
    
    return missedCallIcon;
}

@end

@implementation MissedCall (MagicalRecord)

+(void)addMissedCallWithLineSession:(JCLineSession *)session
{
    [MissedCall addCallEntity:kMissedCallEntityName lineSession:session];
}


@end


//- (JCLineSession *) makeCall:(NSString*) callee
//videoCall:(BOOL)videoCall contactName:(NSString *)contactName;
//{
//    
//    JCLineSession *currentSession = [self findLineWithSessionState];
//    if (currentSession && currentSession.mSessionState && !currentSession.mHoldSate) {
//        [_mPortSIPSDK hold:currentSession.mSessionId];
//    }
//    
//    currentSession = [self findIdleLine];
//    
//    long sessionId = [_mPortSIPSDK call:callee sendSdp:TRUE videoCall:videoCall];
//    if(sessionId >= 0)
//    {
//        [currentSession setMSessionId:sessionId];
//        [currentSession setMSessionState:YES];
//        
//        [currentSession setCallTitle:contactName ? contactName : callee];
//        [currentSession setCallDetail:callee];
//        [OutgoingCall addOutgoingCallWithLineSession:currentSession];
//    }
//    else
//    {
//        //TODO:update call state
//        [currentSession setMCallState:JCCallFailed];
//        [currentSession reset];
//    }
//    
//    return currentSession;
//}
