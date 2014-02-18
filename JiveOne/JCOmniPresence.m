//
//  JCOmniPresence.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/18/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCOmniPresence.h"
#import "ClientEntities.h"
#import "ClientMeta.h"

@implementation JCOmniPresence

+(instancetype)sharedInstance
{
    static JCOmniPresence *sharedObject;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[JCOmniPresence alloc] init];
    });
    
    return sharedObject;
}

- (ClientEntities*)me
{
    return [ClientEntities MR_findFirstByAttribute:@"me" withValue:[NSNumber numberWithBool:YES]];
}


@end
