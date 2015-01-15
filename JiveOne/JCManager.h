//
//  JCManager.h
//  JiveOne
//
//  Created by Robert Barclay on 1/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

@interface JCManager : NSObject

@property (nonatomic, strong) CompletionHandler completion;

-(void)reportError:(NSError *)error;
-(void)notifyCompletionBlock:(BOOL)success error:(NSError *)error;

-(void)postNotificationNamed:(NSString *)name;
-(void)postNotificationNamed:(NSString *)name userInfo:(NSDictionary *)userInfo;

@end
