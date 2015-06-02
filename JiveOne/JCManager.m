//
//  JCManager.m
//  JiveOne
//
//  Created by Robert Barclay on 1/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCManager.h"

@implementation JCManager

+(NSMutableDictionary *)singletons
{
    static NSMutableDictionary *singletons;
    static dispatch_once_t instantiated;
    dispatch_once(&instantiated, ^{
        singletons = [NSMutableDictionary dictionary];
    });
    return singletons;
}

+(instancetype)sharedManager
{
    NSMutableDictionary *singletons = [self singletons];
    Class class = [self class];
    id object = [[self singletons] objectForKey:NSStringFromClass(class)];
    if (!object) {
        object = [class new];
        [singletons setObject:object forKey:NSStringFromClass(class)];
    }
    return object;
}

+ (id)copyWithZone:(NSZone *)zone
{
    return self;
}

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
