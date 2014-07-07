//
//  JasmineSocket.h
//  AttedantConsole
//
//  Created by Eduardo Gueiros on 7/1/14.
//  Copyright (c) 2014 Jive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PSWebSocket.h>

@interface JasmineSocket : NSObject <PSWebSocketDelegate>

+ (JasmineSocket *)sharedInstance;

- (void)initSocket;
- (void)postSubscriptionsToSocketWithId:(NSString *)ident entity:(NSString *)entity type:(NSString *)type;
@property (nonatomic, strong) PSWebSocket *socket;
@property (nonatomic, strong) NSString *subscriptionUrl;
@property (nonatomic, strong) NSString *webSocketUrl;
@property (nonatomic, strong) NSString *selfUrl;

@end
