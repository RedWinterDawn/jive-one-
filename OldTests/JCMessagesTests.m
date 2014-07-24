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
#import "JCRESTClient.h"
#import "ConversationEntry+Custom.h"

@interface JCMessagesTests : XCTestCase
@property (strong, nonatomic) NSManagedObjectContext *context;

@end

@implementation JCMessagesTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    if(!self.context){
        self.context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
}

-(void)setupVoicemailDummyData{
    
    Conversation *conv1 = [Conversation MR_createInContext:self.context];
    conv1.conversationId = @"conversation1";
    
    Conversation *conv2 = [Conversation MR_createInContext:self.context];
    conv2.conversationId = @"conversation2";
    
    
    
    ConversationEntry *entry1 = [ConversationEntry MR_createInContext:self.context];
    
    entry1.failedToSend = [NSNumber numberWithBool:YES];
    entry1.createdDate = [NSNumber numberWithLong:2000000];
    entry1.tempUrn = @"tempUrn123";
    entry1.message = [NSDictionary dictionaryWithObjectsAndKeys:@"hi", @"raw", nil];
    entry1.conversationId = conv1.conversationId;
    
    ConversationEntry *entry2 = [ConversationEntry MR_createInContext:self.context];
    
    entry2.failedToSend = [NSNumber numberWithBool:YES];
    entry2.createdDate = [NSNumber numberWithLong:2000000];
    entry2.tempUrn = @"tempUrn123";
    entry2.message = [NSDictionary dictionaryWithObjectsAndKeys:@"hi back", @"raw", nil];
    entry2.conversationId = conv1.conversationId;
    
    
    ConversationEntry *entry3 = [ConversationEntry MR_createInContext:self.context];
    
    entry3.failedToSend = [NSNumber numberWithBool:YES];
    entry3.createdDate = [NSNumber numberWithLong:2000000];
    entry3.tempUrn = @"tempUrn123";
    entry3.message = [NSDictionary dictionaryWithObjectsAndKeys:@"hi", @"raw", nil];
    entry3.conversationId = conv2.conversationId;
    
    ConversationEntry *entry4 = [ConversationEntry MR_createInContext:self.context];
    
    entry4.failedToSend = [NSNumber numberWithBool:YES];
    entry4.createdDate = [NSNumber numberWithLong:2000000];
    entry4.tempUrn = @"tempUrn123";
    entry4.message = [NSDictionary dictionaryWithObjectsAndKeys:@"hi back", @"raw", nil];
    entry4.conversationId = conv2.conversationId;
    
    
    [self.context MR_saveToPersistentStoreAndWait];
    

}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    //clear unsentMessagesQueue from user defaults
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"unsentMessageQueue"];
}


//assuming there is an unsent queue, test that upon connection restore, all messages are sent and the queue is emptied
//- (void) testUnsentMessagesAreSentOnConnectionRestore{
//    
//    //setup queue of unsent messages
//    [self setupVoicemailDummyData];
//    
//    //save unsent queue to user defaults
//    
//    //setup mock server so that
//    //server shows that all messages are successfully sent
//    __block NSUInteger counter= [ConversationEntry MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"failedToSend == YES"]].count;
//    
//    id mockClient = [OCMockObject niceMockForClass:[JCRESTClient class]];
//    [[mockClient expect] SubmitChatMessageForConversation:OCMOCK_ANY message:OCMOCK_ANY withEntity:[OCMArg any] withTimestamp:2000000 withTempUrn:[OCMArg any]
//                                                  success:[OCMArg checkWithBlock:^BOOL(void (^successBlock)(AFHTTPRequestOperation *, id))
//                                                           {
//                                                               counter--;
//                                                               successBlock(nil, @"200");
//                                                               if(counter==0){
//                                                                   return YES;
//                                                               }
//                                                               return NO;
//                                                           }]
//                                                  failure:OCMOCK_ANY];
//    
//    //not sure how to imitate restoring the connection, so i'll just call the method, (sendOfflineMessagesQueue) that gets triggered, directly
//    [JCMessagesViewController sendOfflineMessagesQueue:mockClient];
//    [mockClient verify];
//    
//    //query core data for all messages that are still unsent
//    NSArray *entries = [ConversationEntry MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"failedToSend == YES"]];
//    
//    NSLog(@"%@", entries);
//    
//   //assert that none are found
//   XCTAssert(entries.count==0 , @"Core data should be empty of any messages with flag 'failedToSend', but found %lu", (unsigned long)entries.count);
//    
//    
//}

//assuming there is an unsent queue, test that upon connection restore then immediate loss, all messages remain in queue
//- (void) testUnsentMessageQueueIsNotSentOnConnectionLoss{
//    
//    //setup queue of unsent messages and put in user defaults
//   [self setupVoicemailDummyData];
//
//    //setup mock server so that
//    //messages fail to send
//    __block NSUInteger counter= [ConversationEntry MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"failedToSend == YES"]].count;
//    NSUInteger assertCounter = counter;
//    id mockClient = [OCMockObject niceMockForClass:[JCRESTClient class]];
//    
//    
//    [[mockClient expect] SubmitChatMessageForConversation:OCMOCK_ANY message:OCMOCK_ANY withEntity:[OCMArg any] withTimestamp:2000000 withTempUrn:[OCMArg any]
//                                                  success:OCMOCK_ANY
//                                                  failure:[OCMArg checkWithBlock:^BOOL(void (^failureBlock)(NSError *))
//                                                           {
//                                                               counter--;
//                                                               failureBlock(nil);
//                                                               if(counter==0){
//                                                                   return YES;
//                                                               }
//                                                               return NO;
//                                                           }]];
//    
//    //not sure how to imitate restoring the connection, so i'll just call the method, (sendOfflineMessagesQueue) that gets triggered, directly
//    [JCMessagesViewController sendOfflineMessagesQueue:mockClient];
//    [mockClient verify];
//    
//    //server shows that messages were not successfully sent
//    
//    //queue is full
//    NSArray *entries = [ConversationEntry MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"failedToSend == YES"]];
//    NSLog(@"%@", entries);
//    
//    //assert queue is empty
//    XCTAssert(entries.count==assertCounter , @"Core data should have the same number of messages with flag 'failedToSend' that existed before message sending was attempted (%lu), but only found %lu", (unsigned long)assertCounter, (unsigned long)entries.count);
//}

