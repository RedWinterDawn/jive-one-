//
//  JCVersion.h
//  JiveOne
//
//  Created by Doug on 5/9/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JCVersionClientDelegateProtocol <NSObject>

- (void)receivedData:(NSData *)data;
- (void)emptyReply;
- (void)timedOut;
- (void)downloadError;

@end

@interface JCVersion : NSObject <JCVersionClientDelegateProtocol>

@property (nonatomic, retain) id<JCVersionClientDelegateProtocol> delegate;
-(void)getVersion;
@end