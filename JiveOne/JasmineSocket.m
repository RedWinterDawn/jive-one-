//
//  JasmineSocket.m
//  AttedantConsole
//
//  Created by Eduardo Gueiros on 7/1/14.
//  Copyright (c) 2014 Jive. All rights reserved.
//

#import "JasmineSocket.h"
#import "Common.h"
#import "JCV5ApiClient.h"

@implementation JasmineSocket
{
	NSTimer *breakSocketTimer;
    NSDictionary *sessionDictionary;
}

//static NSInteger SocketCloseCode = 1001;
static BOOL closedSocketOnPurpose;

- (void)initSocket
{
	if ([self.socket respondsToSelector:@selector(readyState)]) {
		if (_socket.readyState != SR_OPEN) {
			[self requestSession];
		}
	}
    
//	breakSocketTimer = [NSTimer timerWithTimeInterval:5 target:self selector:@selector(closeSocketWithoutReason) userInfo:nil repeats:NO];
//	[[NSRunLoop currentRunLoop] addTimer:breakSocketTimer forMode:NSDefaultRunLoopMode];
}

- (void) requestSession
{
	[self cleanup];
	
    [[JCV5ApiClient sharedClient] RequestSocketSession:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
        if (suceeded) {
            _webSocketUrl = responseObject[@"ws"];
            _subscriptionUrl = responseObject[@"subscriptions"];
            _selfUrl = responseObject[@"self"];
            
            [self startSocketWithURL];
        }
    }];
}

- (void) startSocketWithURL
{
    // create the NSURLRequest that will be sent as the handshake
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.webSocketUrl]];
    
    // create the socket and assign delegate
    self.socket = [[SRWebSocket alloc] initWithURLRequest:request];
    self.socket.delegate = self;
    
    // open socket
    [self.socket open];
}

- (void)restartSocket
{
	/*
	 * Chech to see if we can skip the a network request to get a new session
	 */
	if (self.subscriptionUrl && self.webSocketUrl && self.selfUrl) {
		[self startSocketWithURL];
	}
	else {
		[self requestSession];
	}
}

- (void) closeSocketWithReason:(NSString *)reason
{
	if (self.socket) {
		closedSocketOnPurpose = YES;
		[self.socket closeWithCode:1001 reason:reason];
	}
}

- (void) cleanup
{
	_completionBlock = nil;
	_socket = nil;
	_subscriptionUrl = nil;
	_webSocketUrl = nil;
	_selfUrl = nil;
}

#pragma mark - for testing
- (void)closeSocketWithoutReason
{
	if (self.socket) {
		[self.socket closeWithCode:0 reason:nil];
	}
		
}

#pragma mark - PSWebSocketDelegate


- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
//    NSLog(@"The websocket handshake completed and is now open!");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"socketDidOpen" object:nil];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
//    NSLog(@"The websocket received a message: %@", message);
    
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *messageDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    
    [self processMessage:messageDictionary];
    
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"The websocket handshake/connection failed with an error: %@", error);
	[self restartSocket];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"The websocket closed with code: %@, reason: %@, wasClean: %@", @(code), reason, (wasClean) ? @"YES" : @"NO");
	
	
	/*
	 * If we have a completion block, it means 
	 * this connection was started by the background fetch process or background 
	 * remote notification. If that's the case then once we're done, we don't want to 
	 * restart the socket automatically.
	 */
	if (self.completionBlock) {
		self.completionBlock(YES, nil);
		closedSocketOnPurpose = YES;
	}
	
	
	/*
	 * If this was not closed on purpose, try to connect again
	 */
	if (!closedSocketOnPurpose) {
		[self restartSocket];
	}
	
	closedSocketOnPurpose = NO;
}

#pragma mark - Subscriptions
- (void)postSubscriptionsToSocketWithId:(NSString *)ident entity:(NSString *)entity type:(NSString *)type
{
    
    
	if (![Common stringIsNilOrEmpty:ident] && ![Common stringIsNilOrEmpty:entity]) {
		
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"id": ident, @"entity": entity}];
		
		if (type) {
			[params setObject:type forKey:@"type"];
		}
		
		[[JCV5ApiClient sharedClient] SubscribeToSocketEvents:self.subscriptionUrl dataDictionary:params];
	}
    
}

- (void) processMessage:(NSDictionary *)message
{
    [self eventForLine:message];
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"eventForLine" object:message];
}

#pragma mark - Background socket connection
- (void)startPoolingFromSocketWithCompletion:(CompletionBlock)completed;
{
    //LOG_Info();
	
    _completionBlock = completed;
    @try {
        [self requestSession];
    }
    @catch (NSException *exception) {
        //LogMessage(@"socket", 4,@"Exception Failed to Pool from Socket: %@", exception);
		
       
    }
}

#pragma mark - process presence
- (void) eventForLine:(NSDictionary *)message
{
    
    NSString *type = message[@"type"];
    //NSString *subId = message[@"subId"];
    NSString *state;
    
    if (![message[@"data"] isKindOfClass:[NSNull class]]) {
        state = message[@"data"][@"state"];
    }
    
    
    // right now we only care about withdraws and confirmeds
    if ([type isEqualToString:@"withdraw"] || (state && [state isEqualToString:@"confirmed"])) {
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
//            Line *line = [Line MR_findFirstByAttribute:@"jrn" withValue:subId inContext:localContext];
//            
//            if (line) {
//                if (state && [state isEqualToString:@"confirmed"]) {
//                    line.state = [NSNumber numberWithInt:(int) JCPresenceTypeDoNotDisturb];
//                }
//                else if (type && [type isEqualToString:@"withdraw"]) {
//                    line.state = [NSNumber numberWithInt:(int) JCPresenceTypeAvailable];
//                }
//            }
            
        }];
    }
}




@end

@implementation JasmineSocket (Singleton)

+ (JasmineSocket *)sharedInstance
{
    static JasmineSocket* sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[JasmineSocket alloc] init];
    });
    return sharedObject;
}

+ (void)startSocket
{
    JCAuthenticationManager *authManager = [JCAuthenticationManager sharedInstance];
    JasmineSocket *socket = [JasmineSocket sharedInstance];
    if (authManager.userAuthenticated && authManager.userLoadedMinimumData) {
        if (socket.socket.readyState != SR_OPEN) {
            [socket restartSocket];
        }
    }
}

+ (void)stopSocket
{
    [[JasmineSocket sharedInstance] closeSocketWithReason:@"Entering background"];
}

@end


