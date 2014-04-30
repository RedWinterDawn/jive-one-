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
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:unsentQueue] forKey:@"unsentMessageQueue"];
//    [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"unsentMessageQueue"]];
    
    //setup mock server so that
    //server shows that all messages were successfully sent
    __block int counter=0;
    id mockClient = [OCMockObject niceMockForClass:[JCOsgiClient class]];
    [[mockClient expect] SubmitChatMessageForConversation:OCMOCK_ANY message:OCMOCK_ANY withEntity:[OCMArg any] withTimestamp:OCMOCK_ANY withTempUrn:[OCMArg any]
                                                  success:[OCMArg checkWithBlock:^BOOL(void (^successBlock)(AFHTTPRequestOperation *, id))
                                                           {
                                                               counter++;
                                                               successBlock(nil, @"200");
                                                               if(counter==4){
                                                                   return YES;
                                                               }
                                                               return NO;
                                                           }]
                                                  failure:OCMOCK_ANY];
    
    //not sure how to imitate restoring the connection, so i'll just call the method, (sendOfflineMessagesQueue) that gets triggered, directly
    [JCMessagesViewController sendOfflineMessagesQueue:mockClient];
    [mockClient verify];
    
    NSDictionary *updatedUnsentQueue = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"unsentMessageQueue"]];
    NSLog(@"%@", updatedUnsentQueue);
    
    //assert queue is empty
    for(NSString* convKey in updatedUnsentQueue){
        
        NSArray *messages = [updatedUnsentQueue objectForKey:convKey];
        
        XCTAssert(messages.count==0 , @"Queue should be empty of any messages");
    }
    
    
}

//assuming there is an unsent queue, test that upon connection restore then immediate loss, all messages remain in queue
- (void) testUnsentMessageQueueIsNotSentOnConnectionLoss{
    
    //setup queue of unsent messages and put in user defaults
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
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:unsentQueue] forKey:@"unsentMessageQueue"];

    //setup mock server so that
    //messages fail to send
    __block int counter =0;
    id mockClient = [OCMockObject niceMockForClass:[JCOsgiClient class]];
    [[mockClient expect] SubmitChatMessageForConversation:OCMOCK_ANY message:OCMOCK_ANY withEntity:[OCMArg any] withTimestamp:OCMOCK_ANY withTempUrn:[OCMArg any]
                                                  success:OCMOCK_ANY
                                                  failure:[OCMArg checkWithBlock:^BOOL(void (^failureBlock)(id))
                                                           {
                                                               counter++;
                                                               failureBlock(nil);
                                                               if(counter==4){
                                                                   return YES;
                                                               }
                                                               return NO;
                                                           }]];
    
    //not sure how to imitate restoring the connection, so i'll just call the method, (sendOfflineMessagesQueue) that gets triggered, directly
    [JCMessagesViewController sendOfflineMessagesQueue:mockClient];
    [mockClient verify];
    XCTAssertTrue(counter==4, @"Should have been called 4 times. Once for each message");
    
    //server shows that messages were not successfully sent
    
    //queue is full
    NSDictionary *updatedUnsentQueue = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"unsentMessageQueue"]];
    NSLog(@"%@", updatedUnsentQueue);
    
    //assert queue is empty
    for(NSString* convKey in updatedUnsentQueue){
        
        NSArray *messages = [updatedUnsentQueue objectForKey:convKey];
        
        XCTAssertTrue(messages.count==2 , @"Queue should have 2 messages in each array, but only found %lu", (unsigned long)messages.count);
    }
}

//assuming there is an unsent queue, test that upon intermittent connection, sent messages do not reappear in queue, but unsent messages do
-(void) testUnsentMessageQueueKeepUnsentOnIntermittentConnection{
    
    //setup queue of unsent messages and put in user defaults
    //setup queue of unsent messages and put in user defaults
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
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:unsentQueue] forKey:@"unsentMessageQueue"];
    
    //setup mock server so that
    //messages for conversation1 send
    id mockClient = [OCMockObject niceMockForClass:[JCOsgiClient class]];
    
    //for conversation1 we want it to come back successfull
     __block int counter1 =0;
    [[mockClient expect] SubmitChatMessageForConversation:@"conversation1" message:OCMOCK_ANY withEntity:[OCMArg any] withTimestamp:OCMOCK_ANY withTempUrn:[OCMArg any]
                                                  success:[OCMArg checkWithBlock:^BOOL(void (^successBlock)(AFHTTPRequestOperation *, id))
                                                           {
                                                               counter1++;
                                                               successBlock(nil, @"200");
                                                               if(counter1==2){
                                                                   return YES;
                                                               }
                                                               return NO;
                                                           }]
                                                  failure:OCMOCK_ANY];
    
    //for conversation2 we want it to come back as a failure
     __block int counter2 =0;
    [[mockClient expect] SubmitChatMessageForConversation:@"conversation2" message:OCMOCK_ANY withEntity:[OCMArg any] withTimestamp:OCMOCK_ANY withTempUrn:[OCMArg any]
                                                   success:OCMOCK_ANY
                                                   failure:[OCMArg checkWithBlock:^BOOL(void (^failureBlock)(id))
                                                            {
                                                                counter2++;
                                                                failureBlock(nil);
                                                                if(counter2==2){
                                                                    return YES;
                                                                }
                                                                return NO;
                                                            }]];
    
    
    //not sure how to imitate restoring the connection, so i'll just call the method, (sendOfflineMessagesQueue) that gets triggered, directly
    [JCMessagesViewController sendOfflineMessagesQueue:mockClient];
    [mockClient verify];
    
    //queue is full
    NSDictionary *updatedUnsentQueue = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"unsentMessageQueue"]];
    NSLog(@"%@", updatedUnsentQueue);
    
    //assert queue is empty
    for(NSString* convKey in updatedUnsentQueue){
        
        NSArray *messages = [updatedUnsentQueue objectForKey:convKey];
        
        if([convKey isEqualToString:@"conversation2"]){
        XCTAssertTrue(messages.count==2 , @"Queue should have 2 messages in each array, but only found %lu", (unsigned long)messages.count);
        }else{
            XCTAssertTrue(messages.count==0 , @"Queue should have 0 messages in each array");
        }
    }
    
    //restore connection
    
    
}

@end
