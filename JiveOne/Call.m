//
//  Call.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Call.h"

NSString *const kCallEntityName = @"Call";

@implementation Call

@dynamic name;
@dynamic number;
@dynamic extension;

@end

@implementation Call (MagicalRecord)

+(void)addCallEntity:(NSString *)entityName lineSession:(JCLineSession *)session
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        Call *call = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:localContext];
        call.date = [NSDate date];
        call.name = session.callTitle;
        call.number = session.callDetail;
        
    } completion:^(BOOL success, NSError *error) {
        if (error) {
            NSLog(@"%@ Call Event Insert Error:%@", entityName, [error description]);
        }
    }];
}

@end