//assuming there is an unsent queue, test that upon intermittent connection, sent messages do not reappear in queue, but unsent messages do
//-(void) testUnsentMessageQueueKeepUnsentOnIntermittentConnection{
//    
//    //setup queue of unsent messages and put in user defaults
//   [self setupVoicemailDummyData];
//    
//    //setup mock server so that
//    //messages for conversation1 send
//    id mockClient = [OCMockObject niceMockForClass:[JCRESTClient class]];
//    
//    //for conversation1 we want it to come back successfull
//    __block NSUInteger counter1 = [ConversationEntry MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"failedToSend == YES AND conversationId == %@", @"conversation1"]].count;
//    [[mockClient expect] SubmitChatMessageForConversation:@"conversation1" message:OCMOCK_ANY withEntity:[OCMArg any] withTimestamp:2000000 withTempUrn:[OCMArg any]
//                                                  success:[OCMArg checkWithBlock:^BOOL(void (^successBlock)(AFHTTPRequestOperation *, id))
//                                                           {
//                                                               counter1--;
//                                                               successBlock(nil, @"200");
//                                                               if(counter1==0){
//                                                                   return YES;
//                                                               }
//                                                               return NO;
//                                                           }]
//                                                  failure:OCMOCK_ANY];
//    
//    //for conversation2 we want it to come back as a failure
//    __block NSUInteger counter2 = [ConversationEntry MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"failedToSend == YES and conversationId == %@", @"conversation2"]].count;
//    NSUInteger failCounter = counter2;
//
//    [[mockClient expect] SubmitChatMessageForConversation:@"conversation2" message:OCMOCK_ANY withEntity:[OCMArg any] withTimestamp:2000000 withTempUrn:[OCMArg any]
//                                                   success:OCMOCK_ANY
//                                                   failure:[OCMArg checkWithBlock:^BOOL(void (^failureBlock)(id))
//                                                            {
//                                                                counter2--;
//                                                                failureBlock(nil);
//                                                                if(counter2==0){
//                                                                    return YES;
//                                                                }
//                                                                return NO;
//                                                            }]];
//    
//    
//    //not sure how to imitate restoring the connection, so i'll just call the method, (sendOfflineMessagesQueue) that gets triggered, directly
//    [JCMessagesViewController sendOfflineMessagesQueue:mockClient];
//    [mockClient verify];
//    
//    //queue is full
//    NSArray *entries = [ConversationEntry MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"failedToSend == YES"]];
//    NSLog(@"%@", entries);
//    
//    //assert queue is empty
//    XCTAssert(entries.count==failCounter , @"Core data should have %lu messages (count of messages with flag 'failedToSend' is true and conversationId = 'conversation2' at beginning of test), but only found %lu", (unsigned long)failCounter, (unsigned long)entries.count);
//    //restore connection
//    
//    
//}

//test that after a message is created locally, and the server returns the response (mocked) that the message's (with that tempUrn) timestamp does not get changed when calling addConversationEntry
-(void) testTimestampIsImmutableOnServerSync{
    
    [Conversation MR_truncateAll];
    [ConversationEntry MR_truncateAll];
    
    //put some unsent messages in core data so when i run sendOfflineMessagesQueue it will send some messages
    [self setupVoicemailDummyData];
    
    //get info about first conversationEntry in core data
    NSArray *conversation1Entries = [ConversationEntry MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"conversationId == %@", @"conversation1"]];
    
    //what will we send the server
    long timestampToCheck = [((ConversationEntry*)conversation1Entries[0]).createdDate longValue];
    
    //tempUrn so we can find the right message in core data later
    NSString *tempUrn = ((ConversationEntry*)conversation1Entries[0]).tempUrn;
    
    //setup dictionary that will be what the server returned and give it a bad createdDate (different than what we sent up)
    NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:@"conversation1", @"conversation", @"entities:andrew", @"entity", @"conversations:7753:entries:7761", @"id", @"1398981121840", @"lastModified", @"raw", @"message", tempUrn, @"tempUrn", @"chat", @"type", @"conversations:7753:entries:7761", @"urn", [NSNumber numberWithLong:156],@"createdDate", nil];
    
    //method being tested
    [ConversationEntry addConversationEntry:entry sender:nil];
   
    //retrived the message we sent up earlier, returned by the server, and then updated in core data by method above
    ConversationEntry *message = [ConversationEntry MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"tempUrn == %@", tempUrn]][0];
    
    //assert that timestamp is the same as earlier
    XCTAssert(timestampToCheck==[message.createdDate longValue], @"Timestamp should have been the same before (%lu) and after addConversationEntry(), but was (%lu)", timestampToCheck, [message.createdDate longValue]);

}



@end
