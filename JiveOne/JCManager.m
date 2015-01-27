//
//  JCManager.m
//  JiveOne
//
//  Created by Robert Barclay on 1/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCManager.h"

@implementation JCManager

-(void)setCompletion:(CompletionHandler)completion
{
    if (_completion) {
        [self notifyCompletionBlock:NO error:nil];
    }
    
    _completion = completion;
}

-(void)reportError:(NSError *)error
{
    [self notifyCompletionBlock:NO error:error];
}

-(void)notifyCompletionBlock:(BOOL)success error:(NSError *)error
{
    if (![NSThread isMainThread]) {
         dispatch_async(dispatch_get_main_queue(), ^{
             if (_completion) {
                 _completion(success, error);
                 _completion = nil;
             }
         });
    }
    
    if (_completion) {
        _completion(success, error);
        _completion = nil;
    }
}

-(void)postNotificationNamed:(NSString *)name
{
    [self postNotificationNamed:name userInfo:nil];
}

/**
 * A helper method to post a notification to the main thread. All notifcations posting from the
 * authentication Manager should be from the main thread.
 */
-(void)postNotificationNamed:(NSString *)name userInfo:(NSDictionary *)userInfo
{
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
        });
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}

@end
