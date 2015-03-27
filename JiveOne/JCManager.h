//
//  JCManager.h
//  JiveOne
//
//  A utility base class that provides a singleton instance of a mamager that is built to be a base
//  superclass for core components. Provides some utitlity methods for posting notifications,
//  handling completion events, and singleton lifecycle.
//
//  Created by Robert Barclay on 1/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^CompletionHandler)(BOOL success, NSError *error);

@interface JCManager : NSObject

+(instancetype)sharedManager;

@property (nonatomic, strong) CompletionHandler completion;

-(void)reportError:(NSError *)error;
-(void)notifyCompletionBlock:(BOOL)success error:(NSError *)error;

-(void)postNotificationNamed:(NSString *)name;
-(void)postNotificationNamed:(NSString *)name userInfo:(NSDictionary *)userInfo;

@end
