//
//  JCSocketManager.h
//  JiveOne
//
//  Created by Robert Barclay on 3/17/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSocket.h"

@interface JCSocketManager : NSObject {
    JCSocket *_socket;
}

@property (nonatomic, readonly) JCSocket *socket;

-(void)receivedResult:(NSDictionary *)result type:(NSString *)type data:(NSDictionary *)data;

@end

@interface JCSocketManager (Singleton)

+(instancetype)sharedManager;

@end