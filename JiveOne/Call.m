//
//  Call.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Call.h"
#import "Contact.h"
#import "Line.h"

NSString *const kCallEntityName = @"Call";

@implementation Call

@end

@implementation Call (MagicalRecord)

+(void)addCallEntity:(NSString *)entityName line:(Line *)line lineSession:(JCLineSession *)session read:(BOOL)read
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Line *localLine = (Line *)[localContext objectWithID:line.objectID];
        Call *call = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:localContext];
        call.date = [NSDate date];
        call.name = session.callTitle;
        call.number = session.callDetail;
        call.read = read;
        call.line = localLine;
        
        if (session.contact) {
            call.contact = (Contact *)[localContext objectWithID:session.contact.objectID];
        }
    } completion:^(BOOL success, NSError *error) {
        if (error) {
            NSLog(@"%@ Call Event Insert Error:%@", entityName, [error description]);
        }
    }];
}

@end

