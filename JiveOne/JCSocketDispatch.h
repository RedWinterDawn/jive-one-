//
//  JCSocketDispatch.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>

@interface JCSocketDispatch : NSObject <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) NSMutableDictionary *badges;

+ (instancetype)sharedInstance;

- (void)requestSession;

- (void)closeSocket;

- (void)clearBadgeCountForVoicemail;

@end
