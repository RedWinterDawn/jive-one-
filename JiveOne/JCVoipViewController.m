//
//  JCVoipViewController.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoipViewController.h"
#import "JCOsgiClient.h"
#import "KeychainItemWrapper.h"

@interface JCVoipViewController ()
{
    NSDictionary* cmd_start;
    NSDictionary* cmd_poll;
    NSString *json_start;
    NSString *json_poll;
    NSString* ws;
    NSString* pipedTokens;
    NSOperationQueue *operationQueue;
    
    NSString *sessionToken;
    
    SRWebSocket *socket;
    NSString *lastMessage;
}

@end

const uint8_t pingString[] = "ping\n";
const uint8_t pongString[] = "pong\n";

@implementation JCVoipViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"VoIP", @"VoIP");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addEvent:(NSString *)event
{
    [self.communicationLog appendFormat:@"%@\n", event];
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive)
    {
        self.txtReceivedData.text = self.communicationLog;
    }
    else
    {
        NSLog(@"App is backgrounded. New event: %@", event);
    }
}

- (IBAction)didTapConnect:(id)sender
{
    //[self createConnection];
    
    if(!socket)
    {
        
        socket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:ws]]];
        socket.delegate = self;
        [socket open];
        
    }
    else
    {
        [socket close];
        socket = nil;
    }
    
}

-(void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    
    NSLog(@"%@",message);
    
    NSString *msgString = message;
    NSData *data = [msgString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *toUse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    
    [self addEvent:msgString];
    
    [socket send:json_poll];
    
}
- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    self.communicationLog = [[NSMutableString alloc] init];
    [self addEvent:@"Connection Open"];
    [socket send:json_start];
    }
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    [self addEvent:[NSString stringWithFormat:@"Connection Failed: %@", [error description]]];
}
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    [self addEvent:@"Connection Closed"];
}

- (void)didTapSubscription:(id)sender
{
    [self createSubscriptions];
}

- (void)didTapSession:(id)sender
{
    [[JCOsgiClient sharedClient] RequestSocketSession:^(id JSON) {
        KeychainItemWrapper* _keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
        
        NSDictionary* response = (NSDictionary*)JSON;
        NSLog([response description]);
        
        sessionToken = [NSString stringWithFormat:@"%@",[response objectForKey:@"token"]];
        NSString* authToken = [_keychainWrapper objectForKey:(__bridge id)(kSecAttrAccount)];
        pipedTokens = [NSString stringWithFormat:@"%@%@", authToken, sessionToken];
        
        cmd_start = [NSDictionary dictionaryWithObjectsAndKeys:@"start", @"cmd", authToken, @"authToken", sessionToken, @"sessionToken", nil];
        cmd_poll  = [NSDictionary dictionaryWithObjectsAndKeys:@"poll", @"cmd", authToken, @"authToken", sessionToken, @"sessionToken", nil];
        NSError* error;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:cmd_start options:NSJSONWritingPrettyPrinted error:&error];
        
        json_start = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        jsonData = [NSJSONSerialization dataWithJSONObject:cmd_poll options:NSJSONWritingPrettyPrinted error:&error];
        json_poll = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        ws = [response objectForKey:@"ws"];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Session" message:@"Created" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        
        //[self createConnection];
        
    } failure:^(NSError *err) {
        NSLog(@"%@", [err description]);
    }];
}

- (void) createSubscriptions
{
    NSDictionary* subscriptions = [NSDictionary dictionaryWithObjectsAndKeys:@"(conversations|permanentrooms|groupconversations|adhocrooms):*:entries:*", @"urn", nil];
    
    [[JCOsgiClient sharedClient] SubscribeToSocketEventsWithAuthToken:sessionToken subscriptions:subscriptions success:^(id JSON) {
        NSLog(@"%@", JSON);
    } failure:^(NSError *err) {
        NSLog(@"%@", err);
    }];
}

- (void) createConnection
{
    if (!self.inputStream)
    {
        
        
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)(ws), 443, &readStream, &writeStream);
        
        
        self.sentPing = NO;
        self.communicationLog = [[NSMutableString alloc] init];
        self.inputStream = (__bridge_transfer NSInputStream *)readStream;
        self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
        [self.inputStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
        [self.inputStream setDelegate:self];
        [self.outputStream setDelegate:self];
        [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream open];
        [self.outputStream open];
        
        [[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^{
            if (self.outputStream)
            {
//                [self.outputStream write:json_start maxLength:strlen((char*)json_start)];
//                [self addEvent:@"Ping sent"];
            }
        }];
    }
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventNone:
            // do nothing.
            break;
            
        case NSStreamEventEndEncountered:
            [self addEvent:@"Connection Closed"];
            break;
            
        case NSStreamEventErrorOccurred:
            [self addEvent:[NSString stringWithFormat:@"Had error: %@", aStream.streamError]];
            break;
            
        case NSStreamEventHasBytesAvailable:
            if (aStream == self.inputStream)
            {
                uint8_t buffer[1024];
                NSInteger bytesRead = [self.inputStream read:buffer maxLength:1024];
                NSString *stringRead = [[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSUTF8StringEncoding];
                stringRead = [stringRead stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                
                [self addEvent:[NSString stringWithFormat:@"Received: %@", stringRead]];
                
                if ([stringRead isEqualToString:@"notify"])
                {
                    UILocalNotification *notification = [[UILocalNotification alloc] init];
                    notification.alertBody = @"New VOIP call";
                    notification.alertAction = @"Answer";
                    [self addEvent:@"Notification sent"];
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                }
                else if ([stringRead isEqualToString:@"ping"])
                {
                    [self.outputStream write:pongString maxLength:strlen((char*)pongString)];
                }
            }
            break;
            
        case NSStreamEventHasSpaceAvailable:
            if (aStream == self.outputStream && !self.sentPing)
            {
                self.sentPing = YES;
                if (aStream == self.outputStream)
                {
                    [self.outputStream write:pingString maxLength:strlen((char*)pingString)];
                    [self addEvent:@"Ping sent"];
                }
            }
            break;
            
        case NSStreamEventOpenCompleted:
            if (aStream == self.inputStream)
            {
                [self addEvent:@"Connection Opened"];
            }
            break;
            
        default:
            break;
    }
}



@end
