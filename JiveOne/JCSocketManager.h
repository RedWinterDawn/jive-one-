//
//  JCSocketManager.h
//  JiveOne
//
//  Created by Robert Barclay on 3/17/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSocket.h"
#import "JCManager.h"
#import "JCAppSettings.h"

@interface JCSocketManager : JCManager {
    JCSocket *_socket;
}

@property (nonatomic, readonly) JCSocket *socket;
@property (nonatomic, readonly) JCAppSettings *appSettings;

@property (nonatomic) NSUInteger batchSize;

-(void)receivedResult:(NSDictionary *)result type:(NSString *)type data:(NSDictionary *)data;

-(void)generateSubscriptionWithIdentifier:(NSString *)identifier
                                     type:(NSString *)type
                               entityType:(NSString *)entityType
                                 entityId:(NSString *)entityId
                          entityAccountId:(NSString *)accountId;

@end

@interface JCSocketManager (Singleton)

+(instancetype)sharedManager;

+(void)subscribe;
+(void)unsubscribe:(CompletionHandler)completion;

@end