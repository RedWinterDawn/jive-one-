//
//  JCSocketManager.h
//  JiveOne
//
//  Created by Robert Barclay on 3/17/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSocket.h"
#import "JCManager.h"

@interface JCSocketManager : JCManager {
    JCSocket *_socket;
}

@property (nonatomic, readonly) JCSocket *socket;

-(void)receivedResult:(NSDictionary *)result type:(NSString *)type data:(NSDictionary *)data;

-(void)generateSubscriptionWithIdentifier:(NSString *)identifier type:(NSString *)type subscriptionType:(NSString *)subscriptionType pbx:(PBX *)pbx;

//-(NSDictionary *)subscriptionDictionaryForIdentifier:(NSString *)identifier entity:(NSDictionary *)entity type:(NSString *)type;

@end

@interface JCSocketManager (Singleton)

+(instancetype)sharedManager;

+(void)subscribe;
+(void)unsubscribe:(CompletionHandler)completion;

@end