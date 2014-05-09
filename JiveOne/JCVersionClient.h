//
//  JCVersionClient.h
//  JiveOne
//
//  Created by Doug on 5/9/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"

@protocol JCVersionClientDelegateProtocol <NSObject>

@required
- (void)receivedData:(NSData *)data;
- (void)emptyReply;
- (void)timedOut;
- (void)downloadError;

@end

@interface JCVersionClient : NSObject <JCVersionClientDelegateProtocol>

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, retain) id<JCVersionClientDelegateProtocol> delegate;
+ (instancetype)sharedClient;
-(void)getVersion;
@end
