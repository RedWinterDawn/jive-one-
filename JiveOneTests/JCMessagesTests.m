//
//  JCMessagesTests.m
//  JiveOne
//
//  Created by Daniel George on 4/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JCMessagesViewController.h"
#import <OCMock/OCMock.h>
#import "JCOsgiClient.h"

@interface JCMessagesTests : XCTestCase

@end

@implementation JCMessagesTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    //clear unsentMessagesQueue from user defaults
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"unsentMessageQueue"];
}


//assuming there is an unsent queue, test that upon connection restore, all messages are sent and the queue is emptied
- (void) testUnsentMessageQueueIsSentOnConnectionRestore{
    
    //setup queue of unsent messages
    NSMutableDictionary *unsentQueue = [[NSMutableDictionary alloc] init];
    NSMutableArray * conversation1 = [[NSMutableArray alloc] init];
    [conversation1 addObject:@"message 1"];
    [conversation1 addObject:@"message 2"];
    [unsentQueue setObject:conversation1 forKey:@"conversation1"];//key should be the conversation id

    NSMutableArray * conversation2 = [[NSMutableArray alloc] init];
    [conversation2 addObject:@"message 3"];
    [conversation2 addObject:@"message 4"];
    [unsentQueue setObject:conversation2 forKey:@"conversation2"];//key should be the conversation id
    
    //save unsent queue to user defaults
    [[NSUserDefaults standardUserDefaults] setObject:unsentQueue forKey:@"unsentMessageQueue"];
    
    //setup mock server so that
    //server shows that all messages were successfully sent
    id mockClient = [OCMockObject niceMockForClass:[JCOsgiClient class]];
    [[mockClient expect] SubmitChatMessageForConversation:OCMOCK_ANY message:OCMOCK_ANY withEntity:[OCMArg any]
                                                  success:[OCMArg checkWithBlock:^BOOL(void (^successBlock)(AFHTTPRequestOperation *, id))
                                                           {
                                                               //TODO:
                                                               //call the code in the block callbackk
                                                               
                                                               successBlock(nil, @"200");//how to make fail?
                                                               return YES;
                                                           }]
                                                  failure:OCMOCK_ANY];
    
    //not sure how to imitate restoring the connection, so i'll just call the method, (sendOfflineMessagesQueue) that gets triggered, directly
    [JCMessagesViewController sendOfflineMessagesQueue:mockClient];
    
    NSLog(@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"unsentMessageQueue"]);
    
    //assert queue is empty
    for(NSString* convKey in unsentQueue){
        
        NSArray *messages = [unsentQueue objectForKey:convKey];
        
        XCTAssert(messages.count==0 , @"Queue should be empty of any messages");
    }
    
    
}

//assuming there is an unsent queue, test that upon connection restore then immediate loss, all messages remain in queue
- (void) testUnsentMessageQueueIsNotSentOnConnectionLoss{
    
    //setup queue of unsent messages and put in user defaults
    
    
    //imitate restore connection
    
    //server shows that messages were not successfully sent
    
    //queue is full
    
    
}

//assuming there is an unsent queue, test that upon intermittent connection, sent messages do not reappear in queue, but unsent messages do
-(void) testUnsentMessageQueueKeepUnsentOnIntermittentConnection{
    
    //setup queue of unsent messages and put in user defaults
    
    
    //restore connection
    
    
}

@end
